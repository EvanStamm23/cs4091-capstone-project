//
//  ContentView.swift
//  LoRaApp
//
//  Created by admin on 11/8/25.
//
// default view for app ==> MAIN UI
// where displayed received messages from LoRa device will go

import SwiftUI

struct ContentView: View {
    @StateObject var bleManager = BLEManager() // Our BLE logic
    @State private var currentNodeId: Int64 = 1 // node connecting to app
    
    // used to visualize db
    @State private var showRSSILogs = false
    @State private var displayedLogs: [RSSILogEntity] = []
    
    func nodeName(for id: Int64) -> String {
        switch id {
        case 0xAA: return "Master"
        case 0xB1: return "Client 1"
        case 0xB2: return "Client 2"
        default: return String(format: "0x%02X", id)
        }
    }

    var body: some View {
        VStack {
            // App logo at the top
            Image("Image")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100) // adjust size
            
            Text("Connected to: Master")
                .font(.headline)
                .padding(.bottom, 10)
            
            Divider()
            
            // Display RSSI for Master and Clients
            RadarView(clientRSSI: bleManager.nodeRSSI.filter { $0.key != 0xAA })
                .padding()
            
            Divider()

            Text("LoRa BLE Messages")
                .font(.headline)
            List(bleManager.messages, id: \.self) { message in
                Text(message)
            }
            
            Button(showRSSILogs ? "Hide RSSI Values" : "Show Saved RSSI Values") {
                if showRSSILogs {
                    // Hide logs
                    showRSSILogs = false
                    displayedLogs = []
                } else {
                    // Show logs
                    let manager = NodeManager()
                    // Example: fetch all logs for current node
                    if let node = manager.findNode(byId: currentNodeId) {
                        displayedLogs = manager.fetchRSSILogs(for: node)
                    }
                    showRSSILogs = true
                }
            }
            if showRSSILogs {
                List(displayedLogs, id: \.timestamp) { log in
                    HStack {
                        Text("Source: \(log.sourceNodeId)")
                        Text("Target: \(log.targetNodeId)")
                        Text("RSSI: \(log.rssiValue) dBm")
                        Spacer()
                        if let timestamp = log.timestamp {
                            Text(timestamp, style: .time)
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
                .frame(maxHeight: 300) // optional height limit
            }

        }
        .padding()
    }
}


#Preview {
    ContentView()
}
