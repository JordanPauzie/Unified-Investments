//
//  ContentView.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 7/21/25.
//

import SwiftUI
import PythonKit

struct ContentView: View {
    @State private var coinbasePublicKey = ""
    @State private var coinbasePrivateKey = ""
    @State private var savedPublicKey = ""
    @State private var savedPrivateKey = ""

    let secrets = SecretsManager()

    @StateObject private var coinbaseBalance = CoinbaseBalance()
    @StateObject private var schwabBalance = SchwabBalance()

    @State private var schwabHash = ""

    @State private var schwabKey = ""
    @State private var schwabSecret = ""
    @State private var schwabCallback = ""
    @State private var savedSchwabKey = ""
    @State private var savedSchwabSecret = ""
    @State private var savedSchwabCallback = ""

    @State private var schwabAuthMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // --- Coinbase Section ---
                Text("🪙 Coinbase")
                    .font(.headline)

                TextField("Enter Coinbase Public Key", text: $coinbasePublicKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Save Public Key") {
                    secrets.setCoinbasePublic(coinbasePublicKey)
                }

                Button("Load Public Key") {
                    savedPublicKey = secrets.getCoinbasePublic() ?? "Nothing found"
                }

                Text("Saved Public Key: \(savedPublicKey)")
                    .padding()

                TextField("Enter Coinbase Private Key", text: $coinbasePrivateKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Save Private Key") {
                    secrets.setCoinbasePrivate(coinbasePrivateKey)
                }

                Button("Load Private Key") {
                    savedPrivateKey = secrets.getCoinbasePrivate() ?? "Nothing found"
                }

                Text("Saved Private Key: \(savedPrivateKey)")
                    .padding()

                Button("Fetch Coinbase Portfolio") {
                    Task {
                        await coinbaseBalance.getPortfolioData()
                    }
                }

                Text("Total Balance: \(coinbaseBalance.totalBalance.0, specifier: "%.2f") \(coinbaseBalance.totalBalance.1)")
                    .padding()

                Divider()

                // --- Schwab Section ---
                Text("🏦 Schwab")
                    .font(.headline)

                TextField("Enter Schwab Key", text: $schwabKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Save Public Key") {
                    secrets.setSchwabAppKey(schwabKey)
                }

                Button("Load Public Key") {
                    savedSchwabKey = secrets.getSchwabAppKey() ?? "Nothing found"
                }

                Text("Saved Public Key: \(savedSchwabKey)")
                    .padding()

                TextField("Enter Schwab Secret", text: $schwabSecret)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Save Private Key") {
                    secrets.setSchwabSecret(schwabSecret)
                }

                Button("Load Private Key") {
                    savedSchwabSecret = secrets.getSchwabSecret() ?? "Nothing found"
                }

                Text("Saved Private Key: \(savedSchwabSecret)")
                    .padding()

                TextField("Enter Schwab Callback", text: $schwabCallback)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Save Private Key") {
                    secrets.setSchwabCallback(schwabCallback)
                }

                Button("Load Private Key") {
                    savedSchwabCallback = secrets.getSchwabCallback() ?? "Nothing found"
                }

                Text("Saved Private Key: \(savedSchwabCallback)")
                    .padding()

                // Button("Fetch Schwab Portfolio") {
                //     Task {
                //         await schwabBalance.getPortfolioData()
                //     }
                    
                //     Task {
                //         do {
                //             let tokens = try await schwabBalance.authRequestTokens()                        
                //             schwabHash = try await schwabBalance.getHash(tokens: tokens)
                //             schwabAuthMessage = "Succesful token/hash retrieval."
                //         } catch {
                //             print("Error during auth/token/hash: \(error)")
                //         }
                //     }
                // }

                Text("Step 1: Open Schwab Auth Link")
                Button("Open Schwab Login") {
                    if let url = schwabBalance.makeAuthURL() {
                        NSWorkspace.shared.open(url)
                    }
                }

                Text("Step 2: Paste returned URL here:")
                TextField("Paste redirect URL", text: $schwabBalance.returnedURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Exchange Code for Tokens") {
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
                    do {
                        // Step 3: Fetch balances
                        await schwabBalance.getPortfolioData()
                        schwabAuthMessage = "✅ Successful token/hash retrieval."
                    } catch {
                        schwabAuthMessage = "❌ Error: \(error.localizedDescription)"
                    }
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


