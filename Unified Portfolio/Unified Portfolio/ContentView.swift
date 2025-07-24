//
//  ContentView.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 7/21/25.
//

import SwiftUI

struct ContentView: View {
    // Testing the keychain
    @State private var coinbasePublicKey = ""
    @State private var savedPublicKey = ""

    let secrets = SecretsManager()

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter Coinbase Public Key", text: $coinbasePublicKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Save Key") {
                secrets.setCoinbasePublic(coinbasePublicKey)
            }

            Button("Load Key") {
                savedPublicKey = secrets.getCoinbasePublic() ?? "Nothing found"
            }

            Text("Saved Key: \(savedPublicKey)")
                .padding()
        }
        .padding()
    }
}
