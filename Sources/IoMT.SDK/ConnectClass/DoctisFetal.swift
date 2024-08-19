//
//  Elta.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 04.07.2023.
//

import Foundation
import CoreBluetooth
import CommonCrypto
import Decoder
extension Int{
    var doubleValue: Double{
        return(Double(self))
    }
}
public class DoctisFetal:
    ConnectClass,
    DeviceScaningDelegate,
    DeviceConnectionDelegate,
    ServicesDiscoveryDelegate,
    ReadWirteCharteristicDelegate{
    
    private var instanceDF: DoctisFetal? = nil
    internal var _identifer: UUID?
    internal var _mac:String?
    var peripheral: CBPeripheral? = nil
    var serial:String = "";
    var model:String = "";
    var battLevel:Int = -1;
    var id:UUID = UUID();
    static var test:Bool = false
    var rightDisconnect:Bool = false
    var reconnectingState:Bool = false
    internal var startTime:Date?
    public var peripherals: [DisplayPeripheral] = []
    static var itter:Int = 0
    static var time:Int = 0
    internal var rxtxService: CBService?
    public struct DataItem:Codable {
        var key: TimeInterval
        var value: Int
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    var rateArray: [DataItem] = []
    var tocoArray:[DataItem] = []
    var moveArray:[TimeInterval] = []
    internal var rxCharacteistic: CBCharacteristic?
    var stopwatch = Stopwatch()
    internal var txCharacteistic: CBCharacteristic?
    
    internal var internetManager: InternetManager = InternetManager.getManager()
   // var decoder = LMTPDecoder()
    var disconnectTimer: Timer? = nil
    internal static let FormatPlatformTime: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.formatOptions = [.withInternetDateTime]
        return dateFormatter
    }()
    private static var sharedInstance: DoctisFetal?

     // Публичное статическое свойство для доступа к общему экземпляру класса
     public static var shared: DoctisFetal {
         if let sharedInstance = sharedInstance {
             return sharedInstance
         } else {
             sharedInstance = DoctisFetal()
             return sharedInstance!
         }
     }

     // Метод для создания нового экземпляра класса
     public static func createInstance() -> DoctisFetal {
         if(DoctisFetal.activeExecute == false){
             sharedInstance = nil
             sharedInstance = DoctisFetal()
         }
         return sharedInstance!
     }


     // Приватный конструктор, чтобы предотвратить создание других экземпляров класса
     private override init() {
         super.init()
     }

    ///Объект для форматирования времени при записи данны
    internal static let FormatDeviceTime: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyMMddHHmmss"
        df.timeZone = TimeZone.current
        return df
    }()
    
    internal let manager: BLEManager = {
        return BLEManager.getSharedBLEManager()
    }()
    
    internal func getLastTime(serial: String){
        internetManager.getTime(serial: serial)
    }
    
    override public func connect(device: CBPeripheral) {

               DoctisFetal.activeExecute = true
               manager.connectionDelegate = self
               _identifer = device.identifier
               manager.connectPeripheralDevice(peripheral: device, options: nil)

    }
     
    override public func search(timeout: UInt32) {
        manager.scaningDelegate = self
        manager.scanAllDevices()
        print("START SEARCH")
        print(DoctisFetal.activeExecute)
        sleep(timeout)
        manager.stopScan()
        callback?.searchedDevices(peripherals: peripherals)
    }

    //DeviceScaningDelegate
    internal func scanningStatus(status: Int) {
        DeviceService.getInstance().ls.addLogs(text:String(describing:status))
        if(status == 4){
            rightDisconnect = false
            DoctisFetal.activeExecute = false
        }
        if(status == 5 && serial != "" && model != "" && battLevel != -1){
            if let peripheral = self.peripheral{
                manager.connectPeripheralDevice(peripheral: peripheral, options: nil)
            }
            }
    }
    func formatMACAddress(_ mac: String) -> String {
        var formattedMAC = ""
        for (index, char) in mac.enumerated() {
            if index % 2 == 0 && index > 0 {
                formattedMAC += ":"
            }
            formattedMAC.append(char)
        }
        return formattedMAC
    }

    internal func bleManagerDiscover(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if(peripheral.name != nil){
            for (index, foundPeripheral) in peripherals.enumerated() {
                if foundPeripheral.peripheral?.identifier == peripheral.identifier {
                    peripherals[index].lastRSSI = RSSI
                    peripherals[index].peripheral = peripheral
                    return
                }
            }
            let isConnectable = advertisementData["kCBAdvDataIsConnectable"] as? Bool
            let localName = peripheral.name!
            let displayPeripheral: DisplayPeripheral = DisplayPeripheral(peripheral: peripheral, lastRSSI: RSSI, isConnectable: isConnectable!, localName: localName)
            callback?.findDevice(peripheral: displayPeripheral);
            peripherals.append(displayPeripheral)
        }
    }
    
    //DeviceConnectingDelegate
    internal func bleManagerConnectionFail(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("fail")
callback?.onExpection(mac: _identifer!, ex: error!)
    }
    
    // This method will be triggered once device will be connected.
    internal func bleManagerDidConnect(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        rightDisconnect = false
        reconnectingState = false
        manager.discoveryDelegate = self
        manager.readWriteCharDelegate = self
        callback?.onStatusDevice(mac: _identifer!, status: BluetoothStatus.ConnectStart)
        peripheral.discoverServices(nil)
        self.peripheral = peripheral
     //   decoder.startRealTimeAudioPlyer()
        if(serial == "" && battLevel == -1){
       //     decoder.startMonitor(withAudioFilePath: getDocumentsDirectory().appendingPathComponent(id.uuidString).path + ".mp3")
        }
    }
    // This method will be triggered once device will be disconnected.
    internal func bleManagerDisConect(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
          if let error = error {
              callback?.onExpection(mac: peripheral.identifier, ex: error)
          }
          
          if(rightDisconnect == false) {
              reconnectingState = true
              connectToDevice()
          }
          callback?.onStatusDevice(mac: _identifer!, status: BluetoothStatus.ConnectDisconnect)
      }
    private func connectToDevice() {
        if reconnectingState {
            if let peripheral = self.peripheral {
                DoctisFetal.activeExecute = true
                manager.connectionDelegate = self
                _identifer = peripheral.identifier
                manager.connectPeripheralDevice(peripheral: peripheral, options: nil)
            }}
    }
    private func resetValue(){
    model = ""
    serial = ""
    startTime = nil
    battLevel = -1
    rateArray.removeAll()
    tocoArray.removeAll()
    stopwatch.stop()
    id = UUID()
    peripheral = nil
    rightDisconnect = false
    reconnectingState = false
    }
    
    //ReadWirteCharteristicDelegate
    internal func bleManagerDidUpdateValueForChar(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
        if let value = characteristic.value {
            if(characteristic.uuid.uuidString == "2A25"){
                if let dataString = String(data: value, encoding: .ascii) {
                   serial = dataString
                    callback?.onExploreDevice(mac: _identifer!, atr: Atributes.SerialNumber, value: dataString)
                } else {
                    // Не удалось преобразовать данные в строку ASCII
                    print("Failed to convert data to ASCII string")
                }
            }
            if(characteristic.uuid.uuidString == "2A24"){
                if let dataString = String(data: value, encoding: .ascii) {
                    model = dataString
                    callback?.onExploreDevice(mac: _identifer!, atr: Atributes.ModelNumber, value: dataString)
                } else {
                    // Не удалось преобразовать данные в строку ASCII
                    print("Failed to convert data to ASCII string")
                }
            }
            if(DoctisFetal.time != 0){
                if(stopwatch.elapsedTimeInSeconds() / 60 > DoctisFetal.time.doubleValue){
                    finishMeasurments()
                }
            }
//            if let decodedValue = decoder.start(withCharacterData: value) {
//                if(DoctisFetal.test == true && stopwatch.elapsedTimeInSeconds() > 10){
//                    finishMeasurments()
//                }
//                if(decodedValue.rate > 0){
//                    rateArray.append(DataItem(key:stopwatch.elapsedTimeInSeconds(),value:decodedValue.rate))
//                    callback?.onExploreDevice(mac: _identifer!, atr: Atributes.HeartRate, value: decodedValue.rate)
//                }
//                if(battLevel == -1){
//                    battLevel = decodedValue.battValue
//                    callback?.onExploreDevice(mac: _identifer!, atr: Atributes.BatteryLevel, value: decodedValue.battValue)
//                }
//                tocoArray.append(DataItem(key:stopwatch.elapsedTimeInSeconds(),value: decodedValue.tocoValue))
//                callback?.onExploreDevice(mac: _identifer!, atr: Atributes.Toco, value: decodedValue.tocoValue)
//            } else {
              
    //        }
        } else {
            print("Characteristic value is nil")
        }

    }
    internal func bleManagerDidWriteValueForChar(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
        print(characteristic)

    }
    
    internal func bleManagerDidUpdateValueForDesc(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?){
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
    }
    
    internal func bleManagerDidWriteValueForDesc(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?){
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
    }
    //Обработчик:
    internal func bleManagerDidUpdateNotificationState(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
        print(characteristic)
        stopwatch.start()
        startTime = Date();
    }
    
    //ServicesDiscoveryDelegate
    internal func bleManagerDiscoverService (_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        } else {
            DeviceService.getInstance().ls.addLogs(text:"No services found")
        }
    }
    internal func bleManagerDiscoverCharacteristics (_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            callback?.onExpection(mac: peripheral.identifier, ex: error)
            return
        }
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print(characteristic.uuid)
                if characteristic.uuid.uuidString == "FED6" {
                    print("uuid=")
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                if(characteristic.uuid.uuidString == "2A25" || characteristic.uuid.uuidString == "2A24"){
                    print(characteristic)
                    peripheral.readValue(for: characteristic)
                }
                
            }
              }
}

    internal func subscribeToCharacteristic(peripheral: CBPeripheral) {
     
    }
    internal func bleManagerDiscoverDescriptors(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    {
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
        DeviceService.getInstance().ls.addLogs(text:"bleManagerDiscoverDescriptors")
    }
    
    internal func setPin(device: CBPeripheral){
        let response: Data = ("pin."+cred!).data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    internal func getRDS(device: CBPeripheral){
        let response: Data = String(format: "rd.%03dd", EltaGlucometr.itter).data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    internal func getDisplay(device: CBPeripheral, char:CBCharacteristic){
        let response: Data = String("ModelNumber").data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    internal func getSerial(device: CBPeripheral, char:CBCharacteristic){
//        let response: Data = String("serial").data(using: .utf8)!
//        manager.writeCharacteristicValue(peripheral: device, data: response, char: char, type: CBCharacteristicWriteType.withResponse)
        manager.subscribeToCharacteristic(peripheral: device, characteristic: char)

    }
    internal func getMac(device: CBPeripheral){
        let response: Data = String("mac").data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    internal func getBattery(device: CBPeripheral){
        let response: Data = String("bat").data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    public func finishMeasurments(){
        if let peripheral = self.peripheral{
            manager.disconnectPeripheralDevice(peripheral: peripheral)
            if let centralManager = manager.centralManager {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            DoctisFetal.activeExecute = false
            rightDisconnect = true
            reconnectingState = false
           // decoder.stopRealTimeAudioPlyer()
           // decoder.stopMoniter()
            DoctisFetal.activeExecute = false
            let sum = tocoArray.reduce(0) { $0 + $1.value }
            let average: Double
            if !tocoArray.isEmpty {
                average = Double(sum) / Double(rateArray.count)
            } else {
                average = 0
            }
            if(average == 10){
                tocoArray.removeAll()
            }
            if rateArray.isEmpty && average == 10{
                callback?.onSendData(mac: _identifer!, status: PlatformStatus.NoDataSend)
            }else {
                if let time = startTime {
                    if DoctisFetal.time != 0 {
                        if stopwatch.elapsedTimeInSeconds() / 60 > DoctisFetal.time.doubleValue {
                            let data = FhirTemplate.FetalMonitor(model: model, id: id, serialNumber: serial, startTime: time, battLevelStart: battLevel, fhrData: rateArray, tocoData: tocoArray, moveDetect: moveArray)!
                            sleep(3)
                            DeviceService.getInstance().im.postResource(data: data, id: id)
                            resetValue()
                        } else {
                            callback?.onSendData(mac: _identifer!, status: PlatformStatus.NoDataSend)
                        }
                    } else {
                        let data = FhirTemplate.FetalMonitor(model: model, id: id, serialNumber: serial, startTime: time, battLevelStart: battLevel, fhrData: rateArray, tocoData: tocoArray, moveDetect: moveArray)!
                 
                        DeviceService.getInstance().im.postResource(data: data, id: id)
                        resetValue()
                    }
                } else {
                    print("ERROR")
                }
            }
        }
    }
    public func addMove(){
        moveArray.append(stopwatch.elapsedTimeInSeconds())
    }
    public func stopReconnecting(){
        if let peripheral = self.peripheral{  manager.disconnectPeripheralDevice(peripheral: peripheral)
            if let centralManager = manager.centralManager {
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
       // decoder.stopRealTimeAudioPlyer()
      //  decoder.stopMoniter()
        DoctisFetal.activeExecute = false
        rightDisconnect = true
        reconnectingState = false
        resetValue()
    }
    public func disconnectDevice(){
        if let peripheral = self.peripheral{  manager.disconnectPeripheralDevice(peripheral: peripheral)
            if let centralManager = manager.centralManager {
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }
    public func reconnectToDevice(){
        if let peripheral = self.peripheral {
            connect(device: peripheral)
        }else{
            DeviceService.getInstance().ls.addLogs(text:"Error: unable to connect")
        }
    }
}
