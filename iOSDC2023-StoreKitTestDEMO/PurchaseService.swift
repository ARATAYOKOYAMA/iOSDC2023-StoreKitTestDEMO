//
//  PurchaseService.swift
//  iOSDC2023-StoreKitTestDEMO
//
//  Created by 横山 新 on 2023/07/26.
//

import Combine
import StoreKit

typealias Transaction = StoreKit.Transaction
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState
typealias PurchaseOption = StoreKit.Product.PurchaseOption

struct SubscriptionInformation {
    public let renewalState: RenewalState
    public let renewalInfo: RenewalInfo
    public let transaction: Transaction
}

final actor PurchaseService {
    static let productIDs: [String] = ["iosdc2023.1month", "iosdc2023.3month", "iosdc2023.premium.1month", "iosdc2023.premium.3month"]

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case let .unverified(_, verificationError):
            throw verificationError

        case let .verified(safe):
            return safe
        }
    }
}

extension PurchaseService {
    func getProducts() async throws -> [Product] {
        try await Product.products(for: PurchaseService.productIDs)
    }
}

extension PurchaseService {
    func purchase(_ product: Product, option: Set<PurchaseOption>) async throws -> Transaction {
        let result = try await product.purchase(options: option)
        switch result {
        case let .success(verification):
            let transaction = try checkVerified(verification)
            return try await sendPurchase(transaction: transaction, signedTransactionInfo: verification.jwsRepresentation)

        case .userCancelled:
            throw PurchaseErrorType.userCancelled

        case .pending:
            throw PurchaseErrorType.pending

        @unknown default:
            throw PurchaseErrorType.unknown
        }
    }

    func sendPurchase(transaction: Transaction, signedTransactionInfo: String) async throws -> Transaction {
        switch transaction.productType {
        case .autoRenewable, .nonRenewable:
            await transaction.finish()
            return transaction

        case .consumable, .nonConsumable:
            await transaction.finish()
            return transaction

        default:
            throw PurchaseErrorType.unknown
        }
    }
}

extension PurchaseService {
    func getCurrentEntitlements() async throws -> [SubscriptionInformation] {
        var subscriptionGroupIds: [String] = []
        for await result in Transaction.currentEntitlements {
            let transaction = try self.checkVerified(result)
            guard let groupId = transaction.subscriptionGroupID else { continue }
            subscriptionGroupIds.append(groupId)
        }
        var activeSubscriptionInfos: [SubscriptionInformation] = []
        for groupId in Set(subscriptionGroupIds) {
            let subscriptionInfo = try await getSubscriptionInfo(groupID: groupId)
            subscriptionInfo
                .filter { $0.renewalState.isActive }
                .forEach { activeSubscriptionInfos.append($0) }
        }
        return activeSubscriptionInfos
    }

    private func getSubscriptionInfo(groupID: String) async throws -> [SubscriptionInformation] {
        var results: [SubscriptionInformation] = []

        let statuses = try await Product.SubscriptionInfo.status(for: groupID)
        for status in statuses {
            guard case .verified(let renewalInfo) = status.renewalInfo,
                case .verified(let transaction) = status.transaction
            else {
                continue
            }
            results.append(.init(renewalState: status.state, renewalInfo: renewalInfo, transaction: transaction))
        }
        return results
    }
}

extension Product.SubscriptionInfo.RenewalState {
    // Check whether the subscription available.
    public var isActive: Bool {
        self == .subscribed || self == .inGracePeriod
    }
}

extension StoreKit.Transaction {
    public var isRevoked: Bool {
        // The revocation date is never in the future.
        revocationDate != nil
    }
}
