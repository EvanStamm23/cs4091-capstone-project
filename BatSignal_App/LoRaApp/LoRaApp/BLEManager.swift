//
//  BLEManager.swift
//  LoRaApp
//
//  Created by admin on 11/8/25.
//
// Handles all BLE logic (scan, connect, notifications

import Foundation
import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    
    @Published var messages: [String] = []
    @Published var latestRSSI: Int = -100
    @Published var connectedDeviceName: String = "Not Connected"
    @Published var nodeRSSI: [Int64: Int] = [:] // key: sourceNodeId, value: RSSI
    @Published var lostClients: [Int64: Bool] = [:]
    
    var loRaPeripheral: CBPeripheral?
    let characteristicUUID = CBUUID(string: "ABCD1234-5678-90AB-CDEF-1234567890AB")
    let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-1234567890AB")
    
    let nodeManager = NodeManager()
    
    var rssiTimer: Timer?
    
    override init() {
        super.init()
        print("BLEManager initialized")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState called — current state: \(central.state.rawValue)")
        
        if central.state == .poweredOn {
            print("BLE powered on. Scanning...")
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        } else {
            print("BLE not available")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        loRaPeripheral = peripheral
        loRaPeripheral!.delegate = self
        centralManager.stopScan()
        centralManager.connect(loRaPeripheral!)
        print("Connecting to LoRa device...")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to LoRa device!")
        DispatchQueue.main.async {
            self.connectedDeviceName = peripheral.name ?? "Unknown Device"
        }
        peripheral.discoverServices(nil)
        
        // start reading rssi every 1 second
        startRSSIUpdates()
    }
    
    // Called when device disconnects
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from device")
        stopRSSIUpdates()
        DispatchQueue.main.async {
            self.connectedDeviceName = "Not Connected"
        }
    }
    
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == CBUUID(string: "12345678-1234-1234-1234-1234567890AB") {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == characteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                print("Subscribed to notifications for LoRa messages!")
            }
        }
    }

    func parseLoRaMessage(_ message: String) -> (source: Int64, target: Int64, rssi: Int64)? {
        // Example: "RSSI,source=1,target=2,value=-70"
        let parts = message.components(separatedBy: ",")
        guard parts.count == 4 else { return nil }
        let source = Int64(parts[1].split(separator: "=")[1]) ?? 0
        let target = Int64(parts[2].split(separator: "=")[1]) ?? 0
        let rssi = Int64(parts[3].split(separator: "=")[1]) ?? 0
        return (source, target, rssi)
    }

    
    // rssi callback - save to db
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            print("Error reading RSSI: \(error!.localizedDescription)")
            return
        }
        
        let rssiValue = RSSI.int64Value
        
        DispatchQueue.main.async {
            self.latestRSSI = RSSI.intValue
            print("RSSI updated: \(self.latestRSSI)")
            
            // ✅ Save to database
            // Use nodeId: 1 for now, or extract from peripheral identifier
            self.nodeManager.saveRSSIFromBLE(sourceId: 1, targetId: -1, rssiValue: rssiValue)
            print("✅ Saved RSSI \(rssiValue) to database")
        }
    }
    
    // Start periodic RSSI readings
    func startRSSIUpdates() {
        print("Starting RSSI updates...")
        rssiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.loRaPeripheral?.readRSSI()
        }
    }
    
    // Stop RSSI readings
    func stopRSSIUpdates() {
        print("Stopping RSSI updates...")
        rssiTimer?.invalidate()
        rssiTimer = nil
    }
    
    // Cleanup when object is destroyed
    deinit {
        stopRSSIUpdates()
    }
    
    // ========== NOTIFICATION LOGIC ===================
    // Assmuning receiving message from LoRa:
    // {"clientId": "0xB1", "lost": true}
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {

        guard let data = characteristic.value,
              let message = String(data: data, encoding: .utf8) else { return }

        print("Received message: \(message)")

        DispatchQueue.main.async {
            self.messages.append(message)
        }

        // ---- JSON PARSING ----
        if let jsonData = message.data(using: .utf8) {
            do {
                let loRa = try JSONDecoder().decode(LoRaMessage.self, from: jsonData)

                // Update RSSI map
                DispatchQueue.main.async {
                    self.nodeRSSI[loRa.source] = Int(loRa.rssi)
                    self.lostClients[loRa.source] = loRa.isLost
                }

                // Save to DB
                nodeManager.setNode(loRa.source, lost: loRa.isLost)
                nodeManager.createRSSILog(
                    sourceId: loRa.source,
                    targetId: loRa.target,
                    rssiValue: loRa.rssi
                )

            } catch {
                print("JSON decode failed: \(error)")
            }
        }
    }
}
