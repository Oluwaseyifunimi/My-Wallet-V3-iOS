// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

enum AccountPickerRowAction {
    case accountPickerRowDidTap

    case singleAccount(action: SingleAccountAction)
    case accountGroup(action: AccountGroupAction)
    case button(action: ButtonAction)
    case linkedBankAccount(action: LinkedBankAccountAction)
}

extension AccountPickerRowAction {
    enum SingleAccountAction {
        case subscribeToUpdates
        case update(balances: AccountPickerRow.SingleAccount.Balances)
        case failedToUpdate(Error)
    }

    enum ButtonAction {}

    enum AccountGroupAction {
        case subscribeToUpdates
        case update(balances: AccountPickerRow.AccountGroup.Balances)
        case failedToUpdate(Error)
    }

    enum LinkedBankAccountAction {}
}
