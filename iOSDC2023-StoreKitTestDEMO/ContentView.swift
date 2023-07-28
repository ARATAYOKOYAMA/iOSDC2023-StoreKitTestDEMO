//
//  ContentView.swift
//  iOSDC2023-StoreKitTestDEMO
//
//  Created by 横山 新 on 2023/07/26.
//

import SwiftUI
import StoreKit

struct ContentView: View {
    @ObservedObject var presenter: Presenter = .init()

    var body: some View {
        ScrollView {
            Text("ユーザ情報")
                .font(.title)
            meStatus()
                .padding(.horizontal, 12.0)
            Text("商品一覧")
                .font(.title)
            LazyVStack(spacing: 12.0) {
                ForEach(presenter.products) { product in
                    productView(product: product)
                        .padding(.horizontal, 12.0)
                }
            }
        }
        .onAppear {
            Task {
                await presenter.dispatch(action: .startTransactionListener)
                await presenter.dispatch(action: .getMe)
                await presenter.dispatch(action: .getProducts)
            }
        }
        .alert(isPresented: $presenter.isShowAlert) {
            Alert(title: Text("課金エラー"))
        }
    }
}

extension ContentView {
    @ViewBuilder
    private func meStatus() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8.0) {
                Text("status:" + presenter.me.subscriptionStatus.rawValue)
                    .font(.headline)
                Group {
                    if let information = presenter.me.subscriptionInformation {
                        VStack(alignment: .leading, spacing: 8.0) {
                            Text("productID:" + information.transaction.productID)
                            Text("startDate:" + "\(information.transaction.purchaseDate)")
                            Text("expirationDate:" + "\(String(describing: information.transaction.expirationDate))")
                            Text("willAutoRenew:" + "\(information.renewalInfo.willAutoRenew))")
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private func productView(product: Product) -> some View {
        Button {
            Task {
                await presenter.dispatch(action: .purchase(product: product))
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8.0) {
                    Text(product.id)
                        .font(.headline)
                    Text(product.displayPrice)
                        .font(.subheadline)
                }
                Spacer()
            }
        }
        .padding()
        .border(.blue)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
