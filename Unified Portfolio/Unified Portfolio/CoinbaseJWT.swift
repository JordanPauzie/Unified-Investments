//
//  CoinbaseJWT.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 8/1/25.
//

import Foundation
import SwiftJWT

struct CoinbaseClaims: Claims {
    let sub: String
    let iss: String
    let nbf: Date
    let exp: Date
    let uri: String
}

func generateCoinbaseJWT(apiKey: String, apiSecret: String, method: String, path: String) throws -> String {
    let now = Date()
    let exp = now.addingTimeInterval(120)
    let uri = "\(method) api.coinbase.com\(path)"

    let claims = CoinbaseClaims(
        sub: apiKey,
        iss: "cdp",
        nbf: now,
        exp: exp,
        uri: uri
    )

    var jwt = JWT(
        header: Header(typ: "JWT", kid: apiKey),
        claims: claims
    )

    let apiSecret = apiSecret.replacingOccurrences(of: "\\n", with: "\n")

    let jwtSigner = JWTSigner.es256(privateKey: Data(apiSecret.utf8))

    return try jwt.sign(using: jwtSigner)
}

