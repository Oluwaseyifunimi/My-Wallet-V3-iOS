// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import FeatureAuthenticationDomain
import FeatureAuthenticationUI
import FeatureSettingsDomain
import PlatformKit
import PlatformUIKit
import ToolKit

public enum Onboarding {
    public enum Alert: Equatable {
        case walletAuthentication(AuthenticationError)
    }

    public enum Action: Equatable {
        case start
        case pin(PinCore.Action)
        case walletUpgrade(WalletUpgrade.Action)
        case passwordScreen(PasswordRequired.Action)
        case welcomeScreen(WelcomeAction)
        case informSecondPasswordDetected
        case forgetWallet
        case createAccountScreenClosed
    }

    public struct State: Equatable {
        public var pinState: PinCore.State? = .init()
        public var walletUpgradeState: WalletUpgrade.State?
        public var passwordScreen: PasswordRequired.State?
        public var welcomeState: WelcomeState?
        public var displayAlert: Alert?
        public var showLegacyCreateWalletScreen: Bool = false
        public var deeplinkContent: URIContent?
        public var walletCreationContext: WalletCreationContext?

        /// Helper method to toggle any visible legacy screen if needed
        /// ugly, yeah, I know, but we need to check which current screen is presented
        /// and dismiss that in the `OnboardingHostingController`
        mutating func hideLegacyScreenIfNeeded() {
            if showLegacyCreateWalletScreen {
                showLegacyCreateWalletScreen = false
            }
        }

        public init(
            pinState: PinCore.State? = .init(),
            walletUpgradeState: WalletUpgrade.State? = nil,
            passwordScreen: PasswordRequired.State? = nil,
            welcomeState: WelcomeState? = nil,
            displayAlert: Alert? = nil,
            showLegacyCreateWalletScreen: Bool = false,
            deeplinkContent: URIContent? = nil,
            walletCreationContext: WalletCreationContext? = nil
        ) {
            self.pinState = pinState
            self.walletUpgradeState = walletUpgradeState
            self.passwordScreen = passwordScreen
            self.welcomeState = welcomeState
            self.displayAlert = displayAlert
            self.showLegacyCreateWalletScreen = showLegacyCreateWalletScreen
            self.deeplinkContent = deeplinkContent
            self.walletCreationContext = walletCreationContext
        }
    }

    public struct Environment {
        var appSettings: BlockchainSettingsAppAPI
        var alertPresenter: AlertViewPresenterAPI
        var mainQueue: AnySchedulerOf<DispatchQueue>
        let featureFlags: InternalFeatureFlagServiceAPI
        var buildVersionProvider: () -> String
    }
}

/// The reducer responsible for handing Pin screen and Login/Onboarding screen related action and state.
let onBoardingReducer = Reducer<Onboarding.State, Onboarding.Action, Onboarding.Environment>.combine(
    welcomeReducer
        .optional()
        .pullback(
            state: \.welcomeState,
            action: /Onboarding.Action.welcomeScreen,
            environment: {
                WelcomeEnvironment(
                    mainQueue: $0.mainQueue,
                    featureFlags: $0.featureFlags,
                    buildVersionProvider: $0.buildVersionProvider
                )
            }
        ),
    pinReducer
        .optional()
        .pullback(
            state: \.pinState,
            action: /Onboarding.Action.pin,
            environment: {
                PinCore.Environment(
                    appSettings: $0.appSettings,
                    alertPresenter: $0.alertPresenter
                )
            }
        ),
    passwordRequiredReducer
        .optional()
        .pullback(
            state: \.passwordScreen,
            action: /Onboarding.Action.passwordScreen,
            environment: { _ in
                PasswordRequired.Environment()
            }
        ),
    walletUpgradeReducer
        .optional()
        .pullback(
            state: \.walletUpgradeState,
            action: /Onboarding.Action.walletUpgrade,
            environment: { _ in
                WalletUpgrade.Environment()
            }
        ),
    Reducer<Onboarding.State, Onboarding.Action, Onboarding.Environment> { state, action, environment in
        switch action {
        case .start:
            return decideFlow(
                state: &state,
                appSettings: environment.appSettings
            )
        case .pin:
            return .none
        case .createAccountScreenClosed:
            state.showLegacyCreateWalletScreen = false
            state.walletCreationContext = nil
            return .none
        case .welcomeScreen(.presentScreenFlow(.welcomeScreen)):
            // don't clear the state if the state is not .existing when dismissing the modal by setting the screen flow back to welcome screen
            if state.walletCreationContext == .existing {
                state.walletCreationContext = nil
            }
            return .none
        case .welcomeScreen(.presentScreenFlow(.createWalletScreen)):
            state.showLegacyCreateWalletScreen = true
            state.walletCreationContext = .new
            return .none
        case .welcomeScreen(.presentScreenFlow(.emailLoginScreen)):
            state.walletCreationContext = .existing
            return .none
        case .welcomeScreen:
            return .none
        case .walletUpgrade(.begin):
            return .none
        case .walletUpgrade:
            return .none
        case .passwordScreen(.forgetWallet),
             .forgetWallet:
            state.passwordScreen = nil
            state.pinState = nil
            state.welcomeState = .init()
            return Effect(value: .welcomeScreen(.start))
        case .passwordScreen:
            return .none
        case .informSecondPasswordDetected:
            guard state.welcomeState != nil else {
                return .none
            }
            return Effect(value: .welcomeScreen(.informSecondPasswordDetected))
        }
    }
)

// MARK: - Internal Methods

func decideFlow(
    state: inout Onboarding.State,
    appSettings: BlockchainSettingsAppAPI
) -> Effect<Onboarding.Action, Never> {
    if appSettings.guid != nil, appSettings.sharedKey != nil {
        // Original flow
        if appSettings.isPinSet {
            state.pinState = .init()
            state.passwordScreen = nil
            return Effect(value: .pin(.authenticate))
        } else {
            state.pinState = nil
            state.passwordScreen = .init()
            return Effect(value: .passwordScreen(.start))
        }
    } else if appSettings.pinKey != nil, appSettings.encryptedPinPassword != nil {
        // iCloud restoration flow
        if appSettings.isPinSet {
            state.pinState = .init()
            state.passwordScreen = nil
            return Effect(value: .pin(.authenticate))
        } else {
            state.pinState = nil
            state.passwordScreen = .init()
            return Effect(value: .passwordScreen(.start))
        }
    } else {
        state.pinState = nil
        state.passwordScreen = nil
        state.welcomeState = .init()
        return Effect(value: .welcomeScreen(.start))
    }
}