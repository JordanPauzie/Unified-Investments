//
//  PortfolioData.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 7/22/25.
//

import Foundation

struct PortfolioData: Codable {
    let initial_investment: Double
    let total_cost_basis: Double
    let total_balance: Double
    let total_unrealized_return: Double
}

struct PieChartData: Codable {
    let labels: [String]
    let values: [Double]
}

struct Output: Codable {
    let portfolio_data: PortfolioData
    let assets: [[String]]
    let pie_chart: PieChartData
}