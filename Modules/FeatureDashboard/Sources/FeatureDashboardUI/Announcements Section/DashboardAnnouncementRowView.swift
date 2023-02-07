// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainUI
import ComposableArchitecture
import Foundation
import SwiftUI
import UnifiedActivityDomain
import UnifiedActivityUI

public struct DashboardAnnouncementRowView: View {
    @BlockchainApp var app
    @Environment(\.context) var context

    let store: StoreOf<DashboardAnnouncementRow>

    public init(store: StoreOf<DashboardAnnouncementRow>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(
            store,
            observe: { $0 }
        ) { viewStore in
            HStack(alignment: .center, spacing: Spacing.padding3) {
                Icon.lockOpen
                    .renderingMode(.template)
                    .color(.WalletSemantic.pink)
                    .frame(width: 33, height: 33)
                    .padding(.leading, Spacing.padding3)

                VStack(alignment: .leading, spacing: 0) {
                    Text(viewStore.announcement.title)
                        .typography(.caption1)
                        .foregroundColor(.WalletSemantic.muted)

                    Text(viewStore.announcement.message)
                        .lineLimit(3)
                        .typography(.body2)
                        .foregroundColor(.WalletSemantic.title)
                }
                .padding(.vertical, Spacing.padding2)
                .padding(.trailing, Spacing.padding3)
            }
            .background(Color.white)
            .onTapGesture {
                app.post(event: viewStore.announcement.action)
            }
        }
    }
}
