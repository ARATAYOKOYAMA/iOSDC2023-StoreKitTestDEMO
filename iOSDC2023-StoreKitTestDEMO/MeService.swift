//
//  MeService.swift
//  iOSDC2023-StoreKitTestDEMO
//
//  Created by 横山 新 on 2023/07/26.
//

import StoreKit

final class MeService {
    func getMe(entitlements: [SubscriptionInformation]) -> Me {
        guard let subscriptionInformation = entitlements.first else { return .init(subscriptionStatus: .free, subscriptionInformation: nil) }
        return .init(subscriptionStatus: subscriptionInformation.transaction.subscriptionStatus, subscriptionInformation: subscriptionInformation)
    }
}
