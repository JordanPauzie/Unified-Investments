import Foundation
import SwiftDotenv

class CoinbaseBalance: ObservableObject {
    @Published var totalBalance: (Double, String) = (0, "USD")
    @Published var totalCostBasis: (Double, String) = (0, "USD")
    @Published var assets: [String: Coin] = [:]
    @Published var cash: Double = 0.0

    init() {
        loadEnvSecrets()
        Task {
            await getPortfolioData()
        }
    }

    private func loadEnvSecrets() {
        // WIP
}

    func getPortfolioData() async {
        // WIP
    }
}
