//
//  BleMng.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 06.06.2023.
//

import Foundation
import CoreBluetooth


// DeviceScaningDelegate Protocol: Implements to get scanning devices
internal protocol DeviceScaningDelegate: AnyObject{
    func scanningStatus(status: Int)
    func bleManagerDiscover(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
}

// DeviceConnectionDelegate Protocol: Implements to get Connection/Disconnection Success or Failure
internal protocol DeviceConnectionDelegate: AnyObject {
    func bleManagerConnectionFail (_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    func bleManagerDidConnect(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    func bleManagerDisConect(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
}

// ServicesDiscoveryDelegate Protocol: Implements to get Services,Characteristics and Descriptors Discovery
internal protocol ServicesDiscoveryDelegate: AnyObject {
    func bleManagerDiscoverService (_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    func bleManagerDiscoverCharacteristics (_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    func bleManagerDiscoverDescriptors (_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
}

// ReadWirteCharteristicDelegate Protocol: Implements to get Read,Write and Notify Characterisctis and Descriptors
internal protocol ReadWirteCharteristicDelegate: AnyObject {
    func bleManagerDidUpdateValueForChar(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    func bleManagerDidWriteValueForChar(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    func bleManagerDidUpdateValueForDesc(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?)
    func bleManagerDidWriteValueForDesc(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?)
    func bleManagerDidUpdateNotificationState(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
}

// ReadRSSIValueDelegate Protocol: Implements to get RSSI Value
internal protocol ReadRSSIValueDelegate: AnyObject {
    func bleManagerReadRSSIValue(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?)
}

private var sharedBLEManager: BLEManager? = nil

internal class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    internal var centralManager: CBCentralManager?
    internal var scaningDelegate: DeviceScaningDelegate?
    internal var connectionDelegate: DeviceConnectionDelegate?
    internal var discoveryDelegate: ServicesDiscoveryDelegate?
    internal var readWriteCharDelegate: ReadWirteCharteristicDelegate?
    internal var readRSSIdelegate: ReadRSSIValueDelegate?
    internal var stopScanTimer: Timer?
    static func getSharedBLEManager () -> BLEManager {
        if sharedBLEManager == nil {
            sharedBLEManager = BLEManager()
        }
        return sharedBLEManager!
    }
    func subscribeToCharacteristic(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
           // Подписываемся на уведомления об изменении характеристики
           peripheral.setNotifyValue(true, for: characteristic)
       }
    // MARK: CBPeripheralDelegate
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
                readWriteCharDelegate?.bleManagerDidUpdateValueForChar(peripheral, didUpdateValueFor:characteristic, error:error)
        }
   // MARK: Intializing BLE CentralManager
    internal func initCentralManager(queue: DispatchQueue?, options: [String : Any]?) {
        if self.centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: queue, options: options)
        }
    }
    
    // MARK: BLE CBCentralManagerDelegate
    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 10.0, *) {
            switch central.state {
            case CBManagerState.unauthorized:
                scaningDelegate?.scanningStatus(status:CBManagerState.unauthorized.rawValue)
                break
            case CBManagerState.poweredOff:
                scaningDelegate?.scanningStatus(status:CBManagerState.poweredOff.rawValue)
                DeviceService.getInstance().ls.addLogs(text:"poweredOff")
                break
            case CBManagerState.resetting:
                scaningDelegate?.scanningStatus(status:CBManagerState.resetting.rawValue)
                break
            case CBManagerState.poweredOn:
                scaningDelegate?.scanningStatus(status:CBManagerState.poweredOn.rawValue)
                break
            default:
                break
            }
        } else {
           let cmState: CBCentralManagerState = (CBCentralManagerState)(rawValue: central.state.rawValue)!
            switch cmState {
            case CBCentralManagerState.unauthorized:
                scaningDelegate?.scanningStatus(status:CBCentralManagerState.unauthorized.rawValue)
                break
            case CBCentralManagerState.poweredOff:
                scaningDelegate?.scanningStatus(status:CBCentralManagerState.poweredOff.rawValue)
                DeviceService.getInstance().ls.addLogs(text:"poweredOff")
                break
            case CBCentralManagerState.poweredOn:
                scaningDelegate?.scanningStatus(status:CBCentralManagerState.poweredOn.rawValue)
                break
            case CBCentralManagerState.resetting:
                scaningDelegate?.scanningStatus(status:CBCentralManagerState.resetting.rawValue)
                break
            default:
                break
            } }
    }
    
    internal func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripheral.delegate = self
        scaningDelegate?.bleManagerDiscover(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
    }
    
    internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        connectionDelegate?.bleManagerDidConnect(central, didConnect: peripheral)
    }
    
    internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionDelegate?.bleManagerConnectionFail(central, didFailToConnect: peripheral, error: error)
    }
    
    internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionDelegate?.bleManagerDisConect(central, didDisconnectPeripheral: peripheral, error: error)
    }
    
