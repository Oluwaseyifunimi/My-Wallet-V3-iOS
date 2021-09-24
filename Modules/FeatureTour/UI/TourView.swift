// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import Localization
import SwiftUI
import UIComponentsKit

public struct TourView: View {

    let store: Store<TourState, TourAction>

    init(store: Store<TourState, TourAction>) {
        self.store = store
    }

    public init(environment: TourEnvironment) {
        self.init(
            store: Store(
                initialState: TourState(),
                reducer: tourReducer,
                environment: environment
            )
        )
    }

    public var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                Image("logo-blockchain-black", bundle: Bundle.featureTour)
                    .padding(.top)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                ZStack {
                    makeTabView()
                    makeButtonsView(viewStore)
                }
                .background(AnimatedGradient().ignoresSafeArea(.all))
            }
        }
    }
}

extension TourView {

    public enum Carousel {
        case brokerage
        case earn
        case keys
        case prices

        @ViewBuilder public func makeView() -> some View {
            switch self {
            case .brokerage:
                makeCarouselView(
                    image: Image("bitcoin_perspective", bundle: Bundle.featureTour),
                    text: LocalizationConstants.Tour.carouselBrokerageScreenMessage
                )
            case .earn:
                makeCarouselView(
                    image: Image("rocket", bundle: Bundle.featureTour),
                    text: LocalizationConstants.Tour.carouselEarnScreenMessage
                )
            case .keys:
                makeCarouselView(
                    image: Image("lock", bundle: Bundle.featureTour),
                    text: LocalizationConstants.Tour.carouselKeysScreenMessage
                )
            case .prices:
                PriceListFactory.makePriceList()
            }
        }

        @ViewBuilder private func makeCarouselView(image: Image?, text: String) -> some View {
            VStack(spacing: 25) {
                if let image = image {
                    image
                }
                Text(text)
                    .multilineTextAlignment(.center)
                    .frame(width: 200.0)
                    .textStyle(.title)
            }
            .padding(.bottom, 180)
        }
    }

    @ViewBuilder private func makeTabView() -> some View {
        TabView {
            Carousel.brokerage.makeView()
            Carousel.earn.makeView()
            Carousel.keys.makeView()
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }

    @ViewBuilder private func makeButtonsView(_ viewStore: ViewStore<TourState, TourAction>) -> some View {
        VStack(spacing: 16) {
            Spacer()
            PrimaryButton(title: LocalizationConstants.Tour.createAccountButtonTitle) {
                viewStore.send(.createAccount)
            }
            MinimalDoubleButton(
                leftTitle: LocalizationConstants.Tour.restoreButtonTitle,
                leftAction: { viewStore.send(.restore) },
                rightTitle: LocalizationConstants.Tour.loginButtonTitle,
                rightAction: { viewStore.send(.logIn) }
            )
        }
        .padding(.top)
        .padding(.bottom, 60)
        .padding(.horizontal, 24)
    }
}

struct TourView_Previews: PreviewProvider {
    static var previews: some View {
        TourView(
            environment: TourEnvironment(
                createAccountAction: {},
                restoreAction: {},
                logInAction: {}
            )
        )
    }
}