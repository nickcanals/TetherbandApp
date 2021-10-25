//
//  BLEManager.swift
//  Tether
//
//  Created by Eric Hull on 9/21/21.
//

import Foundation
import CoreBluetooth
import UserNotifications

struct Peripheral: Identifiable{
    let id: Int
    let deviceName: String
    let rssi: Int
    let manufData: Int
    let debug: String
    let originalReference: CBPeripheral
    let identifyUUID: [CBUUID] // for storing each tetherband's unique identify uuid value
    var UUIDS: TetherbandUUIDS //
    var characteristicHandles = TetherbandCharHandles() // handles used to read/write to characteristics
    var braceletInfo = TetherbandInfo()
    
    func setPeripheralDelegate(delegate: CBPeripheralDelegate){
        originalReference.delegate = delegate
    }
}

class TetherbandInfo{
    var rssiArr: [Int]
    var kidName: String
    var batteryLevel: Int
    var braceletOn: Bool
    var txPower: Int8
   // var distanceUpdateDone: Bool
    var inRange: Bool
    var currentDistanceText: String
    var currentDistanceNum: Double
    var sampleRssiTimer: DispatchSourceTimer?
    var stopSamplingTimer: DispatchSourceTimer?
    var refreshDistanceTimer: DispatchSourceTimer?
    
    
    init(){
        self.rssiArr = []
        self.batteryLevel = 100
        self.braceletOn = false
        self.txPower = 0
      //  self.distanceUpdateDone = true
        self.inRange = true
        self.currentDistanceText = ""
        self.currentDistanceNum = 0.0
        self.kidName = ""
    }
}


class TetherbandCharHandles{ // Container to hold the handles for all characteristics
    var identifyWriteChar: CBCharacteristic! // for writing emergency alert values
    var batteryNotifyChar: CBCharacteristic! // to receive battery level notifications
    var txPowerReadChar: CBCharacteristic! // for distance determination
    var immediateAlertWriteChar: CBCharacteristic! // to write alerts for distance determination
    var linkLossReadWriteChar: CBCharacteristic! // for link loss service
}

class TetherbandUUIDS{
    let immediateAlertService = CBUUID(string: "1802")
    let txPowerService = CBUUID(string: "1804")
    let linkLossService = CBUUID(string: "1803")
    let batteryLevelService = CBUUID(string: "180F")
    var identifyService: CBUUID
    
    let batteryLevelChar = CBUUID(string: "2A19")
    let alertChar = CBUUID(string: "2A06") // used by both link loss and immediate alert service
    let txPowerChar = CBUUID(string: "2A07")
    var identifyChar: CBUUID?
    
    init(identify: CBUUID){
        self.identifyService = identify
    }
    
    func getAllServices() -> [CBUUID]{
        let allServices: [CBUUID] = [immediateAlertService, txPowerService, linkLossService, batteryLevelService, identifyService]
        return allServices
    }
}


class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate, UNUserNotificationCenterDelegate {
    var localCentral: CBCentralManager!
    @Published var isOn = false
    @Published var connectedPeripherals = [Peripheral]()
    @Published var batteryLevelUpdated: [Bool] = [false]
    @Published var trackingStarted: [Bool] = [false]
    @Published var backgroundFlag = false // content view flips this to true when the user switches to another app or locks their phone. Allows distance to keep tracking in background
    
    var scanAndConnectFlag = false
    var currentIdentifyUUID: String! // unique UUID value read from the NFC tag
    var includedServices: TetherbandUUIDS?
    let NUM_RSSI_SAMPLES = 20 // num of rssi samples to take before averaging.
    let MAX_DISTANCE: Double = 3000 // given in mm. aka 15m.
    
    let distanceQueue = DispatchQueue(label: "com.tetherband.distance", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .workItem)
    
    var logFilePath: Logger? // logging
    var log: LoggerFuncs = LoggerFuncs(date: true) // used to add date time stamp to prints written to file on phone.
    
    init(logger:Logger){
        super.init()
        localCentral = CBCentralManager(delegate: self, queue: nil)
        localCentral.delegate = self
        logFilePath = logger
    }
    
