// Copyright © Blockchain Luxembourg S.A. All rights reserved.

public enum OrderDirection: String {
    /// From non-custodial to non-custodial
    case onChain = "ON_CHAIN"
    /// From non-custodial to custodial
    case fromUserKey = "FROM_USERKEY"
    /// From custodial to non-custodial
    case toUserKey = "TO_USERKEY"
    /// From custodial to custodial
    case `internal` = "INTERNAL"

    public var requiresDestinationAddress: Bool {
        switch self {
        case .onChain,
             .toUserKey:
            return true
        case .fromUserKey,
             .internal:
            return false
        }
    }

    public var requiresRefundAddress: Bool {
        switch self {
        case .onChain,
             .fromUserKey:
            return true
        case .toUserKey,
             .internal:
            return false
        }
    }
}