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

// Combined wrapper
struct output: Codable {
    let portfolio_data: PortfolioData
    let assets: [[String]]
    let pie_chart: PieChartData
}

func acquireVisualizationData() {
    let task = Process()
    
    let fileManager = FileManager.default
    let projectDir = fileManager.currentDirectoryPath

    let envPath = "\(projectDir)/Python/coinbase-env/bin/python3"
    let scriptPath = "\(projectDir)/Python/visualization_data.py"
    
    task.executableURL = URL(fileURLWithPath: envPath)
    task.arguments = [scriptPath]

    do {
        try task.run()
        task.waitUntilExit()
    } catch {
        print("Failed to run Python script: \(error)")
    }
}

func loadPortfolioData() throws -> output {
    let fileManager = FileManager.default
    let projectDir = fileManager.currentDirectoryPath

    let jsonPath = "\(projectDir)/Python/visualization_data.json"
    let url = URL(fileURLWithPath: jsonPath)
    let data = try Data(contentsOf: url)

    return try JSONDecoder().decode(output.self, from: data)
}
