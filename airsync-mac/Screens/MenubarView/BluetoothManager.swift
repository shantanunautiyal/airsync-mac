//
//  BluetoothManager.swift
//  BLEJsonTransport
//
//  Created 2025-10-02.
//

import Foundation
import CoreBluetooth
internal import Combine

// MARK: - BLE UUIDs (PLACEHOLDERS - must be matched by Android counterpart)
enum BLEUUIDs {
    // Custom Service UUID
    static let serviceUUID = CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455")
    
    // RX Characteristic (Write from iOS to Android)
    static let rxCharacteristicUUID = CBUUID(string: "49535343-1E4D-4BD9-BA61-23C647249616")
    
    // TX Characteristic (Notify from Android to iOS)
    static let txCharacteristicUUID = CBUUID(string: "49535343-8841-43F4-A8D4-ECBE34729BB3")
}

// MARK: - BluetoothManager

final class BluetoothManager: NSObject, ObservableObject {
    
    static let shared = BluetoothManager()
    
    // MARK: - Published properties
    
    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var connectedDeviceName: String? = nil
    
    // MARK: - Private properties
    
    private var centralManager: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral?
    
    private var rxCharacteristic: CBCharacteristic?
    private var txCharacteristic: CBCharacteristic?
    
    private let mtu = 180 // Max chunk size in bytes for JSON message parts
    
    // Buffer for incoming fragmented messages keyed by peripheral identifier
    private var incomingBuffers: [UUID: IncomingBuffer] = [:]
    
    // Serial queue to protect access to incomingBuffers from multiple threads
    private let bufferAccessQueue = DispatchQueue(label: "com.airsync.ble-buffer-access")
    
    // MARK: - Init
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public API
    
    /// Enable or disable Bluetooth management (auto scan/connect)
    func enable(_ enabled: Bool) {
        DispatchQueue.main.async {
            self.isEnabled = enabled
        }
        if enabled {
            startScanning()
        } else {
            stopScanning()
            disconnectCurrentPeripheral()
        }
    }
    
    /// Start scanning for peripherals matching criteria
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        
        if centralManager.isScanning { return }
        
