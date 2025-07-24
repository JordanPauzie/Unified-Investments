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
        self.coinValue = asset["total_balance_crypto"] as? Double ?? 0.0
        self.currentValue = asset["total_balance_fiat"] as? Double ?? 0.0
        self.costAverage = (asset["average_entry_price"] as? [String: Any])?["value"] as? Double ?? 0.0
        self.costBasis = (asset["cost_basis"] as? [String: Any])?["value"] as? Double ?? 0.0

        let diff = self.currentValue - self.costBasis
        self.unrealizedReturn = (abs(diff), diff >= 0)
    }
}
