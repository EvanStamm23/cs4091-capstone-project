//
//  ClientDot.swift
//  LoRaApp
//
//  Created by admin on 12/3/25.
//

import Foundation
import SwiftUI

struct ClientDot: View {
    let clientName: String
    let rssi: Int
    let isLost: Bool
    
    @State private var pulse = false
    
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
            Circle()
                .fill(isLost ? Color.red : rssiToColor(rssi))
                .frame(width: 30, height: 30)
                .opacity(isLost ? (pulse ? 0.2 : 1.0) : 1.0)
                .onAppear { startPulseIfLost() }
                .onChange(of: isLost) { newValue, _ in
                    startPulseIfLost()
                }
            Text(clientName)
                .font(.caption2)
                .foregroundColor(.white)
        }
    }
    
    private func startPulseIfLost() {
        guard isLost else { return }
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            pulse.toggle()
        }
    }
}
