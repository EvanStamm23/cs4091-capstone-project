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
    
    var body: some View {
        VStack {
            // App logo at the top
            Image("Image")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100) // adjust size

            Text("LoRa BLE Messages")
                .font(.headline)
            List(bleManager.messages, id: \.self) { message in
                Text(message)
            }
        }
        .padding()
    }
}


#Preview {
    ContentView()
}