    // required to implement this function to use bluetooth. Checks that bluetooth is enabled on the device.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn{
            isOn = true
        }
        else{
            isOn = false
        }
    }
    
    // function that gets called everytime the phone sees an advertisement packet
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var peripheralName: String!
        let peripheralManufDataList = advertisementData[CBAdvertisementDataManufacturerDataKey].customMirror
        var peripheralManufData: String
        var manufDataInt: Int
        
        if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Int{
            manufDataInt = data
        }
        else{
            manufDataInt = 0
        }
        
        peripheralManufData = convertMirror(mirror: peripheralManufDataList)
        
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String{
            peripheralName = name
        }
        else{
            peripheralName = "Unknown"
        }
        
        let newPeripheralUUIDS = TetherbandUUIDS(identify: CBUUID.init(string: currentIdentifyUUID))
        
        let newPeripheral = Peripheral(id: connectedPeripherals.count, deviceName: peripheralName, rssi: RSSI.intValue, manufData: manufDataInt, debug: peripheralManufData, originalReference: peripheral, identifyUUID: [newPeripheralUUIDS.identifyService], UUIDS: newPeripheralUUIDS)
        newPeripheral.setPeripheralDelegate(delegate: self)
        
        // Set up timer for getting distance values
        //newPeripheral.setDistanceTimer(queue: distanceQueue)
        print(newPeripheral)
        connectedPeripherals.append(newPeripheral)
        
        localCentral.connect(peripheral, options: nil)
    }
    
    // Saves reference to connected peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print(log.addDate(message: "Connected Successfully to device: \(connectedPeripherals[connectedPeripherals.endIndex-1].deviceName)!"), to: &logFilePath!)
        let tetherServices = connectedPeripherals[connectedPeripherals.endIndex-1].UUIDS.getAllServices()
        if connectedPeripherals.count > 1{
            batteryLevelUpdated.append(false)
            trackingStarted.append(false)// increase the size of flag array by one
        }
        peripheral.discoverServices(tetherServices)
        print(log.addDate(message: "All services and characteristics setup successfully"), to: &logFilePath!)
    }
    
    // error handler in case connection fails
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Couldn't connect to \(String(describing: peripheral.name))")
        connectedPeripherals.remove(at: connectedPeripherals.endIndex-1) // remove from the connected peripherals array
    }
    
    
    func scanAndConnect(){
        scanAndConnectFlag = true
        currentIdentifyUUID = "B0201F39-97BC-A2F5-4621-C9AB58C9BFCA"
        let customUUID: [CBUUID] = [CBUUID.init(string: "B0201F39-97BC-A2F5-4621-C9AB58C9BFCA")]
        localCentral.scanForPeripherals(withServices: customUUID, options: nil)
    }
    
    func scanAndConnect(read_uuid: String){
        scanAndConnectFlag = true
        currentIdentifyUUID = read_uuid
        currentIdentifyUUID.remove(at: currentIdentifyUUID.startIndex)
        let customUUID : [CBUUID] = [CBUUID.init(string: currentIdentifyUUID)]
        localCentral.scanForPeripherals(withServices: customUUID, options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if((error) != nil){
            print("Error discovering services: \(String(describing: error?.localizedDescription))")
        }
        guard let services = peripheral.services else{
            return
        }
        print("Discovered services successfully.")
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if((error) != nil){
            print("Error discovering characteristics for service: \(service.description). Error is: \(String(describing: error?.localizedDescription))")
        }
        guard let characteristics = service.characteristics else{
            return
        }
        
        let currentPeripheralIndex = connectedPeripherals[connectedPeripherals.endIndex-1].id
        let currentPeripheralServices = connectedPeripherals[currentPeripheralIndex].UUIDS.getAllServices()
        
        //immediateAlertService, txPowerService, linkLossService, batteryLevelService, identifyService
        // This switch statement sets up all the handles that are used to read/write later
        switch service.uuid{
        
        case currentPeripheralServices[0]: // immediate alert service (send distance determ. alerts)
            connectedPeripherals[currentPeripheralIndex].characteristicHandles.immediateAlertWriteChar = characteristics[0]
            print("DISCOVERED IMMEDIATE ALERT SERVICE AND CHARS")
            
        case currentPeripheralServices[1]: // tx power service (used in calculating distance determ.)
            connectedPeripherals[currentPeripheralIndex].characteristicHandles.txPowerReadChar = characteristics[0]
            peripheral.readValue(for: connectedPeripherals[currentPeripheralIndex].characteristicHandles.txPowerReadChar)
            print("DISCOVERED TX POWER SERVICE AND CHARS")
            
        case currentPeripheralServices[2]: // link loss service (distance determ)
            connectedPeripherals[currentPeripheralIndex].characteristicHandles.linkLossReadWriteChar = characteristics[0]
            print("DISCOVERED LINK LOSS SERVICE AND CHARS")
            
        case currentPeripheralServices[3]: // battery level service (notifications of battery level)
            connectedPeripherals[currentPeripheralIndex].characteristicHandles.batteryNotifyChar = characteristics[0]
            peripheral.setNotifyValue(true, for: connectedPeripherals[currentPeripheralIndex].characteristicHandles.batteryNotifyChar)
            peripheral.readValue(for: connectedPeripherals[currentPeripheralIndex].characteristicHandles.batteryNotifyChar)
            print("SUBSCRIBED TO NOTIFICATIONS FOR BATTERY SERVICE")

        case currentPeripheralServices[4]: // custom identify service (write emergency alert values)
            connectedPeripherals[currentPeripheralIndex].UUIDS.identifyChar = characteristics[0].uuid
            connectedPeripherals[currentPeripheralIndex].characteristicHandles.identifyWriteChar = characteristics[0]
            print("DISCOVERED CUSTOM IDENTIFY SERVICE AND CHARS")
            
        default:
            print("Services case statement to discover characteristics failed for service: \(service.description).")
        }
        
        /*if service.uuid.isEqual(connectedPeripherals[connectedPeripherals.endIndex].identifyUUID[0]){ // if identify service is being read
            connectedPeripherals[connectedPeripherals.endIndex].UUIDS.identifyChar = characteristics[0].uuid // set identify characteristic uuid
            connectedPeripherals[connectedPeripherals.endIndex].characteristicHandles?.identifyWriteChar = characteristics[0]
        }*/
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if((error) != nil){
            print("Error reading value for characteristic: \(characteristic.description). Error is: \(String(describing: error?.localizedDescription))")
        }
        guard let data = characteristic.value else{
            return
        }
        for connectedPeripheral in connectedPeripherals{
            if peripheral.isEqual(connectedPeripheral.originalReference){
                let connectedPeripheralIndex = connectedPeripheral.id
                guard let firstByte = data.first else{
                    print("Data sent from characteristic: \(characteristic.description) is empty!")
                    return
                }
                switch characteristic.uuid{
                
                case connectedPeripheral.UUIDS.batteryLevelChar:
                    connectedPeripheral.braceletInfo.batteryLevel = Int(firstByte)
                    print("Number read from battery level update is: \(Int(firstByte))")
                    /*if backgroundFlag{
                        peripheral.readRSSI()
                    }*/
                    batteryLevelUpdated[connectedPeripheralIndex] = true
                    
                case connectedPeripheral.UUIDS.identifyChar: // cap sense alerts here
                    if Int(firstByte) == 1{ // background distance notification
                        print("Received Background Distance Notification.")
                        peripheral.readRSSI()
                    }
                    else if Int(firstByte) == 2{
                        print("Cap Sense alert goes here")
                    }
                    
                case connectedPeripheral.UUIDS.txPowerChar:
                    let txValue = Int8(bitPattern: UInt8(firstByte)) // have to do this to read the hex as signed
                    connectedPeripheral.braceletInfo.txPower = txValue
                    print("TX power read from tx power service is: \(txValue)")
                    
                default:
                    print("Some other read event happened.")
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Did not write characteristic \(characteristic.description), error: \(error.debugDescription)")
            return
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        for currentPeripheral in connectedPeripherals{
            if peripheral.isEqual(currentPeripheral.originalReference){
                guard error == nil else{
                    print("Error reading rssi from bracelet name: \(currentPeripheral.deviceName) and id: \(currentPeripheral.identifyUUID[0].uuidString)")
                    return
                }
                if currentPeripheral.braceletInfo.rssiArr.count <= NUM_RSSI_SAMPLES{ // need more samples before averaging for distance
                        // Timer that after 50 ms stops the sampling timer running every millisecond.
                        let cancelTimer = DispatchSource.makeTimerSource(flags: .strict, queue: distanceQueue)
                        cancelTimer.schedule(deadline: .now(), repeating: .milliseconds(50), leeway: .microseconds(0))
                        cancelTimer.setEventHandler{
                            if currentPeripheral.braceletInfo.rssiArr.count > self.NUM_RSSI_SAMPLES{
                                if !(currentPeripheral.braceletInfo.sampleRssiTimer?.isCancelled ?? true){
                                    currentPeripheral.braceletInfo.sampleRssiTimer?.cancel()
                                }
                            }
                        }
                        currentPeripheral.braceletInfo.stopSamplingTimer = cancelTimer
                        currentPeripheral.braceletInfo.stopSamplingTimer?.resume()
                        
                        // Timer to trigger an RSSI read every millisecond and add it to the array
                        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: distanceQueue)
                        timer.schedule(deadline: .now(), repeating: .milliseconds(1), leeway: .microseconds(0))
                        timer.setEventHandler{
                            currentPeripheral.braceletInfo.rssiArr.append(RSSI.intValue)
                            peripheral.readRSSI()
                        }
                        currentPeripheral.braceletInfo.sampleRssiTimer = timer
                        currentPeripheral.braceletInfo.sampleRssiTimer?.resume()
                }
                else{ // have correct number of samples and are ready to average for distance
                    if backgroundFlag{
                        NSLog("IN BACKGROUND")
                    }
                    
                    currentPeripheral.braceletInfo.stopSamplingTimer?.cancel() // stop sampling timer
                    let rssiArr = currentPeripheral.braceletInfo.rssiArr
                    let txPower = currentPeripheral.braceletInfo.txPower
                    let rssi = rssiArr.reduce(0, +) / rssiArr.count
                    currentPeripheral.braceletInfo.rssiArr.removeAll() // clear the array for next set of samples
                    
                    let currentPeripheralIndex = currentPeripheral.id
                    
                    NSLog("Updating distance with RSSI and TX Values: %d, %d", rssi, txPower)
                    print(log.addDate(message: "Bracelet:\(currentPeripheral.deviceName),Updating_Distance,RSSI_is:\(rssi)"), to: &logFilePath!)
                    if updateDistance(rssi: rssi, txPower: Int(txPower), currentPeripheral: currentPeripheral){ // still in range
                        trackingStarted[currentPeripheralIndex] = true // let the UI know we have started tracking
                        // Timer to have the sampling process start again in 3 seconds.
                        let refreshTimer = DispatchSource.makeTimerSource(flags: .strict, queue: distanceQueue)
                        refreshTimer.schedule(deadline: .now() + .seconds(3), repeating: .never, leeway: .milliseconds(0))
                        refreshTimer.setEventHandler{
                            peripheral.readRSSI()
                        }
                        currentPeripheral.braceletInfo.refreshDistanceTimer = refreshTimer
                        currentPeripheral.braceletInfo.refreshDistanceTimer?.resume()
                    }
                    else{ // out of range
                        trackingStarted[currentPeripheralIndex] = true // let the UI know we have started tracking
                        create_notification(type: "Out of Range", peripheral: currentPeripheral)
                        // STILL NEED refresh distance timer, make alert repeat on an interval
                        // STILL NEED write proper alerts to the proper bracelet characteristics
                        print("In out of range block in did read rssi callback")
                    }
                }
            }
        }
    }
    
    // Function taken from Nordic Toolbox for iOS
    func updateDistance(rssi: Int, txPower: Int, currentPeripheral: Peripheral) -> Bool{
        let distance = pow(10, (Double(txPower - rssi) / 20.0))
        let distanceUnitVal = Measurement<UnitLength>(value: distance, unit: .millimeters)
        let formatter = MeasurementFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        formatter.numberFormatter = numberFormatter
        formatter.unitOptions = .naturalScale
        currentPeripheral.braceletInfo.currentDistanceText = formatter.string(from: distanceUnitVal)
        currentPeripheral.braceletInfo.currentDistanceNum = distance
        print("Formatted distance from update distance function is: \(currentPeripheral.braceletInfo.currentDistanceText)")
        
        if distance > MAX_DISTANCE{
            currentPeripheral.braceletInfo.inRange = false
            print(log.addDate(message: "Bracelet:\(currentPeripheral.deviceName),OUT_OF_RANGE,Formatted_Distance:\(currentPeripheral.braceletInfo.currentDistanceText),Raw_Distance:\(currentPeripheral.braceletInfo.currentDistanceNum)"), to: &logFilePath!)
            print("Distance of \(distance) mm determined OUT OF RANGE in update distance function")
            return false
        }
        else{
            currentPeripheral.braceletInfo.inRange = true
            print(log.addDate(message: "Bracelet:\(currentPeripheral.deviceName),IN_RANGE,Formatted_Distance:\(currentPeripheral.braceletInfo.currentDistanceText),Raw_Distance:\(currentPeripheral.braceletInfo.currentDistanceNum)"), to: &logFilePath!)
            print("Distance of \(distance) mm determined IN RANGE in update distance function")
            return true
        }
    }
    
    func create_notification(type: String, peripheral: Peripheral){
        UNUserNotificationCenter.current().delegate = self
        let content = UNMutableNotificationContent()
        switch (type){
        case "Out of Range":
            content.title = "\(peripheral.braceletInfo.kidName) is out of range! Please find them ASAP!"
            content.sound = UNNotificationSound.init(named: UNNotificationSoundName(rawValue: "hoobastank_running_away.mp3"))
        default:
            print("in default of create notification function")
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: peripheral.deviceName, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        print("notification center value is: \(UNUserNotificationCenter.current().description)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    // debug function to print out the contents of manufacturer data in advertisement packets
    func convertMirror(mirror: Mirror) -> String{ // for debugging
        var debugString = "--"
        mirror.children.forEach {
            debugString += "\n\($0.label ?? ""): \($0.value ?? "")"
        }
        debugString += "--"
        return debugString
    }
    
    /*// start scanning for devices advertising service matching custom UUID variable. This is the value that the NFC tag will send to the iphone.
    func startScan(){
        print("Starting scan")
        scanAndConnectFlag = false
        localCentral.scanForPeripherals(withServices: customUUID, options: nil)
    }
    
    // stop scanning
    func stopScan(){
        print("Stopped scan")
        localCentral.stopScan()
    }*/
}
