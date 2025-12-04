//
//  ProximityView.swift
//  LoRaApp
//
//  Created by admin on 11/9/25.
//

import Foundation
import SwiftUI

struct ProximityView: View {
    var rssi: Int
    var isLost: Bool // new property

    var normalizedProximity: CGFloat {
        let clamped = min(max(rssi, -100), -40)
        return CGFloat(200 - (clamped + 100) * 3)
    }
    
    var proximityColor: Color {
        if isLost {
            return .red
        }
        switch rssi {
        case Int.min ... -81: return .red
        case -80 ... -61: return .yellow
        case -60 ... 0: return .green
        default: return .gray
        }
    }
    
    var proximityLabel: String {
        if isLost {
            return "Lost"
        }
        switch rssi {
        case Int.min ... -81: return "Far"
        case -80 ... -61: return "Nearby"
        case -60 ... 0: return "Very Close"
        default: return "Out of Range"
        }
    }
    
    var body: some View {
        VStack {
            Text("RSSI: \(rssi) dBm")
                .font(.headline)
            
            Circle()
                .fill(proximityColor.opacity(0.6))
                .frame(width: normalizedProximity, height: normalizedProximity)
                .shadow(radius: 10)
                .animation(.easeInOut(duration: 0.3), value: rssi)
            
            Text(proximityLabel)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
