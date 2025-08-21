//
//  ContentView.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 7/21/25.
//

import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var coinbaseBalance = CoinbaseBalance()
    @Published var schwabBalance = SchwabBalance()
    
    let secrets = SecretsManager()
}

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var selection: SidebarItem? = .portfolio
    
    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) {
                item in Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle("Unified Portfolio")
        } detail: {
            switch selection {
            case .portfolio:
                PortfolioView(
                    coinbaseBalance: appState.coinbaseBalance,
                    schwabBalance: appState.schwabBalance
                )
            case .keys:
                KeysView(secrets: appState.secrets)
            case .none:
                Text("Select a section")
            }
        }
    }
    
    enum SidebarItem: String, CaseIterable, Identifiable {
        case keys = "Keys"
        case portfolio = "Portfolio"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .keys: return "key.fill"
            case .portfolio: return "chart.bar.fill"
            }
        }
    }
    
    struct KeysView: View {
        @ObservedObject var secrets: SecretsManagerWrapper
    
        @State private var coinbasePublicKey = ""
        @State private var coinbasePrivateKey = ""
        @State private var schwabKey = ""
        @State private var schwabSecret = ""
        @State private var schwabCallback = ""

        init(secrets: SecretsManager) {
            self.secrets = SecretsManagerWrapper(secrets: secrets)
            self._coinbasePublicKey = State(initialValue: secrets.getCoinbasePublic() ?? "")
            self._coinbasePrivateKey = State(initialValue: secrets.getCoinbasePrivate() ?? "")
            self._schwabKey = State(initialValue: secrets.getSchwabAppKey() ?? "")
            self._schwabSecret = State(initialValue: secrets.getSchwabSecret() ?? "")
            self._schwabCallback = State(initialValue: secrets.getSchwabCallback() ?? "")
        }
        
        var body: some View {
            VStack {
                Text("🪙 Coinbase")
                    .font(.headline)
                
                TextField("Coinbase Public Key", text: $coinbasePublicKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Coinbase Private Key", text: $coinbasePrivateKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Save Coinbase Credentials") {
                    secrets.setCoinbasePublic(coinbasePublicKey)
                    secrets.setCoinbasePrivate(coinbasePrivateKey)

                    // Testing
                    print("Saved Public Key: \(String(describing: secrets.getCoinbasePublic()))")
                    print("Saved Private Key: \(String(describing: secrets.getCoinbasePrivate()))")
                }
                
                
                Divider()
                
                Text("🏦 Schwab")
                    .font(.headline)
                
                TextField("Schwab App Key", text: $schwabKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Schwab Secret", text: $schwabSecret)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Schwab Callback", text: $schwabCallback)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Save Schwab Credentials") {
                    secrets.setSchwabAppKey(schwabKey)
                    secrets.setSchwabSecret(schwabSecret)
                    secrets.setSchwabCallback(schwabCallback)

                    // Testing
                    print("Saved App Key: \(String(describing: secrets.getSchwabAppKey()))")
                    print("Saved Secret: \(String(describing: secrets.getSchwabSecret()))")
                    print("Saved Callbacks: \(String(describing: secrets.getSchwabCallback()))")
                }
                .padding()
            }
        }
    }
    
    struct PortfolioView: View {
        @ObservedObject var coinbaseBalance: CoinbaseBalance
        @ObservedObject var schwabBalance: SchwabBalance

        @State private var schwabAuthMessage: String = ""
        
        var body: some View {
            VStack {
                Text("🪙 Coinbase")
                    .font(.headline)
                
                Button("Fetch Coinbase Portfolio") {
                    Task {
                        await coinbaseBalance.getPortfolioData()
                    }
                }
                
                Text("Total Balance: \(coinbaseBalance.totalBalance.0, specifier: "%.2f") \(coinbaseBalance.totalBalance.1)")
                    .padding()
                
                Divider()
                
                Text("🏦 Schwab")
                    .font(.headline)
                
                Button("Schwab API Login") {
                    if let url = schwabBalance.makeAuthURL() {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                TextField("Paste Redirect URL", text: $schwabBalance.returnedURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Initialize Tokens") {
                    Task {
                        do {
                            let tokens = try await schwabBalance.authRequestTokens(from: schwabBalance.returnedURL)
                            schwabBalance.tokens = tokens
                            schwabBalance.hash = try await schwabBalance.getHash(tokens: tokens)
                            schwabAuthMessage = "✅ Succesful token/hash retrieval."
                        } catch {
                            schwabAuthMessage = "❌ Error: \(error.localizedDescription)"
                        }
                    }
                }
                
                Button("Fetch Schwab Portfolio") {
                    Task {
                        await schwabBalance.getPortfolioData()
                        schwabAuthMessage = "✅ Successful token/hash retrieval."
                    }
                }
                
                Text(schwabAuthMessage)
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            .padding()
        }
    }
}

class SecretsManagerWrapper: ObservableObject {
    private let secrets: SecretsManager
    
    init(secrets: SecretsManager) {
        self.secrets = secrets
    }
    
    func setCoinbasePublic(_ value: String) { secrets.setCoinbasePublic(value) }
    func setCoinbasePrivate(_ value: String) { secrets.setCoinbasePrivate(value) }
    func setSchwabAppKey(_ value: String) { secrets.setSchwabAppKey(value) }
    func setSchwabSecret(_ value: String) { secrets.setSchwabSecret(value) }
    func setSchwabCallback(_ value: String) { secrets.setSchwabCallback(value) }
    
    func getCoinbasePublic() -> String? { secrets.getCoinbasePublic() }
    func getCoinbasePrivate() -> String? { secrets.getCoinbasePrivate() }
    func getSchwabAppKey() -> String? { secrets.getSchwabAppKey() }
    func getSchwabSecret() -> String? { secrets.getSchwabSecret() }
    func getSchwabCallback() -> String? { secrets.getSchwabCallback() }
}