//
//  RadarView.swift
//  LoRaApp
//
//  Created by admin on 12/2/25.
//

import Foundation
import SwiftUI

struct RadarView: View {
    var clientRSSI: [Int64: Int] // clientId : RSSI

    let maxRadius: CGFloat = 150 // maximum distance from center

    func rssiToDistance(_ rssi: Int) -> CGFloat {
        let clamped = min(max(rssi, -100), -40)
        return maxRadius - CGFloat(clamped + 100) * (maxRadius - 20) / 60
    }

    func rssiToColor(_ rssi: Int) -> Color {
        switch rssi {
        case Int.min ... -81: return .red
        case -80 ... -61: return .yellow
        case -60 ... 0: return .green
        default: return .gray
        }
    }

    var body: some View {
        ZStack {
            // Concentric rings (optional)
            ForEach([50, 100, 150], id: \.self) { radius in
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    .frame(width: CGFloat(radius*2), height: CGFloat(radius*2))
            }

            // Master node
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
            Text("Master")
                .foregroundColor(.white)
                .font(.caption)
                .offset(y: 30)

            // Clients
            ForEach(Array(clientRSSI.keys), id: \.self) { clientId in
                let rssi = clientRSSI[clientId] ?? -100
                let distance = rssiToDistance(rssi)
                let angles: [Int64: Double] = [0xB1: 45, 0xB2: 135] // fixed positions
                let angle = (angles[clientId] ?? 0) * .pi / 180
                let x = cos(angle) * distance
                let y = sin(angle) * distance

                ZStack {
                    Circle()
                        .fill(rssiToColor(rssi))
                        .frame(width: 30, height: 30)
                    Text(String(format: "0x%02X", clientId))
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .offset(x: x, y: y)
                .animation(.easeInOut(duration: 0.3), value: rssi)
            }
        }
        .frame(width: maxRadius * 2 + 50, height: maxRadius * 2 + 50)
    }
}
