//
//  iOSDC2023_StoreKitTestDEMOTests.swift
//  iOSDC2023-StoreKitTestDEMOTests
//
//  Created by 横山 新 on 2023/07/26.
//

import StoreKitTest
import XCTest

@testable import iOSDC2023_StoreKitTestDEMO

@MainActor
final class iOSDC2023_StoreKitTestDEMOTests: XCTestCase {
    private var dependency: Dependency!

    override func setUpWithError() throws {
        try super.setUpWithError()
        dependency = try Dependency()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        dependency.session.clearTransactions()
    }

    // 成功
    func testBuy() async throws {
        let products = try await Product.products(for: [Const.productID])
        let product = try XCTUnwrap(products.first)

        XCTAssertEqual(dependency.testTarget.me.subscriptionStatus, .free)
        try await dependency.testTarget.dispatch(action: .purchase(product: product))
        XCTAssertEqual(dependency.testTarget.me.subscriptionStatus, .membership)
    }

    // 失敗
    func testFailBuy() async throws {
        dependency.session.failureError = .unknown
        dependency.session.failTransactionsEnabled = true

        let products = try await Product.products(for: [Const.productID])
        let product = try XCTUnwrap(products.first)

        XCTAssertEqual(dependency.testTarget.me.subscriptionStatus, .free)
        try await dependency.testTarget.dispatch(action: .purchase(product: product))
        XCTAssertEqual(dependency.testTarget.me.subscriptionStatus, .free)
        XCTAssertEqual(dependency.testTarget.isShowAlert, true)
    }

    // 復元
    func testRestore() async throws {
        try dependency.session.buyProduct(productIdentifier: Const.productID)
        XCTAssertEqual(dependency.testTarget.me.subscriptionStatus, .free)
        try await dependency.testTarget.dispatch(action: .getMe)
        XCTAssertEqual(dependency.testTarget.me.subscriptionStatus, .membership)
    }

    // transaction.updatesの監視
    func testTransactionListener() async throws {
        XCTAssertEqual(dependency.testTarget.me.subscriptionStatus, .free)
        try await dependency.testTarget.dispatch(action: .startTransactionListener)
        try dependency.session.buyProduct(productIdentifier: Const.productID)
        try await Task.sleep(nanoseconds: 6 * 1_000_000_000)
        XCTAssertEqual(dependency.testTarget.me.subscriptionStatus, .membership)
    }

    // Grace Period
    func testGracePeriod() async throws {
        dependency.session.billingGracePeriodIsEnabled = true
        dependency.session.shouldEnterBillingRetryOnRenewal = true

        XCTAssertEqual(dependency.testTarget.me.subscriptionStatus, .free)
        try dependency.session.buyProduct(productIdentifier: Const.productID)
        try dependency.session.forceRenewalOfSubscription(productIdentifier: Const.productID)
        try await dependency.testTarget.dispatch(action: .getMe)
        XCTAssertEqual(dependency.testTarget.me.subscriptionStatus, .membership)
        XCTAssertEqual(dependency.testTarget.me.subscriptionInformation?.renewalState, .inGracePeriod)

        dependency.session.billingGracePeriodIsEnabled = false
        dependency.session.shouldEnterBillingRetryOnRenewal = false
    }
}

extension iOSDC2023_StoreKitTestDEMOTests {
    enum Const {
        static let productID = "iosdc2023.1month"
        static let configurationFileNamed = "iOSDC2023"
    }

    @MainActor
    struct Dependency {
        let testTarget: Presenter
        let session: SKTestSession

        init() throws {
            self.testTarget = Presenter()
            self.session = try SKTestSession(configurationFileNamed: Const.configurationFileNamed)
            self.session.disableDialogs = true
            self.session.clearTransactions()
            self.session.failTransactionsEnabled = false
            self.session.timeRate = .oneRenewalEveryTwoSeconds
        }
    }
}
