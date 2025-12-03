//
//  NodeNaming.swift
//  LoRaApp
//
//  Created by admin on 12/3/25.
//

import Foundation

func nodeName(for id: Int64) -> String {
    switch id {
    case 0xAA:
        return "Master"
    case 0xB1:
        return "Client 1"
    case 0xB2:
        return "Client 2"
    default:
        return String(format: "0x%02X", id)
    }
}
