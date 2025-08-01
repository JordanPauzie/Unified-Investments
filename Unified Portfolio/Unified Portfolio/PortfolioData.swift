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

// Since I'm refactoring everything to Swift, I'm not sure if I'll need this logic or not in the future

//func acquireVisualizationData() -> Output? {
//    // let task = Process() 
//    let fileManager = FileManager.default
//    let projectDir = fileManager.currentDirectoryPath
//
//    let sys = Python.import("sys")
//
//    sys.path.append("\(projectDir)/Python")
//
//    // let envPath = "\(projectDir)/Python/coinbase-env/bin/python3"
//    // let envPath = "/usr/bin/python3"
//    // let scriptPath = "\(projectDir)/Python/visualization_data.py"
//
//    let vis = Python.import("visualization_data")
//    let result = vis.get_visualization_data()
//    
//    // task.executableURL = URL(fileURLWithPath: envPath)
//    // task.arguments = [scriptPath]
//
//    // do {
//    //     try task.run()
//    //     task.waitUntilExit()
//    // } catch {
//    //     print("Failed to run Python script: \(error)")
//    // }
//
//    guard let jsonData = try? JSONSerialization.data(withJSONObject: result.__tojson__().asObject, options: []) else {
//        print("Failed to convert Python data to JSON")
//        return nil
//    }
//
//    do {
//        let decoded = try JSONDecoder().decode(Output.self, from: jsonData)
//        return decoded
//    } catch {
//        print("Failed to decode JSON into Swift Output: \(error)")
//        return nil
//    }
//}
