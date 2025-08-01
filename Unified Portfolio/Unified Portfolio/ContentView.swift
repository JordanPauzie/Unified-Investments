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

    var body: some View {
        VStack(spacing: 20) {
            // --- API Key Entry ---
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

            Divider()

            // --- CoinbaseBalance ViewModel ---
            Button("Fetch Coinbase Portfolio") {
                Task {
                    await coinbaseBalance.getPortfolioData()
                }
            }

            Text("Total Balance: \(coinbaseBalance.totalBalance.0, specifier: "%.2f") \(coinbaseBalance.totalBalance.1)")
                .padding()
        }
        .padding()
    }
}

