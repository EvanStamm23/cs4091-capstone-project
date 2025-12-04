//
//  LoRaMessage.swift
//  LoRaApp
//
//  Created by admin on 12/3/25.
//

import Foundation

struct LoRaMessage: Codable {
    let id: String
    let rssi: Int64
    let isLost: Bool

    var source: Int64 {
        // convert id hex string like "b1" to decimal Int64
        return Int64(id, radix: 16) ?? 0
    }
    
    var target: Int64 {
        return -1 // Arduino doesn’t send target
    }
}

