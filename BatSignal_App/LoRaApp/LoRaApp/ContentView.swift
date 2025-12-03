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
    
    // Mark Client lost
    @State private var lostClients: [Int64: Bool] = [:] // clientId -> isLost
    @State private var selectedClientId: Int64 = 0xB1

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
            RadarView(
                clientRSSI: bleManager.nodeRSSI.filter { $0.key != 0xAA },
                lostClients: lostClients
            )
            .padding()

            
            Divider()

            Text("LoRa BLE Messages")
                .font(.headline)
            List(bleManager.messages, id: \.self) { message in
                Text(message)
            }
            
            Text("Select Client to Report Lost:")
            Picker("Client", selection: $selectedClientId) {
                Text("Client 1").tag(Int64(0xB1))
                Text("Client 2").tag(Int64(0xB2))
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Report lost client button
            Button(lostClients[selectedClientId] == true ? "Client Found" : "Client Lost") {
                // Toggle the lost state
                let newState = !(lostClients[selectedClientId] ?? false)
                
                // Update the UI state
                lostClients[selectedClientId] = newState
                
                // Update the database
                NodeManager().setNode(selectedClientId, lost: newState)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)



            
            // ======================= Show DATABASE =======================
            
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
            let nodes = Dictionary(uniqueKeysWithValues: NodeManager().fetchAllNodes().map { ($0.id, $0) })

            if showRSSILogs {
                List(displayedLogs, id: \.timestamp) { log in
                    HStack {
                        let sourceNode = NodeManager().findNode(byId: log.sourceNodeId)
                        let targetNode = NodeManager().findNode(byId: log.targetNodeId)
               
                        Text("Source: \(nodeName(for: log.sourceNodeId))")
                        Text("Target: \(nodeName(for: log.targetNodeId))")
                        Text("RSSI: \(log.rssiValue) dBm")
                        Text("Source Lost: \(sourceNode?.isLost == true ? "Yes" : "No")")
                        Text("Target Lost: \(targetNode?.isLost == true ? "Yes" : "No")")
              
                        Spacer()
                        if let timestamp = log.timestamp {
                            Text(timestamp.formatted(date: .numeric, time: .standard))
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
                .frame(minHeight: 300, maxHeight: .infinity) // flexible height
            }

        }
        .padding()
    }
}


#Preview {
    ContentView()
}
