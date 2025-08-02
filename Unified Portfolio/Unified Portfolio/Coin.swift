//
//  Coin.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 7/24/25.
//

import Foundation

struct Coin {
    let coinValue: Double
    let currentValue: Double
    let costAverage: Double
    let costBasis: Double
    let unrealizedReturn: (Double, Bool)

    init(from asset: [String: Any]) {
        self.coinValue = doubleFrom(asset, key: "total_balance_crypto")
        self.currentValue = doubleFrom(asset, key: "total_balance_fiat")
        self.costAverage = doubleFrom(asset["average_entry_price"] as? [String: Any] ?? [:], key: "value")
        self.costBasis = doubleFrom(asset["cost_basis"] as? [String: Any] ?? [:], key: "value")

        let diff = self.currentValue - self.costBasis
        self.unrealizedReturn = (abs(diff), diff >= 0)
    }
}
