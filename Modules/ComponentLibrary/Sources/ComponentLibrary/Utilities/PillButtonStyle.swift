// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

struct PillButtonStyle: ButtonStyle {

    struct ColorSet {
        let foreground: Color
        let background: Color
        let border: Color
    }

    struct ColorCombination {
        let enabled: ColorSet
        let pressed: ColorSet
        let disabled: ColorSet
        let progressViewRail: Color
        let progressViewTrack: Color
    }

    @Environment(\.isEnabled) private var isEnabled

    let isLoading: Bool
    let size: PillButtonSize
    let colorCombination: ColorCombination

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(
                        ButtonProgressViewStyle(
                            railColor: colorCombination.progressViewRail,
                            trackColor: colorCombination.progressViewTrack
                        )
                    )
                    .frame(width: size.minHeight / 2, height: size.minHeight / 2)
            } else {
                configuration
                    .label
                    .typography(size.typograhy)
            }
        }
        .foregroundColor(colorSet(for: configuration).foreground)
        .frame(maxWidth: size.maxWidth, minHeight: size.minHeight)
        .padding(size.padding)
        .background(
            RoundedRectangle(cornerRadius: size.borderRadius)
                .fill(colorSet(for: configuration).background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: size.borderRadius)
                .stroke(colorSet(for: configuration).border)
        )
    }

    private func colorSet(for configuration: Configuration) -> ColorSet {
        if configuration.isPressed {
            return colorCombination.pressed
        } else if isEnabled {
            return colorCombination.enabled
        } else {
            return colorCombination.disabled
        }
    }
}

private struct PillButtonSizeEnvironmentKey: EnvironmentKey {

    static var defaultValue: PillButtonSize = .standard
}

extension EnvironmentValues {

    var pillButtonSize: PillButtonSize {
        get { self[PillButtonSizeEnvironmentKey.self] }
        set { self[PillButtonSizeEnvironmentKey.self] = newValue }
    }
}

extension View {

    public func pillButtonSize(_ size: PillButtonSize) -> some View {
        environment(\.pillButtonSize, size)
    }
}