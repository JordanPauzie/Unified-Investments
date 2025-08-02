//
//  Asset.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 8/2/25.
//

import Foundation

struct Asset {
    let type: String
    let assetCount: Double
    let currentValue: Double
    let costAverage: Double
    let unrealizedReturn: Double

    init(from asset: [String: Any]) {
        let instrument = asset["instrument"] as? [String: Any] ?? [:]
        
        self.type = instrument["type"] as? String ?? "Unknown"
        self.assetCount = doubleFrom(asset, key: "longQuantity")
        self.currentValue = doubleFrom(asset, key: "marketValue")
        self.costAverage = doubleFrom(asset, key: "averagePrice")
        self.unrealizedReturn = doubleFrom(asset, key: "longOpenProfitLoss")
    }
}
