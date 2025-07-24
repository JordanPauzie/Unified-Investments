//
//  SecretsManager.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 7/24/25.
//

import Foundation
import KeychainSwift

class SecretsManager {
    private let keychain = KeychainSwift()

    private enum Key: String {
        case coinbasePublic = "COINBASE_PUBLIC"
        case coinbasePrivate = "COINBASE_PRIVATE"
        case schwabAppKey = "SCHWAB_APP_KEY"
        case schwabSecret = "SCHWAB_SECRET"
        case schwabCallback = "SCHWAB_CALLBACK"
        case totalInitial = "TOTAL_INITIAL"
    }

    func setCoinbasePublic(_ value: String) {
        keychain.set(value, forKey: Key.coinbasePublic.rawValue)
    }

    func setCoinbasePrivate(_ value: String) {
        keychain.set(value, forKey: Key.coinbasePrivate.rawValue)
    }

    func setSchwabAppKey(_ value: String) {
        keychain.set(value, forKey: Key.schwabAppKey.rawValue)
    }

    func setSchwabSecret(_ value: String) {
        keychain.set(value, forKey: Key.schwabSecret.rawValue)
    }

    func setSchwabCallback(_ value: String) {
        keychain.set(value, forKey: Key.schwabCallback.rawValue)
    }

    func setInitialInvestment(_ value: String) {
        keychain.set(value, forKey: Key.totalInitial.rawValue)
    }

    func getCoinbasePublic() -> String? {
        keychain.get(Key.coinbasePublic.rawValue)
    }

    func getCoinbasePrivate() -> String? {
        keychain.get(Key.coinbasePrivate.rawValue)
    }

    func getSchwabAppKey() -> String? {
        keychain.get(Key.schwabAppKey.rawValue)
    }

    func getSchwabSecret() -> String? {
        keychain.get(Key.schwabSecret.rawValue)
    }

    func getSchwabCallback() -> String? {
        keychain.get(Key.schwabCallback.rawValue)
    }

    func getInitialInvestment() -> String? {
        keychain.get(Key.totalInitial.rawValue)
    }
}
