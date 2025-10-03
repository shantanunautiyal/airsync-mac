import SwiftUI
internal import Combine
import CoreBluetooth

struct DiscoveredPeripheral: Identifiable, Hashable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String
    let rssi: Int
    let info: String?

    static func == (lhs: DiscoveredPeripheral, rhs: DiscoveredPeripheral) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class HealthDataManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = HealthDataManager()

    @Published var isScanning = false
    @Published var connectedWatch: CBPeripheral?
    @Published var healthData: HealthData = HealthData()
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var discoveredPeripherals: [DiscoveredPeripheral] = []
    @Published var keepScanning: Bool = false
    @Published var verboseLogging: Bool = false
    @Published var authorization: CBManagerAuthorization = CBCentralManager.authorization
    @Published var watchesOnlyFilter: Bool = true

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var scanTimer: Timer?
    private let lastConnectedWatchKey = "lastConnectedWatchID"

    // Service and Characteristic UUIDs for health data
    private let healthServiceUUID = CBUUID(string: "0000180D-0000-1000-8000-00805F9B34FB") // Heart Rate Service
    private let heartRateCharUUID = CBUUID(string: "00002A37-0000-1000-8000-00805F9B34FB") // Heart Rate Measurement

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)

        if let savedIdString = UserDefaults.standard.string(forKey: lastConnectedWatchKey), let _ = UUID(uuidString: savedIdString) {
            // Attempt retrieval when manager powers on in centralManagerDidUpdateState
            // Store UUID for later use
            // No immediate action needed here
        }
    }

    // MARK: - Public Methods

    func startScanning() {
        guard bluetoothState == .poweredOn else { return }
        // Keep previous discoveries so system-connected devices stay visible while scanning
        isScanning = true

        // Scan broadly (don't only rely on advertised Heart Rate service because some watches
        // may not advertise it directly). Use nil to scan for any peripheral and filter in code.
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])

        // Stop scanning automatically after a timeout to avoid infinite scanning loops unless keepScanning is true
        invalidateScanTimer()
        if !keepScanning {
            scanTimer = Timer.scheduledTimer(withTimeInterval: 12.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if self.isScanning { self.stopScanning() }
            }
        }
    }

    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
        invalidateScanTimer()
    }

    /// Check for peripherals already connected by the system that expose the health service.
    func checkForConnectedWatches() {
        guard bluetoothState == .poweredOn else { return }
        // Try retrieving peripherals connected by the system for relevant services so they appear in the list
        let serviceUUIDsToCheck: [CBUUID] = [healthServiceUUID,
                                             CBUUID(string: "0000180F-0000-1000-8000-00805F9B34FB"), // Battery Service
                                             CBUUID(string: "0000180A-0000-1000-8000-00805F9B34FB"), // Device Information
                                             CBUUID(string: "00001800-0000-1000-8000-00805F9B34FB")] // Generic Access

        var allConnected: [CBPeripheral] = []
        for s in serviceUUIDsToCheck {
            let connected = centralManager.retrieveConnectedPeripherals(withServices: [s])
            for p in connected where !allConnected.contains(where: { $0.identifier == p.identifier }) {
                allConnected.append(p)
            }
        }

        if let savedIdString = UserDefaults.standard.string(forKey: lastConnectedWatchKey), let uuid = UUID(uuidString: savedIdString) {
            let retrieved = centralManager.retrievePeripherals(withIdentifiers: [uuid])
            for p in retrieved where !allConnected.contains(where: { $0.identifier == p.identifier }) {
                allConnected.append(p)
            }
        }

        for p in allConnected {
            // Add to discovered list if not already present, mark info as system-connected
            let id = p.identifier
            let name = p.name ?? "Connected Device"
            let discovered = DiscoveredPeripheral(id: id, peripheral: p, name: name, rssi: 0, info: "system-connected")
            DispatchQueue.main.async {
                if !self.discoveredPeripherals.contains(where: { $0.id == discovered.id }) {
                    self.discoveredPeripherals.append(discovered)
                }
                // If nothing else is connected, set the first connected device as connectedWatch
                if self.connectedWatch == nil {
                    self.connectedWatch = p
                    self.peripheral = p
                    p.delegate = self
                    p.discoverServices(nil)
                }
            }
        }
    }

    private func invalidateScanTimer() {
        scanTimer?.invalidate()
        scanTimer = nil
    }

    func connect(to peripheral: CBPeripheral) {
        // store and connect
        self.peripheral = peripheral
        // If the peripheral is already connected at the system level, attach delegates and discover services
        if peripheral.state == .connected {
            DispatchQueue.main.async {
                self.connectedWatch = peripheral
                UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: self.lastConnectedWatchKey)
            }
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        } else {
            centralManager.connect(peripheral, options: nil)
        }
    }

    func disconnect() {
        // Attempt to cancel connection if we own it
        if let p = peripheral {
            // Stop receiving callbacks from this peripheral
            p.delegate = nil
            if p.state == .connected || p.state == .connecting {
                centralManager.cancelPeripheralConnection(p)
            }
        }

        // Immediately clear local state so UI updates right away, regardless of CB callbacks
        DispatchQueue.main.async {
            self.connectedWatch = nil
            self.peripheral = nil
            self.healthData = HealthData() // reset metrics
            UserDefaults.standard.removeObject(forKey: self.lastConnectedWatchKey)
        }
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        authorization = CBCentralManager.authorization
        if central.state == .poweredOn {
            checkForConnectedWatches()
            if let savedIdString = UserDefaults.standard.string(forKey: lastConnectedWatchKey), let uuid = UUID(uuidString: savedIdString) {
                let retrieved = central.retrievePeripherals(withIdentifiers: [uuid])
                for p in retrieved {
                    let id = p.identifier
                    let name = p.name ?? "Connected Device"
                    let discovered = DiscoveredPeripheral(id: id, peripheral: p, name: name, rssi: 0, info: "system-connected")
                    DispatchQueue.main.async {
                        if !self.discoveredPeripherals.contains(where: { $0.id == discovered.id }) {
                            self.discoveredPeripherals.append(discovered)
                        }
                    }
                }
            }
        } else {
            // When not powered on, stop scanning
            stopScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Detect vendor from manufacturer data company ID (first 2 bytes little-endian)
        var vendorHint: String? = nil
        if let mData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, mData.count >= 2 {
            let companyId = UInt16(mData[1]) << 8 | UInt16(mData[0])
            switch companyId {
            case 0x004C: vendorHint = "Apple"
            case 0x0075: vendorHint = "Samsung"
            case 0x0131: vendorHint = "Xiaomi"
            case 0x00E0: vendorHint = "Garmin"
            default: break
            }
        }

        // Build a friendly info string from advertisement data for diagnostics
        var infoParts: [String] = []
        if let vendor = vendorHint { infoParts.append("vendor:\(vendor)") }
        if let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String { infoParts.append("name:\(advName)") }
        if let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            let s = services.map { $0.uuidString }.joined(separator: ",")
            infoParts.append("services:\(s)")
        }
        if let mData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            infoParts.append("mfg:")
            infoParts.append(mData.map { String(format: "%02x", $0) }.joined())
        }

        let info = infoParts.isEmpty ? nil : infoParts.joined(separator: " ")

        // Get a friendly name from advertisement or peripheral
        let nameFromAdv = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)

        // Try to decode manufacturer data as printable UTF-8 string if present
        var manufacturerString: String? = nil
        if let mData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            // Try extracting printable ASCII or UTF-8/UTF-16LE substrings from manufacturer payload
            manufacturerString = cleanedManufacturerString(from: mData)
        }

        // Derive a friendly display name using advertisement, peripheral name, and cleaned manufacturer string
        var name = nameFromAdv ?? peripheral.name

        if (name == nil || name?.isEmpty == true), let m = manufacturerString, !m.isEmpty {
            // Prefer manufacturer / model strings when they look human-readable
            name = titleCasedName(from: m)
        }

        // Fall back to a service-based hint if available (e.g., Heart Rate Service)
        if name == nil || name?.isEmpty == true {
            if let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID], services.contains(healthServiceUUID) {
                name = "Heart Rate Monitor"
            }
        }

        // Final fallback: friendly unknown label with RSSI to help identification
        if name == nil || name?.isEmpty == true {
            name = "Unknown Watch (RSSI: \(RSSI.intValue))"
        }

        let discovered = DiscoveredPeripheral(id: peripheral.identifier, peripheral: peripheral, name: name ?? "Unknown", rssi: RSSI.intValue, info: info)

        DispatchQueue.main.async {
            if let idx = self.discoveredPeripherals.firstIndex(where: { $0.id == discovered.id }) {
                // Update RSSI, name, and info if they changed
                var current = self.discoveredPeripherals[idx]
                let newName = discovered.name
                let newInfo = discovered.info
                let newRSSI = discovered.rssi
                var changed = false
                if current.name != newName { current = DiscoveredPeripheral(id: current.id, peripheral: current.peripheral, name: newName, rssi: current.rssi, info: current.info); changed = true }
                if current.info != newInfo { current = DiscoveredPeripheral(id: current.id, peripheral: current.peripheral, name: current.name, rssi: current.rssi, info: newInfo); changed = true }
                if current.rssi != newRSSI { current = DiscoveredPeripheral(id: current.id, peripheral: current.peripheral, name: current.name, rssi: newRSSI, info: current.info); changed = true }
                if changed { self.discoveredPeripherals[idx] = current }
            } else {
                self.discoveredPeripherals.append(discovered)
            }
        }

        if verboseLogging {
            print("[BLE] Discovered: id=\(peripheral.identifier) name=\(name ?? "") rssi=\(RSSI.intValue)")
            print("[BLE] Advertisement: \(advertisementData)")
            if let mData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                print("[BLE] Manufacturer Hex: \(mData.map { String(format: "%02x", $0) }.joined())")
                if let cleaned = manufacturerString { print("[BLE] Manufacturer (clean): \(cleaned)") }
            }
        }

        // Do not auto-connect immediately; allow user to pick from the UI. If desired, auto-connect
        // only when the peripheral name matches a strict supported list (optional).
        if self.isSupportedWatch(peripheral, advertisementData: advertisementData) && self.connectedWatch == nil {
            // Do not auto-connect here — prefer user action. Keep this code commented for now.
            // self.peripheral = peripheral
            // central.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScanning()
        DispatchQueue.main.async {
            self.connectedWatch = peripheral
            UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: self.lastConnectedWatchKey)
        }
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        if verboseLogging {
            print("[BLE] Connected to \(peripheral.identifier) (name: \(peripheral.name ?? "unknown"))")
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if connectedWatch?.identifier == peripheral.identifier {
            DispatchQueue.main.async {
                self.connectedWatch = nil
                UserDefaults.standard.removeObject(forKey: self.lastConnectedWatchKey)
            }
        }
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error, verboseLogging {
            print("[BLE] didDiscoverServices error: \(error.localizedDescription)")
        }

        // If services are not yet available, retry shortly
        guard let services = peripheral.services else {
            if verboseLogging { print("[BLE] didDiscoverServices: services=nil, retrying in 0.5s") }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                peripheral.discoverServices(nil)
            }
            return
        }

        if services.isEmpty {
            if verboseLogging { print("[BLE] didDiscoverServices: empty list, retrying in 0.5s") }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                peripheral.discoverServices(nil)
            }
            return
        }

        if verboseLogging {
            print("[BLE] didDiscoverServices for \(peripheral.identifier): \(services.map { $0.uuid.uuidString })")
        }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        if verboseLogging {
            print("[BLE] didDiscoverCharacteristics for service \(service.uuid.uuidString): \(characteristics.map { $0.uuid.uuidString })")
        }

        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            peripheral.readValue(for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            if verboseLogging {
                print("[BLE] Error reading characteristic: \(error.localizedDescription)")
            }
            return
        }

        switch characteristic.uuid {
        case heartRateCharUUID:
            if let value = characteristic.value {
                let hr = parseHeartRate(from: value)
                healthData.heartRate = hr
                if verboseLogging {
                    print("[BLE] HeartRate notification raw=\(value.map { String(format: "%02x", $0) }.joined()) parsed=\(hr)")
                }
            }
        default:
            if verboseLogging {
                if let v = characteristic.value {
                    print("[BLE] Characteristic \(characteristic.uuid.uuidString) update value=\(v.map { String(format: "%02x", $0) }.joined())")
                } else {
                    print("[BLE] Characteristic \(characteristic.uuid.uuidString) update nil value")
                }
            }
        }
    }

    // Attempt to extract a human readable string from manufacturer data by trying printable ASCII,
    // then UTF-8, then UTF-16LE, and finally stripping non-printable characters.
    private func cleanedManufacturerString(from data: Data) -> String? {
        // Try printable ASCII extraction first
        let asciiChars = data.compactMap { (byte) -> Character? in
            if byte >= 0x20 && byte <= 0x7E {
                return Character(UnicodeScalar(byte))
            }
            return nil
        }
        if !asciiChars.isEmpty {
            return String(asciiChars)
        }

        // Try UTF-8
        if let s = String(data: data, encoding: .utf8), !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return s.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Try UTF-16 Little Endian
        if let s = String(data: data, encoding: .utf16LittleEndian), !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return s.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Fallback: remove non-printable bytes and return result if any
        let cleaned = data.compactMap { (byte) -> Character? in
            if byte >= 0x20 && byte <= 0x7E {
                return Character(UnicodeScalar(byte))
            }
            return nil
        }
        if !cleaned.isEmpty { return String(cleaned) }

        return nil
    }

    private func titleCasedName(from raw: String) -> String {
        // Quick title-case and small normalizations (e.g., cmf -> CMF)
        let parts = raw.split { !$0.isLetter && !$0.isNumber }
        if parts.isEmpty { return raw }
        let title = parts.map { part -> String in
            let s = String(part)
            if s.lowercased() == "cmf" { return "CMF" }
            return s.capitalized
        }.joined(separator: " ")
        return title
    }

    // MARK: - Helper Methods

    private func isSupportedWatch(_ peripheral: CBPeripheral, advertisementData: [String: Any]?) -> Bool {
        // Prefer advertised/local name first
        if let advName = advertisementData?[CBAdvertisementDataLocalNameKey] as? String, !advName.isEmpty {
            let low = advName.lowercased()
            if low.contains("watch") || low.contains("cmf") || low.contains("mi band") || low.contains("honor") || low.contains("fitbit") || low.contains("garmin") || low.contains("band") { return true }
        }

        // Fallback to peripheral name
        if let pName = peripheral.name?.lowercased(), !pName.isEmpty {
            if pName.contains("watch") || pName.contains("cmf") || pName.contains("mi band") || pName.contains("honor") || pName.contains("fitbit") || pName.contains("garmin") || pName.contains("band") { return true }
        }

        // Inspect service UUIDs for Heart Rate service
        if let services = advertisementData?[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            if services.contains(healthServiceUUID) { return true }
        }

        // Inspect manufacturer data for vendor IDs or textual hints
        if let mData = advertisementData?[CBAdvertisementDataManufacturerDataKey] as? Data {
            // Many vendors include recognizable ASCII in manufacturer payloads; look for ascii substrings
            if let ascii = String(data: mData, encoding: .utf8), ascii.lowercased().contains("cmf") { return true }
        }

        return false
    }

    private func parseHeartRate(from data: Data) -> Int {
        // Parse heart rate data according to Bluetooth GATT specification
        guard data.count >= 2 else { return 0 }
        let firstByte = data[0]
        let format = firstByte & 0x01

        if format == 0 {
            return Int(data[1])
        } else {
            return Int(data[1]) | (Int(data[2]) << 8)
        }
    }
}

struct HealthData {
    var heartRate: Int = 0
    var steps: Int = 0
    var calories: Int = 0
    var distance: Double = 0.0 // in kilometers
    var sleepHours: Double = 0.0
}

