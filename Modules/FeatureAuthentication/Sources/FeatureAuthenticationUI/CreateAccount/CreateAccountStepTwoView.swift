// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import ComposableArchitecture
import ComposableNavigation
import FeatureAuthenticationDomain
import Localization
import SwiftUI
import UIComponentsKit

private typealias LocalizedString = LocalizationConstants.FeatureAuthentication.CreateAccount
private typealias AccessibilityIdentifier = AccessibilityIdentifiers.CreateAccountScreen

struct CreateAccountViewStepTwo: View {

    private let store: Store<CreateAccountStepTwoState, CreateAccountStepTwoAction>
    @ObservedObject private var viewStore: ViewStore<CreateAccountStepTwoState, CreateAccountStepTwoAction>

    init(store: Store<CreateAccountStepTwoState, CreateAccountStepTwoAction>) {
        self.store = store
        viewStore = ViewStore(store)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.padding3) {
                    CreateAccountHeader()
                    CreateAccountForm(viewStore: viewStore)
                    Spacer()
                    BlockchainComponentLibrary.PrimaryButton(
                        title: LocalizedString.createAccountButton,
                        isLoading: viewStore.validatingInput || viewStore.isCreatingWallet
                    ) {
                        viewStore.send(.createButtonTapped)
                    }
                    .disabled(viewStore.isCreateButtonDisabled)
                    .accessibility(identifier: AccessibilityIdentifier.createAccountButton)
                }
                .padding(Spacing.padding3)
            }
            // setting the frame is necessary for the Spacer inside the VStack above to work properly
            .frame(height: geometry.size.height)
        }
        .primaryNavigation(title: "") {
            Button {
                viewStore.send(.createButtonTapped)
            } label: {
                Text(LocalizedString.nextButton)
                    .typography(.paragraph2)
            }
            .disabled(viewStore.isCreateButtonDisabled)
            // disabling the button doesn't gray it out
            .foregroundColor(viewStore.isCreateButtonDisabled ? .semantic.muted : .semantic.primary)
            .accessibility(identifier: AccessibilityIdentifier.nextButton)
        }
        .onAppear(perform: {
            viewStore.send(.onAppear)
        })
        .onWillDisappear {
            viewStore.send(.onWillDisappear)
        }
        .navigationRoute(in: store)
        .alert(store.scope(state: \.failureAlert), dismiss: .alert(.dismiss))
    }
}

private struct CreateAccountHeader: View {

    var body: some View {
        VStack(spacing: Spacing.padding3) {
            Icon.globe
                .frame(width: 32, height: 32)
                .accentColor(.semantic.primary)
            VStack(spacing: Spacing.baseline) {
                Text(LocalizedString.headerTitle)
                    .typography(.title2)
                Text(LocalizedString.headerSubtitle)
                    .typography(.paragraph1)
            }
        }
    }
}

private struct CreateAccountForm: View {

    @ObservedObject var viewStore: ViewStore<CreateAccountStepTwoState, CreateAccountStepTwoAction>

    var body: some View {
        VStack(spacing: Spacing.padding2) {
            emailField
            passwordField
            termsAgreementView
        }
    }

    private var emailField: some View {
        let shouldShowError = viewStore.inputValidationState == .invalid(.invalidEmail)
        return Input(
            text: viewStore.binding(\.$emailAddress),
            isFirstResponder: .constant(false),
            isEnabledAutomaticFirstResponder: false,
            shouldResignFirstResponderOnReturn: true,
            label: LocalizedString.TextFieldTitle.email,
            subText: shouldShowError ? LocalizedString.TextFieldError.invalidEmail : nil,
            subTextStyle: .error,
            placeholder: LocalizedString.TextFieldPlaceholder.email,
            state: shouldShowError ? .error : .default,
            configuration: {
                $0.autocorrectionType = .no
                $0.autocapitalizationType = .none
                $0.keyboardType = .emailAddress
                $0.textContentType = .emailAddress
            }
        )
        .accessibility(identifier: AccessibilityIdentifier.emailGroup)
    }

