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

class SchwabBalance: ObservableObject {
    @Published var totalBalance: (Double, String) = (0, "USD")
    @Published var totalCostBasis: (Double, String) = (0, "USD")
    @Published var assets: [String: Asset] = [:]
    @Published var cash: Double = 0.0
    @Published var hash: String = ""
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
        Task {  
            await getPortfolioData() 
        }
    }

    private func loadSecrets() {
        appKey = keychain.get("SCHWAB_APP_KEY")
        secret = keychain.get("SCHWAB_SECRET")
        callback = keychain.get("SCHWAB_CALLBACK")
    }

    func authRequestTokens() async throws -> TokenResponse {
        guard let clientKey = appKey, let clientSecret = secret, let clientCallback = callback else {
            throw URLError(.badServerResponse)
        }

        let authURLString = "https://api.schwabapi.com/v1/oauth/authorize?client_id=\(clientKey)&redirect_uri=\(clientCallback)"

        print("Go to this URL to authenticate:")
        print(authURLString)

        NSWorkspace.shared.open(URL(string: authURLString)!)

        print("Paste returned URL:")

        guard let returnedURL = readLine(),
            let codeRange = returnedURL.range(of: "code="),
            let atRange = returnedURL.range(of: "%40") 
        else {
            throw URLError(.badServerResponse)
        }

        let responseCode = String(returnedURL[codeRange.upperBound..<atRange.lowerBound]) + "@"
        let credentials = "\(clientKey):\(clientSecret)"
        let base64Credentials = Data(credentials.utf8).base64EncodedString()

        var request = URLRequest(url: URL(string: "https://api.schwabapi.com/v1/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type": "authorization_code",
            "code": responseCode,
            "redirect_uri": callback
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

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

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let accounts = json["accountNumbers"] as? [[String: Any]],
            let hash = accounts.first?["hashValue"] as? String {
            return hash
        } else {
            throw URLError(.badServerResponse)
        }
    }

    func getPortfolioData() async {
        loadSecrets()
        do {
            // Testing
            let tokens = try await authRequestTokens()

            self.tokens = tokens
            self.hash = try await getHash(tokens: tokens)

            print(self.tokens)
            print(self.hash)
            // WIP
        } catch {
            print("Error during portfolio data fetch: \(error.localizedDescription)")
        }
    }
}
