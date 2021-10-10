//
//  BLEManager.swift
//  Tether
//
//  Created by Eric Hull on 9/21/21.
//

import Foundation
import CoreBluetooth

struct Peripheral: Identifiable{
    let id: Int
    let name: String
    let rssi: Int
    let manufData: Int
    let debug: String
    let originalReference: CBPeripheral
}


class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    var localCentral: CBCentralManager!
    @Published var isOn = false
    @Published var scannedPeripherals = [Peripheral]()
    @Published var connectedPeripheral: CBPeripheral?
    @Published var connected: Bool = false 
    var scanAndConnectFlag = false
    
    
    override init() {
        super.init()
        
        localCentral = CBCentralManager(delegate: self, queue: nil)
        localCentral.delegate = self
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
        
        localCentral.connect(peripheral, options: nil)
        connected = true
        
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
        
        let newPeripheral = Peripheral(id: scannedPeripherals.count, name: peripheralName, rssi: RSSI.intValue, manufData: manufDataInt, debug: peripheralManufData, originalReference: peripheral)
        print(newPeripheral)
        scannedPeripherals.append(newPeripheral)
    }
    
    // Saves reference to connected peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        print("Connected Successfully!")
    }
    
    // error handler in case connection fails
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Couldn't connect to \(String(describing: peripheral.name))")
    }
    
    // connects to the given peripheral
    /*func connect(peripheral: CBPeripheral){
        localCentral.connect(peripheral, options: nil)
    }
    
    // start scanning for devices advertising service matching custom UUID variable. This is the value that the NFC tag will send to the iphone.
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
    
    func scanAndConnect(){
        scanAndConnectFlag = true
        let customUUID: [CBUUID] = [CBUUID.init(string: "B0201F39-97BC-A2F5-4621-C9AB58C9BFCA")]
        localCentral.scanForPeripherals(withServices: customUUID, options: nil)
    }
    
    func scanAndConnect(read_uuid: String){
        scanAndConnectFlag = true
        var new_string : String
        new_string = read_uuid
        new_string.remove(at: new_string.startIndex)
        let customUUID : [CBUUID] = [CBUUID.init(string: new_string)]
        localCentral.scanForPeripherals(withServices: customUUID, options: nil)
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
    
}
