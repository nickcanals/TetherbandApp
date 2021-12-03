//
//  BLEManager.swift
//  Tether
//
//  Created by Eric Hull on 9/21/21.
//

import Foundation
import CoreBluetooth
import UserNotifications
import SwiftUI

struct Peripheral: Identifiable{
    let id: Int
    let deviceName: String
    let rssi: Int
    let manufData: Int
    let debug: String
    let originalReference: CBPeripheral
    let coreBluetoothID: UUID
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
    //var rssiArr: [Float]
    var kidName: String
    var batteryLevel: Int
    var braceletOn: Bool
    var txPower: Int8
    var inRange: Bool
    var disconnected: Bool // used in reconnecting after disconnect
    var currentDistanceText: String
    var currentDistanceNum: Double
    var sampleRssiTimer: DispatchSourceTimer?
    var stopSamplingTimer: DispatchSourceTimer?
    var refreshDistanceTimer: DispatchSourceTimer?
    var rangeColor: Color
    var wornColor: Color
    
    
    init(){
        self.rssiArr = []
        self.batteryLevel = 100
        self.braceletOn = false
        self.txPower = 0
        self.inRange = true
        self.currentDistanceText = ""
        self.currentDistanceNum = 0.0
        self.kidName = ""
        self.disconnected = false
        self.rangeColor = Color.green
        self.wornColor = Color.green
        
    }
}


class TetherbandCharHandles{ // Container to hold the handles for all characteristics
    var identifyWriteChar: CBCharacteristic! // for writing emergency alert values
    var batteryNotifyChar: CBCharacteristic! // to receive battery level notifications
    var txPowerReadChar: CBCharacteristic! // for distance determination
    var immediateAlertWriteChar: CBCharacteristic! // to write alerts for distance determination
    var linkLossReadWriteChar: CBCharacteristic! // for link loss service
    var capsenseReadChar: CBCharacteristic! // to receive events when bracelet is removed from child's wrist
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
    var capsenseChar: CBUUID?
    
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
    @Published var trackedFlag: [Bool] = [false]
    @Published var backgroundFlag = false // content view flips this to true when the user switches to another app or locks their phone. Allows distance to keep tracking in background
    @Published var nfcColorNotSelected = false
    
    var currentIdentifyUUID: String! // unique UUID value read from the NFC tag
    var includedServices: TetherbandUUIDS?
    let NUM_RSSI_SAMPLES = 50 // num of rssi samples to take before averaging.
    let MAX_DISTANCE: Double = 1000 // given in mm. aka 15m.
    
    let distanceQueue = DispatchQueue(label: "com.tetherband.distance", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .workItem)
    
    var logFilePath: Logger? // logging
    var log: LoggerFuncs = LoggerFuncs(date: true) // used to add date time stamp to prints written to file on phone.
    var outOfRangeCount = 0 // used to schedule notifications when bracelet is out of range
    
    var contentViewChildList: ChildViewModel? // have to store a reference to child view list from content view so we can delete/add entries on ble events
  
    
    init(logger:Logger){
        super.init()
        localCentral = CBCentralManager(delegate: self, queue: nil)
        localCentral.delegate = self
        logFilePath = logger
    }
    
    func setChildList(list: ChildViewModel){
        self.contentViewChildList = list
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
        var alreadyExists: Bool = false
        var id: Int = connectedPeripherals.count
        
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String{
            peripheralName = name
        }
        else{
            peripheralName = "Unknown"
        }
        
        for connectedPeripheral in connectedPeripherals{ // handle reconnect behavior if bracelets disconnect
            if peripheralName == connectedPeripheral.deviceName{
                alreadyExists = true
                id = connectedPeripheral.id
                break
            }
        }
        
        if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Int{
            manufDataInt = data
        }
        else{
            manufDataInt = 0
        }
        
        peripheralManufData = convertMirror(mirror: peripheralManufDataList)
        
        let newPeripheralUUIDS = TetherbandUUIDS(identify: CBUUID.init(string: currentIdentifyUUID))
        
        let newPeripheral = Peripheral(id: id, deviceName: peripheralName, rssi: RSSI.intValue, manufData: manufDataInt, debug: peripheralManufData, originalReference: peripheral, coreBluetoothID: peripheral.identifier, identifyUUID: [newPeripheralUUIDS.identifyService], UUIDS: newPeripheralUUIDS)
        newPeripheral.setPeripheralDelegate(delegate: self)
        
        //print(newPeripheral)
        if !alreadyExists{
            connectedPeripherals.append(newPeripheral)
        }
        localCentral.connect(peripheral, options: nil)
    }
    
