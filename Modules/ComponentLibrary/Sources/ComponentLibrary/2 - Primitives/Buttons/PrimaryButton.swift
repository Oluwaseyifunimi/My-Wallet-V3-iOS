// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// PrimaryButton from the Figma Component Library.
///
///
/// # Usage:
///
/// `PrimaryButton(title: "Tap me") { print("button did tap") }`
///
/// - Version: 1.0.1
///
/// # Figma
///
///  [Buttons](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=3%3A367)
public struct PrimaryButton<LeadingView: View>: View {

    private let title: String
    private let isLoading: Bool
    private let colorCombination: PillButtonStyle.ColorCombination
    private let leadingView: LeadingView
    private let action: () -> Void

    @Environment(\.pillButtonSize) private var size
    @Environment(\.isEnabled) private var isEnabled

    public init(
        title: String,
        isLoading: Bool = false,
        @ViewBuilder leadingView: () -> LeadingView,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            isLoading: isLoading,
            colorCombination: primaryButtonColorCombination,
            leadingView: leadingView,
            action: action
        )
    }

    init(
        title: String,
        isLoading: Bool = false,
        colorCombination: PillButtonStyle.ColorCombination,
        @ViewBuilder leadingView: () -> LeadingView,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.colorCombination = colorCombination
        self.leadingView = leadingView()
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: Spacing.padding2) {
                leadingView
                    .frame(width: 24, height: 24)

                Text(title)
            }
        }
        .buttonStyle(
            PillButtonStyle(
                isLoading: isLoading,
                isEnabled: isEnabled,
                size: size,
                colorCombination: colorCombination
            )
        )
    }
}

extension PrimaryButton where LeadingView == EmptyView {

    /// Create a primary button without a leading view.
    /// - Parameters:
    ///   - title: Centered title label
    ///   - isLoading: True to display a loading indicator instead of the label.
    ///   - action: Action to be triggered on tap
    public init(
        title: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            isLoading: isLoading,
            leadingView: { EmptyView() },
            action: action
        )
    }
}

let primaryButtonColorCombination = PillButtonStyle.ColorCombination(
    enabled: PillButtonStyle.ColorSet(
        foreground: .palette.white,
        background: .palette.blue600,
        border: .palette.blue600
    ),
    pressed: PillButtonStyle.ColorSet(
        foreground: .palette.white,
        background: .palette.blue700,
        border: .palette.blue700
    ),
    disabled: PillButtonStyle.ColorSet(
        foreground: Color(
            light: .palette.white.opacity(0.7),
            dark: .palette.white.opacity(0.4)
        ),
        background: Color(
            light: .palette.blue400,
            dark: .palette.grey900
        ),
        border: Color(
            light: .palette.blue400,
            dark: .palette.grey900
        )
    ),
    progressViewRail: .palette.white.opacity(0.8),
    progressViewTrack: .palette.white.opacity(0.25)
)

struct PrimaryButton_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            PrimaryButton(title: "Enabled", action: {})
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Enabled")

            PrimaryButton(
                title: "With Icon",
                leadingView: {
                    Icon.placeholder
                },
                action: {}
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("With Icon")

            PrimaryButton(title: "Disabled", action: {})
                .disabled(true)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Disabled")

            PrimaryButton(title: "Loading", isLoading: true, action: {})
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Loading")
        }
        .padding()
    }
}
