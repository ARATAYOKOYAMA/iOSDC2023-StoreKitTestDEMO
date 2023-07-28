//
//  Presenter.swift
//  iOSDC2023-StoreKitTestDEMO
//
//  Created by 横山 新 on 2023/07/26.
//

import StoreKit
import SwiftUI

enum PresenterAction {
    case startTransactionListener
    case getMe
    case getProducts
    case purchase(product: Product)
}

@MainActor
final class Presenter: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var me: Me = .init(subscriptionStatus: .free, subscriptionInformation: nil)
    @Published var isShowAlert: Bool = false

    private let meService: MeService
    private let purchaseService: PurchaseService
    private var transactionUpdatesTask: Task<Void, Error>?

    init() {
        self.meService = .init()
        self.purchaseService = .init()
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func dispatch(action: PresenterAction) async {
        switch action {
        case .startTransactionListener:
            startTransactionListener()

        case .getMe:
            await getMe()

        case .getProducts:
            await getProducts()

        case let .purchase(product):
            await purchase(product: product)
        }
    }

    private func startTransactionListener() {
        if transactionUpdatesTask == nil {
            self.transactionUpdatesTask = Task(priority: .background) {
                for await update in Transaction.updates {
                    do {
                        let transaction = try await self.purchaseService.checkVerified(update)
                        guard transaction.revocationDate == nil,
                            !transaction.isRevoked,
                            !transaction.isUpgraded
                        else { return }
                        _ = try await self.purchaseService.sendPurchase(transaction: transaction, signedTransactionInfo: update.jwsRepresentation)
                        await getMe()
                    } catch {
                        self.isShowAlert = true
                    }
                }
            }
        }
    }

    private func getMe() async {
        do {
            let entitlements = try await self.purchaseService.getCurrentEntitlements()
            let me = self.meService.getMe(entitlements: entitlements)
            self.me = me
        } catch {
            self.isShowAlert = true
        }
    }

    private func getProducts() async {
        do {
            self.products = try await self.purchaseService.getProducts()
        } catch {
            self.products = []
            self.isShowAlert = true
        }
    }

    private func purchase(product: Product) async {
        do {
            _ = try await self.purchaseService.purchase(product, option: [])
            await getMe()
        } catch {
            let purchaseError = PurchaseErrorType(error: error)
            guard purchaseError != .userCancelled else { return }
            self.isShowAlert = true
        }
    }
}
