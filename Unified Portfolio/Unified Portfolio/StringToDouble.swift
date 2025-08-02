//
//  StringToDouble.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 8/2/25.
//

func doubleFrom(_ dict: [String: Any], key: String) -> Double {
        if let str = dict[key] as? String {
            return Double(str) ?? 0.0
        } else if let val = dict[key] as? Double {
            return val
        }
        return 0.0
    }
