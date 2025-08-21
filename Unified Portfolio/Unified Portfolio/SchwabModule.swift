//
//  SchwabModule.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 8/2/25.
//

import Foundation
import KeychainSwift
import AppKit

struct TokenResponse: Codable {
    let refreshToken: String
    let accessToken: String
    let idToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
        case accessToken = "access_token"
        case idToken = "id_token"
    }
}

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

@MainActor
class SchwabBalance: ObservableObject {
    @Published var totalBalance: (Double, String) = (0, "USD")
    @Published var totalCostBasis: (Double, String) = (0, "USD")
    @Published var assets: [String: Asset] = [:]
    @Published var cash: Double = 0.0
    @Published var hash: String = ""
    @Published var returnedURL: String = ""
    @Published var tokens: TokenResponse = TokenResponse(
        refreshToken: "",
        accessToken: "",
        idToken: ""
    )

    private var appKey: String?
    private var secret: String?
    private var callback: String?

    private let keychain = KeychainSwift()

    init() {
        loadSecrets()
    }

    private func loadSecrets() {
        appKey = keychain.get("SCHWAB_APP_KEY")
        secret = keychain.get("SCHWAB_SECRET")
        callback = keychain.get("SCHWAB_CALLBACK")
    }

    func makeAuthURL() -> URL? {
        guard let clientKey = appKey, 
            let clientCallback = callback else { 
            return nil 
        }

        let urlString = "https://api.schwabapi.com/v1/oauth/authorize?client_id=\(clientKey)&redirect_uri=\(clientCallback)"

        return URL(string: urlString)
    }

    func authRequestTokens(from returnedURL: String) async throws -> TokenResponse {
        guard let clientKey = appKey,
            let clientSecret = secret,
            let clientCallback = callback else {
            throw URLError(.badServerResponse)
        }

        guard let codeRange = returnedURL.range(of: "code="),
            let atRange = returnedURL.range(of: "%40") else {
            throw URLError(.badServerResponse)
        }

        let responseCodeStartIndex = returnedURL.index(codeRange.lowerBound, offsetBy: 5)
        let responseCode = String(returnedURL[responseCodeStartIndex..<atRange.lowerBound]) + "@"

        let credentials = "\(clientKey):\(clientSecret)"
        let base64Credentials = Data(credentials.utf8).base64EncodedString()

        var request = URLRequest(url: URL(string: "https://api.schwabapi.com/v1/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type": "authorization_code",
            "code": responseCode,
            "redirect_uri": clientCallback
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP status: \(httpResponse.statusCode)")
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        return tokenResponse
    }

    func getHash(tokens: TokenResponse) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.schwabapi.com/trader/v1/accounts/accountNumbers")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        if let accounts = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
        let hash = accounts.first?["hashValue"] as? String {
            return hash
        } else {
            throw URLError(.badServerResponse)
        }
    }

    func refreshTokens(tokens: TokenResponse) async throws -> TokenResponse {
        guard let clientKey = appKey,
            let clientSecret = secret else {
            throw URLError(.badServerResponse)
        }

        let credentials = "\(clientKey):\(clientSecret)"
        let base64Credentials = Data(credentials.utf8).base64EncodedString()
        let refreshToken = tokens.refreshToken

        var request = URLRequest(url: URL(string: "https://api.schwabapi.com/v1/oauth/token")!)
        
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP status: \(httpResponse.statusCode)")
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        return tokenResponse
    }

    func getPortfolioData() async {
        do {
            self.tokens = try await refreshTokens(tokens: self.tokens)

            var request = URLRequest(
                url: URL(string: "https://api.schwabapi.com/trader/v1/accounts/\(self.hash)?fields=positions")!
            )
            request.httpMethod = "GET"
            request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let securities = json["securitiesAccount"] as? [String: Any],
            let positions = securities["positions"] as? [[String: Any]],
            let balances = securities["currentBalances"] as? [String: Any] {
                DispatchQueue.main.async {
                    self.assets.removeAll()
                    self.totalCostBasis = (0, "USD")

                    for pos in positions {
                        let asset = Asset(from: pos)
                        if let instrument = pos["instrument"] as? [String: Any],
                        let symbol = instrument["symbol"] as? String {
                            self.assets[symbol] = asset
                        }

                        if let openPL = pos["longOpenProfitLoss"] as? Double {
                            self.totalCostBasis.0 += openPL
                        }
                    }

                    self.cash = balances["cashBalance"] as? Double ?? 0.0
                    self.totalBalance = (balances["liquidationValue"] as? Double ?? 0.0, "USD")
                    self.totalCostBasis.0 += self.totalBalance.0
                }
            }
            
            // Testing
                print(self.totalBalance)
                print(self.totalCostBasis)
                print(self.assets)
                print(self.cash)
        } catch {
            print("Error fetching portfolio: \(error.localizedDescription)")
        }
    }
}
