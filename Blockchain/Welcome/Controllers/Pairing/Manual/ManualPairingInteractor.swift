// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import AuthenticationKit
import DIKit
import PlatformKit
import RxCocoa
import RxRelay
import RxSwift
import ToolKit

/// Interaction object for manual pairing flow
final class ManualPairingInteractor {

    enum AuthenticationType {

        /// Standard auth using guid (wallet identifier) and password
        case standard

        /// Special auth using guid (wallet identifier), password and one time 2FA string
        case twoFA(String)
    }

    /// Any action related to authentication should go here
    enum AuthenticationAction {

        /// Authorize login by approving a message sent by email
        case authorizeLoginWithEmail

        /// Authorize login by inserting an OTP code
        case authorizeLoginWith2FA(WalletAuthenticatorType)

        /// Wrong OTP code
        case wrongOtpCode(type: WalletAuthenticatorType, attemptsLeft: Int)

        /// Account is locked
        case lockedAccount

        /// Some error that should be reflected to the user
        case message(String)

        case error(Error)
    }

    /// The state of the interaction layer
    struct Content {
        var walletIdentifier = ""
        var password = ""
    }

    // MARK: - Properties

    let contentStateRelay = BehaviorRelay<Content>(value: Content())
    var content: Observable<Content> {
        contentStateRelay.asObservable()
    }

    var authenticationAction: Observable<AuthenticationAction> {
        authenticationActionRelay.asObservable()
    }

    let dependencies: Dependencies

    private var authenticator = Atomic<WalletAuthenticatorType>(.standard)
    private let authenticationActionRelay = PublishRelay<AuthenticationAction>()
    private let disposeBag = DisposeBag()

    // MARK: - Setup

    init(dependencies: Dependencies = Dependencies()) {
        self.dependencies = dependencies

        dependencies
            .loginService
            .authenticator
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe { [authenticator] authenticatorType in
                authenticator.mutate { authenticator in
                    authenticator = authenticatorType
                }
            }
            .disposed(by: disposeBag)
    }

    // MARK: - API

    typealias Event = AnalyticsEvents.New.Security

    func pair(using action: AuthenticationType = .standard) throws {
        dependencies.analyticsRecorder.record(event: AnalyticsEvents.Onboarding.walletManualLogin)
        if case .twoFA = action {
            dependencies.analyticsRecorder.record(
                event: Event.verificationCodeSubmitted(twoStepOption: .mobileNumber)
            )
        }

        /// We have to call `loadJS` before starting the pairing process
        /// `true` is being sent because we only need to load the JS.
        dependencies.wallet.loadJSIfNeeded()

        let walletIdentifier = contentStateRelay.value.walletIdentifier
        dependencies.sessionTokenService.setupSessionToken()
            .subscribe(
                onCompleted: { [weak self] in
                    self?.authenticate(
                        walletIdentifier: walletIdentifier,
                        action: action
                    )
                },
                onError: { [weak self] error in
                    guard let self = self else { return }
                    self.dependencies.errorRecorder.error(error)
                    self.authenticationActionRelay.accept(.error(error))
                }
            )
            .disposed(by: disposeBag)
    }

    /// Requests OTP via SMS
    func requestOTPMessage() -> Completable {
        dependencies.smsService.request()
    }

    // MARK: - Accessors

    /// Invokes the login service
    private func authenticate(walletIdentifier: String, action: AuthenticationType) {
        let login: Completable
        switch action {
        case .standard:
            login = dependencies.loginService.login(
                walletIdentifier: walletIdentifier
            )
        case .twoFA(let code):
            login = dependencies.loginService.login(
                walletIdentifier: walletIdentifier,
                code: code
            )
        }
        login
            .subscribe(
                onCompleted: { [weak self] in
                    guard let self = self else { return }
                    /// TODO: Continue refactoring wallet fetching logic
                    /// by removing `walletFetcher` reference in favor of a dedicated
                    /// Rx based service.
                    self.dependencies.walletFetcher.authenticate(
                        using: self.contentStateRelay.value.password
                    )
                },
                onError: { [weak self] error in
                    self?.handleAuthentication(error: error)
                }
            )
            .disposed(by: disposeBag)
    }

    /// Handles any authentication error by streaming it to the relay
    private func handleAuthentication(error: Error) {
        switch error {
        case LoginServiceError.twoFactorOTPRequired(let type):
            switch type {
            case .email:
                authenticationActionRelay.accept(.authorizeLoginWithEmail)
            default:
                authenticationActionRelay.accept(.authorizeLoginWith2FA(type))
            }
        case LoginServiceError.twoFAWalletServiceError(.wrongCode(attemptsLeft: let attempts)):
            authenticationActionRelay.accept(.wrongOtpCode(type: authenticator.value, attemptsLeft: attempts))
        case LoginServiceError.twoFAWalletServiceError(.accountLocked),
             LoginServiceError.walletPayloadServiceError(.accountLocked):
            authenticationActionRelay.accept(.lockedAccount)
        case LoginServiceError.walletPayloadServiceError(.message(let message)):
            authenticationActionRelay.accept(.message(message))
        default:
            authenticationActionRelay.accept(.error(error))
        }
    }
}

// MARK: - Dependencies

extension ManualPairingInteractor {

    struct Dependencies {

        // MARK: - Pairing dependencies

        let emailAuthorizationService: EmailAuthorizationServiceAPI
        fileprivate let sessionTokenService: SessionTokenServiceAPI
        fileprivate let smsService: SMSServiceAPI
        fileprivate let loginService: LoginServiceAPI
        fileprivate let walletFetcher: WalletPairingFetcherAPI

        // TODO: Remove from dependencies
        fileprivate let wallet: Wallet

        // MARK: - General dependencies

        fileprivate let analyticsRecorder: AnalyticsEventRecorderAPI
        fileprivate let errorRecorder: ErrorRecording

        init(
            analyticsRecorder: AnalyticsEventRecorderAPI = resolve(),
            errorRecorder: ErrorRecording = CrashlyticsRecorder(),
            sessionTokenService: SessionTokenServiceAPI = resolve(),
            smsService: SMSServiceAPI = resolve(),
            emailAuthorizationService: EmailAuthorizationServiceAPI = resolve(),
            loginService: LoginServiceAPI = resolve(),
            wallet: Wallet = WalletManager.shared.wallet,
            walletFetcher: WalletPairingFetcherAPI = resolve()
        ) {
            self.wallet = wallet
            self.walletFetcher = walletFetcher
            self.analyticsRecorder = analyticsRecorder
            self.errorRecorder = errorRecorder
            self.sessionTokenService = sessionTokenService
            self.smsService = smsService
            self.emailAuthorizationService = emailAuthorizationService
            self.loginService = loginService
        }
    }
}