    private var passwordField: some View {
        let shouldShowError = viewStore.inputValidationState == .invalid(.weakPassword)
        return Input(
            text: viewStore.binding(\.$password),
            isFirstResponder: .constant(false),
            isEnabledAutomaticFirstResponder: false,
            shouldResignFirstResponderOnReturn: true,
            label: LocalizedString.TextFieldTitle.password,
            subText: viewStore.passwordStrength.displayString,
            subTextStyle: viewStore.passwordStrength.inputSubTextStyle,
            state: shouldShowError ? .error : .default,
            configuration: {
                $0.autocorrectionType = .no
                $0.autocapitalizationType = .none
                $0.isSecureTextEntry = !viewStore.passwordFieldTextVisible
                $0.textContentType = .newPassword
            },
            trailing: {
                PasswordEyeSymbolButton(
                    isPasswordVisible: viewStore.binding(\.$passwordFieldTextVisible)
                )
            }
        )
        .accessibility(identifier: AccessibilityIdentifier.passwordGroup)
    }

    private var termsAgreementView: some View {
        HStack(alignment: .top, spacing: Spacing.baseline) {
            let showCheckboxError = viewStore.inputValidationState == .invalid(.termsNotAccepted)
            Checkbox(
                isOn: viewStore.binding(\.$termsAccepted),
                variant: showCheckboxError ? .error : .default
            )
            .accessibility(identifier: AccessibilityIdentifier.termsOfServiceButton)

            agreementText
                .typography(.caption1)
                .accessibility(identifier: AccessibilityIdentifier.agreementPromptText)
        }
        // fixing the size prevents the view from collapsing when the keyboard is on screen
        .fixedSize(horizontal: false, vertical: true)
    }

    private var agreementText: some View {
        HStack {
            VStack(alignment: .leading, spacing: .zero) {
                let promptText = Text(
                    rich: LocalizedString.agreementPrompt
                )
                promptText
                    .foregroundColor(.semantic.body)
                    .accessibility(identifier: AccessibilityIdentifier.agreementPromptText)

                HStack(alignment: .firstTextBaseline, spacing: .zero) {
                    Text(LocalizedString.termsOfServiceLink)
                        .foregroundColor(.semantic.primary)
                        .onTapGesture {
                            guard let url = URL(string: Constants.HostURL.terms) else { return }
                            viewStore.send(.openExternalLink(url))
                        }
                        .accessibility(identifier: AccessibilityIdentifier.termsOfServiceButton)

                    Text(" " + LocalizedString.and + " ")
                        .foregroundColor(.semantic.body)

                    let privacyPolicyComponent = Text(LocalizedString.privacyPolicyLink)
                        .foregroundColor(.semantic.primary)
                    let fullStopComponent = Text(".")
                        .foregroundColor(.semantic.body)
                    let privacyPolicyText = privacyPolicyComponent + fullStopComponent

                    privacyPolicyText
                        .onTapGesture {
                            guard let url = URL(string: Constants.HostURL.privacyPolicy) else { return }
                            viewStore.send(.openExternalLink(url))
                        }
                        .accessibility(identifier: AccessibilityIdentifier.privacyPolicyButton)
                }
            }
            Spacer()
        }
    }
}

extension PasswordValidationScore {
    fileprivate var displayString: String? {
        switch self {
        case .none:
            return nil
        case .normal:
            return LocalizedString.PasswordStrengthIndicator.regularPassword
        case .strong:
            return LocalizedString.PasswordStrengthIndicator.strongPassword
        case .weak:
            return LocalizedString.PasswordStrengthIndicator.weakPassword
        }
    }

    fileprivate var inputSubTextStyle: InputSubTextStyle {
        switch self {
        case .none, .normal:
            return .primary
        case .strong:
            return .success
        case .weak:
            return .error
        }
    }
}

#if DEBUG
import AnalyticsKit
import ToolKit

struct CreateAccountViewStepTwo_Previews: PreviewProvider {

    static var previews: some View {
        CreateAccountViewStepTwo(
            store: .init(
                initialState: .init(
                    context: .createWallet,
                    country: SearchableItem(id: "1", title: "US"),
                    countryState: SearchableItem(id: "1", title: "State"),
                    referralCode: "id1"
                ),
                reducer: createAccountStepTwoReducer,
                environment: .init(
                    mainQueue: .main,
                    passwordValidator: PasswordValidator(),
                    externalAppOpener: ToLogAppOpener(),
                    analyticsRecorder: NoOpAnalyticsRecorder(),
                    walletRecoveryService: .noop,
                    walletCreationService: .noop,
                    walletFetcherService: .noop,
                    featureFlagsService: NoOpFeatureFlagsService(),
                    recaptchaService: NoOpGoogleRecatpchaService()
                )
            )
        )
    }
}
#endif
