//
//  CoinbaseModule.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 7/24/25.
//

import Foundation
import KeychainSwift
import SwiftJWT

class CoinbaseBalance: ObservableObject {
    @Published var totalBalance: (Double, String) = (0, "USD")
    @Published var totalCostBasis: (Double, String) = (0, "USD")
    @Published var assets: [String: Coin] = [:]
    @Published var cash: Double = 0.0

    private var apiKey: String?
    private var apiSecret: String?
    private var uuid: String?
    private var jwt: String?

    private let keychain = KeychainSwift()

    init() {
        loadSecrets()
        Task {  
            await getPortfolioData() 
        }
    }

    private func loadSecrets() {
        apiKey = keychain.get("COINBASE_PUBLIC")
        apiSecret = keychain.get("COINBASE_PRIVATE")
    }

    private func getUUID() async -> String? {
        guard let jwt else {   
            return nil 
        }

        let path = "/api/v3/brokerage/portfolios"

        var request = URLRequest(url: URL(string: "https://api.coinbase.com\(path)")!)

        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("Status: \(httpResponse.statusCode)")
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let portfolios = json["portfolios"] as? [[String: Any]],
                let uuid = portfolios.first?["uuid"] as? String {
                return uuid
            } else { 
                print("Failed to parse JSON for UUID") 
            }
        } catch { 
            print("Request failed: \(error)") 
        }

        return nil
    }

    func getPortfolioData() async {
        loadSecrets()

        guard let apiKey, let apiSecret else {
            print("Missing API credentials")
            return
        }

        var path = "/api/v3/brokerage/portfolios"

        guard let jwtUUID = try? generateCoinbaseJWT(apiKey: apiKey, apiSecret: apiSecret, method: "GET", path: path) else {
            print("Failed to create JWT for portfolio list")
            return
        }

        self.jwt = jwtUUID

        guard let uuid = await getUUID() else {
            print("Could not retrieve UUID")
            return
        }

        path = "/api/v3/brokerage/portfolios/\(uuid)"

        guard let jwtPortfolio = try? generateCoinbaseJWT(apiKey: apiKey, apiSecret: apiSecret, method: "GET", path: path) else {
            print("Failed to create JWT for holdings")
            return
        }

        var request = URLRequest(url: URL(string: "https://api.coinbase.com\(path)")!)

        request.httpMethod = "GET"
        request.setValue("Bearer \(jwtPortfolio)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("Holdings request status: \(httpResponse.statusCode)")
            }

            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                guard let breakdown = json["breakdown"] as? [String: Any],
                    let spotPositions = breakdown["spot_positions"] as? [[String: Any]],
                    let portfolioBalance = breakdown["portfolio_balances"] as? [String: Any],
                    let totalPortfolioBalance = portfolioBalance["total_balance"] as? [String: Any],
                    let totalCurrency = totalPortfolioBalance["currency"] as? String
                else {
                    print("Unexpected JSON structure in holdings")
                    return
                }
                
                let totalValue = doubleFrom(totalPortfolioBalance, key: "value")

                var assetDict: [String: Coin] = [:]
                var totalCostBasis: Double = 0.0
                var totalCash: Double = 0.0

                for asset in spotPositions {
                    if let isCash = asset["is_cash"] as? Bool, !isCash {
                        let coin = Coin(from: asset)
                        let name = asset["asset"] as? String
                        assetDict[name!] = coin
                    } else if asset["total_balance_fiat"] is Double {
                        totalCash = doubleFrom(asset, key: "total_balance_fiat")
                    }

                    if let costBasisDict = asset["cost_basis"] as? [String: Any] {
                        totalCostBasis += doubleFrom(costBasisDict, key: "value")
                    }
                }

                DispatchQueue.main.async {
                    self.totalBalance = (totalValue, totalCurrency)
                    self.totalCostBasis = (totalCostBasis, totalCurrency)
                    self.assets = assetDict
                    self.cash = totalCash
                }

                // Testing
                print(self.totalBalance)
                print(self.totalCostBasis)
                print(self.assets)
                print(self.cash)
            } else {
                print("Failed to decode holdings JSON")
            }
        } catch {
            print("Holdings request failed: \(error)")
        }
    }
}