    // MARK: BLE CBPeripheralDelegate
    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        discoveryDelegate?.bleManagerDiscoverService(peripheral, didDiscoverServices: error)
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        discoveryDelegate?.bleManagerDiscoverCharacteristics(peripheral, didDiscoverCharacteristicsFor: service, error: error)
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        discoveryDelegate?.bleManagerDiscoverDescriptors(peripheral, didDiscoverDescriptorsFor: characteristic, error: error)
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        readWriteCharDelegate?.bleManagerDidWriteValueForChar(peripheral, didWriteValueFor: characteristic, error: error)
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        readWriteCharDelegate?.bleManagerDidUpdateNotificationState(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        readRSSIdelegate?.bleManagerReadRSSIValue(peripheral, didReadRSSI: RSSI, error: error)
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        readWriteCharDelegate?.bleManagerDidWriteValueForDesc(peripheral, didWriteValueFor: descriptor, error: error)
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        readWriteCharDelegate?.bleManagerDidUpdateValueForDesc(peripheral, didUpdateValueFor: descriptor, error: error)
    }
    
    // MARK: Scanning Process
    internal func scanAllDevices(){
        self.scanDevice(serviceUUIDs: nil, options: nil)
    }
    
    internal func scanDevice(serviceUUIDs: NSArray?, options: [String : Any]?) {
        if stopScanTimer != nil {
            stopScanTimer?.invalidate()
            stopScanTimer = nil
        }
        centralManager?.scanForPeripherals(withServices: (serviceUUIDs as? [CBUUID]?)!, options: options)
        self.applyStopScanTimer()
    }
    
    internal func stopScan(){
        centralManager?.stopScan()
    }
    
    @objc internal func stopScanningAfterInterval(){
        if centralManager!.isScanning {
            centralManager?.stopScan()
        }
    }
    
    // MARK: Connection Process
    internal func connectPeripheralDevice(peripheral: CBPeripheral, options: [String : Any]?) {
        self.centralManager?.connect(peripheral, options: options)
    }
    
    internal func disconnectPeripheralDevice(peripheral: CBPeripheral) {
        self.centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: Discover Services
    internal func discoverAllServices(peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    internal func discoverServiceByUUIDs(servicesUUIDs: NSArray, peripheral: CBPeripheral) {
        peripheral.discoverServices(servicesUUIDs as? [CBUUID])
    }
    
    // MARK: Discover Characteristics
    internal func discoverAllCharacteristics(peripheral: CBPeripheral, service: CBService) {
        peripheral.discoverCharacteristics(nil, for: service)
    }
    
    internal func discoverCharacteristicsByUUIDs(charUUIds: NSArray, peripheral: CBPeripheral, service: CBService) {
        peripheral.discoverCharacteristics(charUUIds as? [CBUUID], for: service)
    }
    
    // MARK: Discover Descriptors
    internal func discoverDescriptorsByCharacteristic(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        peripheral.discoverDescriptors(for: characteristic)
    }
    
    internal func writeCharacteristicValue(peripheral: CBPeripheral, data: Data, char: CBCharacteristic, type: CBCharacteristicWriteType) {
        peripheral.writeValue(data, for: char, type: type)
    }
    
    // MARK: BLE Properties Reterival
    internal func readCharacteristicValue(peripheral: CBPeripheral, char: CBCharacteristic) {
        peripheral.readValue(for: char)
    }
    
    internal func setNotifyValue(peripheral: CBPeripheral, enabled: Bool, char: CBCharacteristic) {
       peripheral.setNotifyValue(enabled, for: char)
    }
    
    internal func writeDescriptorValue(peripheral: CBPeripheral, data: Data, descriptor: CBDescriptor) {
        peripheral.writeValue(data, for: descriptor)
    }
    
    internal func readDescriptorValue(peripheral: CBPeripheral, descriptor: CBDescriptor) {
        peripheral.readValue(for: descriptor)
    }
    
    // MARK: Read RSSI Value
    internal func readRSSI(peripheral: CBPeripheral) {
        peripheral.readRSSI()
    }
    internal func getConnectedPeripherals(serviceUUIds: NSArray) -> NSArray? {
        return self.centralManager?.retrieveConnectedPeripherals(withServices: (serviceUUIds as? [CBUUID])!) as NSArray?
    }
    
    @objc internal func applyStopScanTimer() {
        stopScanTimer = Timer.scheduledTimer(timeInterval: TimeInterval(15.0), target: self, selector: #selector(stopScanningAfterInterval), userInfo: nil, repeats: false)
    }
    
}
