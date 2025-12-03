//
//  LoRaMessage.swift
//  LoRaApp
//
//  Created by admin on 12/3/25.
//

import Foundation

struct LoRaMessage: Codable {
    let source: Int64
    let target: Int64
    let rssi: Int64
    let isLost: Bool
}