    // Saves reference to connected peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        for connectedPeripheral in connectedPeripherals{
            if peripheral.isEqual(connectedPeripheral.originalReference){
                if connectedPeripheral.braceletInfo.disconnected{
                    print("Successfully reconnected to device: \(connectedPeripheral.deviceName)")
                    //print(log.addDate(message: "Bracelet Name: \(connectedPeripheral.deviceName) Reconnected."), to: &logFilePath!)
                    connectedPeripheral.braceletInfo.disconnected = false
                    let tetherServices = connectedPeripheral.UUIDS.getAllServices()
                    peripheral.discoverServices(tetherServices)
                    if trackingStarted[connectedPeripheral.id]{ // if we were tracking distance when got disconnected, restart tracking
                        connectedPeripheral.originalReference.readRSSI()
                    }
                    create_notification(type: "Bluetooth reconnected", peripheral: connectedPeripheral)
                }
                else{
                    //print(log.addDate(message: "Connected Successfully to device: \(connectedPeripherals[connectedPeripherals.endIndex-1].deviceName)!"), to: &logFilePath!)
                    print("Connected Successfully to device: \(connectedPeripherals[connectedPeripherals.endIndex-1].deviceName)")
                    let tetherServices = connectedPeripherals[connectedPeripherals.endIndex-1].UUIDS.getAllServices()
                    if connectedPeripherals.count > 1{
                        batteryLevelUpdated.append(false)
                        trackingStarted.append(false)// increase the size of flag array by one
                        trackedFlag.append(false)
                    }
                    peripheral.discoverServices(tetherServices)
                    //print(log.addDate(message: "All services and characteristics setup successfully"), to: &logFilePath!)
                    create_notification(type: "Bluetooth connected", peripheral: connectedPeripheral)
                }
            }
        }
    }
    
    // error handler in case connection fails
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Couldn't connect to \(String(describing: peripheral.name))")
        create_notification(type: "Bluetooth failed to connect", peripheral: connectedPeripherals[connectedPeripherals.endIndex-1])
        connectedPeripherals.remove(at: connectedPeripherals.endIndex-1) // remove from the connected peripherals array
    }
    
    
    func scanAndConnect(){
        currentIdentifyUUID = "B0201F39-97BC-A2F5-4621-C9AB58C9BFCA"
        let customUUID: [CBUUID] = [CBUUID.init(string: "B0201F39-97BC-A2F5-4621-C9AB58C9BFCA")]
        localCentral.scanForPeripherals(withServices: customUUID, options: nil)
    }
    
    func scanAndConnect(read_uuid: String, disconnected: Bool){
        currentIdentifyUUID = read_uuid
        if !disconnected{
            currentIdentifyUUID.remove(at: currentIdentifyUUID.startIndex)
        }
        let customUUID : [CBUUID] = [CBUUID.init(string: currentIdentifyUUID)]
        localCentral.scanForPeripherals(withServices: customUUID, options: nil)
    }
    
    //STILL NEED: Handle cases when reconnect fails
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        for connectedPeripheral in connectedPeripherals{
            if peripheral.identifier == connectedPeripheral.coreBluetoothID{
                //print(log.addDate(message: "Bracelet Name: \(connectedPeripheral.deviceName) Disconnected! Previous Distance: \(connectedPeripheral.braceletInfo.currentDistanceText)"), to: &logFilePath!)
                let reconnectUUID = connectedPeripheral.identifyUUID[0].uuidString
                connectedPeripheral.braceletInfo.disconnected = true
                create_notification(type: "Disconnected from", peripheral: connectedPeripheral)
                self.scanAndConnect(read_uuid: reconnectUUID, disconnected: true)
            }
        }
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
        
        //let currentPeripheralIndex = connectedPeripherals[connectedPeripherals.endIndex-1].id
        var currentPeripheralIndex = 0
        for connectedPeripheral in connectedPeripherals{
            if peripheral.isEqual(connectedPeripheral.originalReference){
                currentPeripheralIndex = connectedPeripheral.id
            }
        }
        let currentPeripheralServices = connectedPeripherals[currentPeripheralIndex].UUIDS.getAllServices()
        print("Items in current peripheral services are:")
        for item in currentPeripheralServices{
            print(item)
        }
        
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
            print("characteristics for identify service are: \(characteristics[0].uuid.debugDescription) and \(characteristics[1].uuid.debugDescription)")
            connectedPeripherals[currentPeripheralIndex].UUIDS.identifyChar = characteristics[0].uuid
            connectedPeripherals[currentPeripheralIndex].characteristicHandles.identifyWriteChar = characteristics[0]
            connectedPeripherals[currentPeripheralIndex].UUIDS.capsenseChar = characteristics[1].uuid
            connectedPeripherals[currentPeripheralIndex].characteristicHandles.capsenseReadChar = characteristics[1]
            peripheral.setNotifyValue(true, for: connectedPeripherals[currentPeripheralIndex].characteristicHandles.capsenseReadChar)
            for connectedPeripheral in connectedPeripherals{
                if peripheral.isEqual(connectedPeripheral.originalReference){
                    if(self.nfcColorNotSelected){ // app was killed while bracelets were connected so bracelet needs to flash original blue light instead of team color light
                        var appKilled: UInt8 = 10
                        connectedPeripheral.originalReference.writeValue(Data(bytes: &appKilled, count: 1), for: connectedPeripheral.characteristicHandles.identifyWriteChar, type: .withoutResponse)
                    }
                    else{
                        var appKilled: UInt8 = 11
                        connectedPeripheral.originalReference.writeValue(Data(bytes: &appKilled, count: 1), for: connectedPeripheral.characteristicHandles.identifyWriteChar, type: .withoutResponse)
                    }
                }
            }
            print("DISCOVERED CUSTOM IDENTIFY SERVICE AND CHARS")
            
        default:
            print("Services case statement to discover characteristics failed for service: \(service.description).")
        }
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
                    batteryLevelUpdated[connectedPeripheralIndex] = true
                    
                case connectedPeripheral.UUIDS.identifyChar:
                    if Int(firstByte) == 1{ // background distance notification
                        print("Received Background Distance Notification.")
                        if(trackingStarted[connectedPeripheral.id]){
                            peripheral.readRSSI()
                        }
                    }
                    
                case connectedPeripheral.UUIDS.capsenseChar: // cap sense alerts here
                    if Int(firstByte) == 2{ // bracelet removed
                        print("BRACELET ON")
                        connectedPeripheral.braceletInfo.braceletOn = true
                        connectedPeripheral.braceletInfo.wornColor = Color.green
                        trackingStarted[connectedPeripheral.id] = true // trigger UI update
                        create_notification(type: "put their bracelet on!", peripheral: connectedPeripheral)
                    }
                    else if Int(firstByte) == 3{ // bracelet removed
                        print("BRACELET REMOVED")
                        connectedPeripheral.braceletInfo.braceletOn = false
                        connectedPeripheral.braceletInfo.wornColor = Color.red
                        trackingStarted[connectedPeripheral.id] = true // trigger UI update
                        create_notification(type: "removed their bracelet!", peripheral: connectedPeripheral)
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
        for connectedPeripheral in connectedPeripherals{
            if peripheral.isEqual(connectedPeripheral.originalReference){
                print("Wrote value to Bracelet Name: \(connectedPeripheral.deviceName) in \(characteristic.debugDescription)")
            }
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
                        cancelTimer.schedule(deadline: .now(), repeating: .milliseconds(NUM_RSSI_SAMPLES), leeway: .microseconds(0))
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
                            //currentPeripheral.braceletInfo.rssiArr.append(RSSI.intValue)
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
                    //let rssi = rssiArr.reduce(0.0, +) / Float(rssiArr.count)
                    let mode = rssiArr.reduce([Int: Int]()){
                        var counts = $0
                        counts[$1] = ($0[$1] ?? 0) + 1
                        return counts
                    }.max{$0.1 < $1.1}?.0
                    let rssi = mode!
                    //let rssi = rssiArr.reduce(0, +) / rssiArr.count
                    currentPeripheral.braceletInfo.rssiArr.removeAll() // clear the array for next set of samples
                    
                    let currentPeripheralIndex = currentPeripheral.id
                    
                    NSLog("Updating distance with RSSI and TX Values: %d, %d", rssi, txPower)
                    //print(log.addDate(message: "Bracelet:\(currentPeripheral.deviceName),Updating_Distance,RSSI_is:\(rssi)"), to: &logFilePath!)
                    if updateDistance(rssi: rssi, txPower: Int(txPower), currentPeripheral: currentPeripheral){ // still in range
                        trackingStarted[currentPeripheralIndex] = true // let the UI know we have started tracking
                        trackedFlag[currentPeripheralIndex] = !trackedFlag[currentPeripheralIndex]
                        
                        if outOfRangeCount != 0{
                            outOfRangeCount = 0
                            remove_notifications(type: "Out of Range Real", peripheral: currentPeripheral)
                        }
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
                        trackedFlag[currentPeripheralIndex] = !trackedFlag[currentPeripheralIndex]
                        outOfRangeCount += 1
                        //create_notification(type: "Out of Range First", peripheral: currentPeripheral)
                        //print(log.addDate(message: "Bracelet:\(currentPeripheral.deviceName),FIRST_OUT_OF_RANGE,Formatted_Distance:\(currentPeripheral.braceletInfo.currentDistanceText),Raw_Distance:\(currentPeripheral.braceletInfo.currentDistanceNum)"), to: &logFilePath!)
                        if outOfRangeCount == 2{
                            
                            create_notification(type: "Out of Range Real", peripheral: currentPeripheral)
                            NSLog("Added out of range notification")
                            outOfRangeCount = 0
                            if(currentPeripheral.braceletInfo.inRange){ // if this is true, then it's the first time it has gone out of range so we send flag to bracelet
                                var rangeFlag = 5
                                currentPeripheral.originalReference.writeValue(Data(bytes: &rangeFlag, count: 1), for: currentPeripheral.characteristicHandles.identifyWriteChar, type: .withoutResponse)
                            }
                            currentPeripheral.braceletInfo.inRange = false // change flag to false
                            
                            //print(log.addDate(message: "Bracelet:\(currentPeripheral.deviceName),OUT_OF_RANGE,Formatted_Distance:\(currentPeripheral.braceletInfo.currentDistanceText),Raw_Distance:\(currentPeripheral.braceletInfo.currentDistanceNum)"), to: &logFilePath!)
                        }
                        
                        
                        // Create timer to check distance again in 200 ms
                        let refreshTimer = DispatchSource.makeTimerSource(flags: .strict, queue: distanceQueue)
                        refreshTimer.schedule(deadline: .now(), repeating: .never, leeway: .milliseconds(0))
                        refreshTimer.setEventHandler{
                            peripheral.readRSSI()
                        }
                        currentPeripheral.braceletInfo.refreshDistanceTimer = refreshTimer
                        currentPeripheral.braceletInfo.refreshDistanceTimer?.resume()
                        
                        // Write value to bracelet to trigger out of range alerts
                        /*var val: UInt8 = 4 // flag for out of range as defined in nordic code
                        let outOfRangeValue = Data(bytes: &val, count: 1)
                        currentPeripheral.originalReference.writeValue(outOfRangeValue, for: currentPeripheral.characteristicHandles.identifyWriteChar, type: .withoutResponse)*/
                    }
                }
            }
        }
    }
    
    // Function taken from Nordic Toolbox for iOS
    func updateDistance(rssi: Int, txPower: Int, currentPeripheral: Peripheral) -> Bool{
    //func updateDistance(rssi: Float, txPower: Int, currentPeripheral: Peripheral) -> Bool{
        let distance = pow(10, (Double(txPower - rssi) / 21.5)) // exponent values of 4.2 is 15.8 meters, 4.15 is 14.125 meters
        let distanceUnitVal = Measurement<UnitLength>(value: distance, unit: .millimeters)
        let formatter = MeasurementFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        formatter.numberFormatter = numberFormatter
        formatter.unitOptions = .naturalScale
        currentPeripheral.braceletInfo.currentDistanceText = formatter.string(from: distanceUnitVal)
        currentPeripheral.braceletInfo.currentDistanceNum = distance
        print("Bracelet name \(currentPeripheral.deviceName): Formatted distance from update distance function is: \(currentPeripheral.braceletInfo.currentDistanceText)")
        
        var rangeFlag = 0
        
        if distance > MAX_DISTANCE{
            /*if currentPeripheral.braceletInfo.inRange == true{ // only send flag to bracelet once and not again until back in range
                rangeFlag = 5
                currentPeripheral.originalReference.writeValue(Data(bytes: &rangeFlag, count: 1), for: currentPeripheral.characteristicHandles.identifyWriteChar, type: .withoutResponse)
            }
            currentPeripheral.braceletInfo.inRange = false
            print(log.addDate(message: "Bracelet:\(currentPeripheral.deviceName),OUT_OF_RANGE,Formatted_Distance:\(currentPeripheral.braceletInfo.currentDistanceText),Raw_Distance:\(currentPeripheral.braceletInfo.currentDistanceNum)"), to: &logFilePath!)*/
            print("Distance of \(distance) mm determined OUT OF RANGE in update distance function")
            currentPeripheral.braceletInfo.rangeColor = Color.red
            return false
        }
        else{
            if(!currentPeripheral.braceletInfo.inRange){ // flag would have been false if coming back from out of range
                create_notification(type: "In Range", peripheral: currentPeripheral)
                rangeFlag = 6
                currentPeripheral.originalReference.writeValue(Data(bytes: &rangeFlag, count: 1), for: currentPeripheral.characteristicHandles.identifyWriteChar, type: .withoutResponse)
            }
            currentPeripheral.braceletInfo.inRange = true
            
            
            currentPeripheral.braceletInfo.rangeColor = Color.green
            //print(log.addDate(message: "Bracelet:\(currentPeripheral.deviceName),IN_RANGE,Formatted_Distance:\(currentPeripheral.braceletInfo.currentDistanceText),Raw_Distance:\(currentPeripheral.braceletInfo.currentDistanceNum)"), to: &logFilePath!)
            //print("Distance of \(distance) mm determined IN RANGE in update distance function")
            return true
        }
    }
    
    func sendEmergencyAlert(start: Bool){
        var emergencyFlag = 0
        if start{
            emergencyFlag = 7 // flags as defined in nordic code
        }
        else{
            emergencyFlag = 8 // flags as defined in nordic code
        }
        for connectedPeripheral in connectedPeripherals{
            if trackingStarted[connectedPeripheral.id]{
                connectedPeripheral.originalReference.writeValue(Data(bytes: &emergencyFlag, count: 1), for: connectedPeripheral.characteristicHandles.identifyWriteChar, type: .withoutResponse)
            }
        }
    }
    
    func powerOffBracelets(){
        var powerOffFlag = 9
        for connectedPeripheral in connectedPeripherals{
            if trackingStarted[connectedPeripheral.id]{
                connectedPeripheral.braceletInfo.stopSamplingTimer?.cancel()
                connectedPeripheral.braceletInfo.refreshDistanceTimer?.cancel()
                connectedPeripheral.braceletInfo.sampleRssiTimer?.cancel()
                connectedPeripheral.originalReference.writeValue(Data(bytes: &powerOffFlag, count: 1), for: connectedPeripheral.characteristicHandles.identifyWriteChar, type: .withoutResponse)
            }
        }
        connectedPeripherals.removeAll()
        trackingStarted.removeAll()
        trackingStarted.append(false)
    }
    
    // Creates a notification for given type associated with given peripheral
    // STILL NEED: Add case for bracelet removed behavior
    func create_notification(type: String, peripheral: Peripheral){
        UNUserNotificationCenter.current().delegate = self
        let content = UNMutableNotificationContent()
        switch (type){
        case "Out of Range Real":
            content.targetContentIdentifier = "\(type): \(peripheral.braceletInfo.kidName)"
            content.title = "\(peripheral.braceletInfo.kidName) is out of range! Please find them ASAP!"
            content.sound = UNNotificationSound.init(named: UNNotificationSoundName(rawValue: "out_of_range_quip.m4a"))
        case "Out of Range First":
            content.targetContentIdentifier = "\(type): \(peripheral.braceletInfo.kidName)"
            content.title = "\(peripheral.braceletInfo.kidName) first out of range!"
            content.sound = UNNotificationSound.init(named: UNNotificationSoundName(rawValue: "out_of_range_quip.m4a"))
        case "In Range":
            content.targetContentIdentifier = "\(type): \(peripheral.braceletInfo.kidName)"
            content.title = "\(peripheral.braceletInfo.kidName) is back in range."
        case "Bluetooth connected":
            content.targetContentIdentifier = "\(type) to \(peripheral.deviceName)"
            content.title = "\(type) to \(peripheral.deviceName)!"
        case "Bluetooth failed to connect":
            content.targetContentIdentifier = "\(type) to \(peripheral.deviceName)"
            content.title = "\(type) to \(peripheral.deviceName)!"
        case "removed their bracelet!":
            content.targetContentIdentifier = "\(peripheral.braceletInfo.kidName) \(type)"
            content.title = "\(peripheral.braceletInfo.kidName) \(type)"
        case "put their bracelet on!":
            content.targetContentIdentifier = "\(peripheral.braceletInfo.kidName) \(type)"
            content.title = "\(peripheral.braceletInfo.kidName) \(type)"
        case "Disconnected from":
            content.targetContentIdentifier = "\(type): \(peripheral.braceletInfo.kidName)"
            content.title = "\(peripheral.braceletInfo.kidName) bracelet is disconnected!."
        case "Bluetooth reconnected":
            content.targetContentIdentifier = "\(type): \(peripheral.braceletInfo.kidName)"
            content.title = "\(peripheral.braceletInfo.kidName) bracelet is reconnected!."
        default:
            print("in default of create notification function")
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: peripheral.deviceName, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    // Cancels and removes any pending notifications associated with given peripheral and identifier type.
    // Called when bracelet goes back in range or is put back on
    func remove_notifications(type: String, peripheral: Peripheral){
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["\(type): \(peripheral.braceletInfo.kidName)"])
        center.removeDeliveredNotifications(withIdentifiers: ["\(type): \(peripheral.braceletInfo.kidName)"])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    // STILL NEED: MAKE APP NOT KEEP NOTIFYING OF OUT OF RANGE IF USER TAPS THE NOTIFICATION.
    /*func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        <#code#>
    }*/
    
    // debug function to print out the contents of manufacturer data in advertisement packets
    func convertMirror(mirror: Mirror) -> String{ // for debugging
        var debugString = "--"
        mirror.children.forEach {
            debugString += "\n\($0.label ?? ""): \($0.value ?? "")"
        }
        debugString += "--"
        return debugString
    }
}
