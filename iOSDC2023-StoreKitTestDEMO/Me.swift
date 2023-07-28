//
//  Me.swift
//  iOSDC2023-StoreKitTestDEMO
//
//  Created by 横山 新 on 2023/07/26.
//

import StoreKit

final class Me {
    init(subscriptionStatus: SubscriptionStatus, subscriptionInformation: SubscriptionInformation?) {
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionInformation = subscriptionInformation
    }

    let subscriptionStatus: SubscriptionStatus
    let subscriptionInformation: SubscriptionInformation?
}

enum SubscriptionStatus: String {
    case free
    case membership
    case premium
}

extension Transaction {
    var subscriptionStatus: SubscriptionStatus {
        switch productID {
        case "iosdc2023.1month", "iosdc2023.3month":
            return .membership

        case "iosdc2023.premium.1month", "iosdc2023.premium.3month":
            return .premium

        default:
            return .free
        }
    }
}