        // Scan only for our custom service to reduce noise
        centralManager.scanForPeripherals(withServices: [BLEUUIDs.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    /// Stop scanning for peripherals
    func stopScanning() {
        if centralManager.isScanning {
            centralManager.stopScan()
        }
    }
    
    /// Send a UTF-8 string message to the connected peripheral over RX characteristic (write)
    /// If message is larger than mtu, it will be split into chunks with simple header PART i/n\n
    func send(_ text: String) {
        guard let peripheral = discoveredPeripheral,
              let rxChar = rxCharacteristic,
              peripheral.state == .connected else {
            return
        }
        
        guard let data = text.data(using: .utf8) else {
            return
        }
        
        let maxPayloadSize = mtu - 10 // ~10 bytes reserved for header "PART i/n\n"
        
        if data.count <= maxPayloadSize {
            // Single chunk, send as is
            peripheral.writeValue(data, for: rxChar, type: .withResponse)
        } else {
            // Split into chunks with basic header
            let totalChunks = Int(ceil(Double(data.count) / Double(maxPayloadSize)))
            for i in 0..<totalChunks {
                let chunkStart = i * maxPayloadSize
                let chunkEnd = min((i + 1) * maxPayloadSize, data.count)
                let chunkData = data.subdata(in: chunkStart..<chunkEnd)
                
                let header = "PART \(i+1)/\(totalChunks)\n"
                guard let headerData = header.data(using: .utf8) else { continue }
                
                var chunkToSend = Data()
                chunkToSend.append(headerData)
                chunkToSend.append(chunkData)
                
                peripheral.writeValue(chunkToSend, for: rxChar, type: .withResponse)
            }
        }
    }
    
    // MARK: - Private helpers
    
    private func disconnectCurrentPeripheral() {
        if let peripheral = discoveredPeripheral, peripheral.state == .connected {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedDeviceName = nil
            self.rxCharacteristic = nil
            self.txCharacteristic = nil
            self.discoveredPeripheral = nil
        }
    }
    
    private func connect(to peripheral: CBPeripheral) {
        if discoveredPeripheral != peripheral {
            disconnectCurrentPeripheral()
        }
        discoveredPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    /// Check if peripheral name matches last connected device or looks like Android device
    private func isPreferredPeripheral(_ peripheral: CBPeripheral) -> Bool {
        let name = peripheral.name ?? ""
        
        // Check last connected device name from AppState.shared.device?.name
        if let lastName = AppState.shared.device?.name, !lastName.isEmpty {
            if name == lastName {
                return true
            }
        }
        
        // Heuristic: Android device names often contain "Android" or "Pixel" or "Samsung"
        let androidNamePatterns = ["android", "pixel", "samsung", "oneplus", "huawei"]
        let lowerName = name.lowercased()
        for pattern in androidNamePatterns {
            if lowerName.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Incoming message assembly
    
    private struct IncomingBuffer {
        var totalParts: Int = 1
        var receivedParts: Int = 0
        var partsData: [Int: Data] = [:]
        
        mutating func appendPart(index: Int, total: Int, data: Data) {
            if totalParts != total {
                totalParts = total
            }
            if partsData[index] == nil {
                partsData[index] = data
                receivedParts += 1
            }
        }
        
        var isComplete: Bool {
            return receivedParts == totalParts
        }
        
        var assembledData: Data? {
            guard isComplete else { return nil }
            var result = Data()
            for i in 1...totalParts {
                if let d = partsData[i] {
                    result.append(d)
                } else {
                    return nil
                }
            }
            return result
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.isEnabled = (central.state == .poweredOn)
        }
        if central.state == .poweredOn, isEnabled {
            startScanning()
        } else {
            stopScanning()
            disconnectCurrentPeripheral()
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        guard isEnabled else { return }
        
        if isPreferredPeripheral(peripheral) {
            connect(to: peripheral)
            stopScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            // Do NOT disconnect existing WebSocket session — allow multiple simultaneous connections
            if AppState.shared.device != nil {
                print("[ble-manager] BLE connected while a primary device exists — keeping existing WebSocket session and attaching BLE as a secondary transport.")
            }
            
            // Only set the global device if none exists; otherwise, keep the current primary device
            if AppState.shared.device == nil {
                if let name = peripheral.name {
                    let bleDevice = Device(name: name, ipAddress: "BLE", port: 0, version: "BLE")
                    AppState.shared.device = bleDevice
                    print("[ble-manager] Established new primary device session for \(name) via BLE.")
                } else {
                    print("[ble-manager] Warning: Connected to a peripheral with no name.")
                }
            } else {
                // Secondary connection present; future work: assign to AppState.secondaryDevice when available
                if let name = peripheral.name {
                    print("[ble-manager] Established secondary BLE connection: \(name)")
                }
            }
            self.isConnected = true
            self.connectedDeviceName = peripheral.name
        }
        peripheral.discoverServices([BLEUUIDs.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedDeviceName = nil
        }
        discoveredPeripheral = nil
        rxCharacteristic = nil
        txCharacteristic = nil
        if isEnabled {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            // If the disconnected peripheral was our main device, clear the global app state.
            // This is crucial to prevent other parts of the app from trying to use a stale connection.
            if AppState.shared.device?.ipAddress == "BLE" {
                print("[ble-manager] Main BLE device disconnected, resetting app state.")
                AppState.shared.device = nil
                AppState.shared.status = nil
            }
            
            self.isConnected = false
            self.connectedDeviceName = nil
            self.rxCharacteristic = nil
            self.txCharacteristic = nil
        }
        discoveredPeripheral = nil
        if isEnabled {
            startScanning()
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services where service.uuid == BLEUUIDs.serviceUUID {
            peripheral.discoverCharacteristics([BLEUUIDs.rxCharacteristicUUID, BLEUUIDs.txCharacteristicUUID], for: service)
            break
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard error == nil else {
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
            case BLEUUIDs.rxCharacteristicUUID:
                rxCharacteristic = characteristic
            case BLEUUIDs.txCharacteristicUUID:
                txCharacteristic = characteristic
                // Subscribe to notifications on TX
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                break
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        // No special action needed
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil else {
            print("[ble-manager] Error updating value for characteristic: \(error?.localizedDescription ?? "idk")")
            return
        }
        
        guard characteristic.uuid == BLEUUIDs.txCharacteristicUUID,
              let data = characteristic.value else { return }
        
        // Parse incoming data for multipart or single part messages
        
        // Incoming data format:
        // If multipart: "PART i/n\n" header followed by chunk data
        // If single part: just the raw JSON UTF8 string
        
        var messageData: Data
        var partIndex = 1
        var totalParts = 1
        
        // Find the first newline character to separate header and body
        if let newlineRange = data.range(of: "\n".data(using: .utf8)!) {
            let headerData = data.subdata(in: 0..<newlineRange.lowerBound)
            
            if let headerString = String(data: headerData, encoding: .utf8), headerString.hasPrefix("PART ") {
                // This is a multipart message
                messageData = data.suffix(from: newlineRange.upperBound)
                
                // Parse header "PART i/n"
                let parts = headerString.components(separatedBy: " ")
                if parts.count == 2 {
                    let indexes = parts[1].split(separator: "/")
                    if indexes.count == 2,
                       let i = Int(indexes[0]),
                       let n = Int(indexes[1]) {
                        partIndex = i
                        totalParts = n
                    }
                }
            } else {
                // Newline found, but not a "PART" header. Treat as single message.
                messageData = data
            }
        } else {
            // Single part message
            messageData = data
            partIndex = 1
            totalParts = 1
        }
        
        // Use the serial queue to safely access the buffer
        bufferAccessQueue.async {
            // Append to incoming buffer
            var buffer = self.incomingBuffers[peripheral.identifier] ?? IncomingBuffer()
            buffer.appendPart(index: partIndex, total: totalParts, data: messageData)
            self.incomingBuffers[peripheral.identifier] = buffer
            
            // If complete, assemble and deliver
            if buffer.isComplete, let assembled = buffer.assembledData,
               let messageString = String(data: assembled, encoding: .utf8) {
                self.incomingBuffers[peripheral.identifier] = nil
                
                DispatchQueue.main.async {
                    // If a device is connected via WebSocket, handle the message.
                    if AppState.shared.device != nil {
                        WebSocketServer.shared.handleRawBluetoothMessage(messageString)
                    } else {
                        print("BluetoothManager received message: \(messageString)")
                    }
                }
            }
        }
    }
}

