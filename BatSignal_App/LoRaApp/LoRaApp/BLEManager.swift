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

    var loRaPeripheral: CBPeripheral?
    let characteristicUUID = CBUUID(string: "ABCD1234-5678-90AB-CDEF-1234567890AB")
    let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-1234567890AB")

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
        if peripheral.name == "LoRaBLENode" {
            loRaPeripheral = peripheral
            loRaPeripheral!.delegate = self
            centralManager.stopScan()
            centralManager.connect(loRaPeripheral!)
            print("Connecting to LoRa device...")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to LoRa device!")
        peripheral.discoverServices(nil)
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
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value, let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.messages.append(message)
                print("Received message: \(message)")
            }
        }
    }
    
    // for RSSI
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        DispatchQueue.main.async {
            self.latestRSSI = RSSI.intValue
            print("RSSI updated: \(self.latestRSSI)")
        }
    }

}

