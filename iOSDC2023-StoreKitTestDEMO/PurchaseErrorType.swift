//
//  PurchaseErrorType.swift
//  iOSDC2023-StoreKitTestDEMO
//
//  Created by 横山 新 on 2023/07/26.
//

import StoreKit

enum PurchaseErrorType: String, Error {
    case userCancelled
    case pending
    case unknown

    init(error: Error) {
        self = .unknown
    }
}
