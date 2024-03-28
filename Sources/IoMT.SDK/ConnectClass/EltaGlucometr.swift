//
//  Elta.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 04.07.2023.
//

import Foundation
import CoreBluetooth
import CommonCrypto

extension String {
    var md5: [UInt8] {
        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = Array<UInt8>(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        
        CC_MD5_Init(context)
        CC_MD5_Update(context, self, CC_LONG(lengthOfBytes(using: .utf8)))
        CC_MD5_Final(&digest, context)
        
        context.deallocate()
        
        return digest
    }
}
extension UUID{
    init?(md5 bytes: [UInt8]) {
        guard
            bytes.count == CC_MD5_DIGEST_LENGTH
        else { return nil }
        
        var bytes = bytes
        bytes[6] &= 0x0f
        bytes[6] |= 0x30
        bytes[8] &= 0x3f
        bytes[8] |= 0x80
        
        let uuid = (
            bytes[0],  bytes[1],  bytes[2],  bytes[3],
            bytes[4],  bytes[5],  bytes[6],  bytes[7],
            bytes[8],  bytes[9],  bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )
        
        self.init(uuid: uuid)
    }
}
public class EltaGlucometr:
    ConnectClass,
    DeviceScaningDelegate,
    DeviceConnectionDelegate,
    ServicesDiscoveryDelegate,
    ReadWirteCharteristicDelegate{
    
    
    internal var _identifer: UUID?
    internal var _mac:String?
    var peripheral: CBPeripheral?
    var serial:String = "";
    static var mail:String = "";
    public var peripherals: [DisplayPeripheral] = []
    
    static var itter:Int = 0
    
    internal var rxtxService: CBService?
    
    internal var rxCharacteistic: CBCharacteristic?
    
    internal var txCharacteistic: CBCharacteristic?
    
    internal var internetManager: InternetManager = InternetManager.getManager()
    
    internal var measurements: Collector?
    var disconnectTimer: Timer? = nil
    public static var lastDateMeasurements: Date? = nil
    
    internal static let FormatPlatformTime: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.formatOptions = [.withInternetDateTime]
        return dateFormatter
    }()
    
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
        EltaGlucometr.activeExecute = true
        manager.connectionDelegate = self
        _identifer = device.identifier
        manager.connectPeripheralDevice(peripheral: device, options: nil)
        EltaGlucometr.activeExecute = false
    }

    
    override public func search(timeout: UInt32) {
        manager.scaningDelegate = self
        manager.scanAllDevices()
        print("START SEARCH")
        sleep(timeout)
        manager.stopScan()
        callback?.searchedDevices(peripherals: peripherals)
    }
    //DeviceScaningDelegate
    internal func scanningStatus(status: Int) {
        DeviceService.getInstance().ls.addLogs(text:String(describing:status))
    }
    func startDisconnectTimer() {
        stopDisconnectTimer()
        guard let peripheral = self.peripheral else {
            return
        }
        disconnectTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            self?.manager.disconnectPeripheralDevice(peripheral: peripheral)
            if let centralManager = self?.manager.centralManager {
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }

     func stopDisconnectTimer() {
         disconnectTimer?.invalidate()
         disconnectTimer = nil
     }

     func resetDisconnectTimer() {
         stopDisconnectTimer()
         startDisconnectTimer()
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
        callback?.onExpection(mac: _identifer!, ex: error!)
        
    }
    
    // This method will be triggered once device will be connected.
    internal func bleManagerDidConnect(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        manager.discoveryDelegate = self
        manager.readWriteCharDelegate = self
        callback?.onStatusDevice(mac: _identifer!, status: BluetoothStatus.ConnectStart)
        peripheral.discoverServices(nil)
        self.peripheral = peripheral
        EltaGlucometr.itter = 0
        self.measurements = Collector()
        self.startDisconnectTimer()
    }
    
    // This method will be triggered once device will be disconnected.
    internal func bleManagerDisConect(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
        self.stopDisconnectTimer()
        callback?.onStatusDevice(mac: _identifer!, status: BluetoothStatus.ConnectDisconnect)
        var observations: [(id:UUID,serial: String, model: String, time: Date, value: Double)] = []
        if(self.measurements == nil) { return; }
        let ret = self.measurements?.returnData()
        callback?.onDisconnect(mac: peripheral.identifier, data: ret!)
        DispatchQueue.global().async {
            sleep(5)
            
            if let serial = self.measurements!.returnCharateristic(atribute: Atributes.SerialNumber) as? String,let model =  self.measurements!.returnCharateristic(atribute: Atributes.ModelNumber) as? String{
                var measurements: Array<Measurements>
                measurements = (self.measurements?.returnMeasurements() as? Array<Measurements>)!
                for measurement in measurements {
                    let time = measurement.get(atr: Atributes.TimeStamp) as! Date
                    let value = measurement.get(atr: Atributes.Glucose) as! Double
                    let idTime = EltaGlucometr.FormatDeviceTime.string(from:time)
                    if(EltaGlucometr.mail != ""){
                        if let mac = self._mac {
                            let concatenatedString = (EltaGlucometr.mail + mac + "\(idTime)").lowercased()
                            let uuid = UUID(md5: concatenatedString.md5)
                            let observation = (id:uuid!,serial: serial, model: model, time: time, value: value)
                            observations.append(observation)
                        }
                    }
                    else{
                        let observation = (id:UUID(),serial: serial, model: model, time: time, value: value)
                        observations.append(observation)
                    }
                }
                
                DeviceService.getInstance().applyObservation(connectClass: EltaGlucometr(), observations: observations)
                
                if(measurements.count == 0){
                    self.callback?.onSendData(mac: peripheral.identifier, status: PlatformStatus.NoDataSend)
                }
            }else{
                self.callback?.onSendData(mac: peripheral.identifier, status: PlatformStatus.Failed)
    }}
            
            
        
    }
    
    //ReadWirteCharteristicDelegate
    internal func bleManagerDidUpdateValueForChar(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
        if(EltaGlucometr.itter > 999){
            manager.disconnectPeripheralDevice(peripheral: peripheral)
            if let centralManager = manager.centralManager {
                centralManager.cancelPeripheralConnection(peripheral)
            } else {
                print("Central manager is nil")
            }
            EltaGlucometr.activeExecute = false
            print("Disconnected by itter > 999")
            return
        }
        if let resultStr = String(data: characteristic.value!, encoding: .utf8) {
            if(resultStr.contains("enter pincode first")){
                callback?.onStatusDevice(mac: peripheral.identifier, status: BluetoothStatus.NotCorrectPin)
                manager.disconnectPeripheralDevice(peripheral: peripheral)
            }
            if(resultStr.starts(with: "ser.")){
                serial = resultStr.replacingOccurrences(of: "ser.", with: "")
                if(UserDefaults.standard.object(forKey: serial) == nil){
                    getLastTime(serial: serial)
                    sleep(2)
                }
                callback?.onExploreDevice(mac: peripheral.identifier, atr: Atributes.SerialNumber, value: serial)
                self.measurements!.addInfo(atr: Atributes.SerialNumber, value: serial)
            }
            if(resultStr.starts(with: "mac.")){
                _mac = formatMACAddress(resultStr.replacingOccurrences(of: "mac.", with: ""))
            }
            if(resultStr.starts(with: "b")){
                let data = resultStr.replacingOccurrences(of: "b", with: "").replacingOccurrences(of: "t", with: "").split(separator: ".")
                callback?.onExploreDevice(mac: peripheral.identifier, atr: Atributes.BatteryLevel, value: data[0])
                self.measurements!.addInfo(atr: Atributes.BatteryLevel, value: data[0])
                callback?.onExploreDevice(mac: peripheral.identifier, atr: Atributes.Temperature, value: data[1])
                self.measurements!.addInfo(atr: Atributes.Temperature, value: data[1])
            }
            if(resultStr.starts(with: "rd")){
                let measurement = resultStr.replacingOccurrences(of: "rd", with: "")
                if measurement.replacingOccurrences(of: "0", with: "").count == 0 {
                    manager.disconnectPeripheralDevice(peripheral: peripheral)
                    if let centralManager = manager.centralManager {
                        centralManager.cancelPeripheralConnection(peripheral)
                    } else {
                        print("Central manager is nil")
                    }
                    EltaGlucometr.activeExecute = false
                    print("Disconnected by rd0")
                    return
                }
                let dateStr: String = String(measurement.prefix(12))
                let start = measurement.index(measurement.startIndex, offsetBy: 12)
                let end = measurement.index(measurement.startIndex, offsetBy: 15)
                let temperatureStr: String = String(measurement[start...end])
                let valueStr: String = String(measurement.suffix(from: measurement.index(measurement.startIndex, offsetBy: 15)))
                
                var m = Measurements()
                let timeStamp = EltaGlucometr.FormatDeviceTime.date(from: dateStr)!
                callback?.onExploreDevice(mac: peripheral.identifier, atr: Atributes.TimeStamp, value: timeStamp)
                m.add(atr: Atributes.TimeStamp, value: timeStamp)
                if(serial != ""){
                    let savedDate = UserDefaults.standard.object(forKey: serial) as? Date

                    if let savedDate = savedDate, savedDate >= timeStamp {
                        manager.disconnectPeripheralDevice(peripheral: peripheral)
                        if let centralManager = manager.centralManager {
                            centralManager.cancelPeripheralConnection(peripheral)
                        } else {
                            print("Central manager is nil")
                        }
                        EltaGlucometr.activeExecute = false
                        print("Disconnected by cacheData")
                        return
                    }
                }
                let temperature: Double = Double(temperatureStr)! / 10
                callback?.onExploreDevice(mac: peripheral.identifier, atr: Atributes.Temperature, value: temperature)
                m.add(atr: Atributes.Temperature, value: temperature)
                
                let value: Double = Double(valueStr)! / 10
                callback?.onExploreDevice(mac: peripheral.identifier, atr: Atributes.Glucose, value: value)
                m.add(atr: Atributes.Glucose, value: value)
                
                self.measurements!.addMeasurements(Object: m)
                EltaGlucometr.itter += 1
                getRDS(device: peripheral)
                resetDisconnectTimer()
            }
        }
    }
    
    internal func bleManagerDidWriteValueForChar(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
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
    internal func bleManagerDiscoverCharacteristics (_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
        rxtxService = service
        rxCharacteistic = rxtxService!.characteristics![0]
        txCharacteistic = rxtxService!.characteristics![1]
        peripheral.setNotifyValue(true, for: txCharacteistic!)
        setPin(device: peripheral)
        getMac(device: peripheral)
        getSerial(device: peripheral)
        getDisplay(device: peripheral)
        setTime(device: peripheral)
        getBattery(device: peripheral)
        getRDS(device: peripheral)
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
    
    internal func getDisplay(device: CBPeripheral){
        let modelNumber = "SatelliteOnline"
        self.measurements!.addInfo(atr: Atributes.ModelNumber, value: modelNumber)
        callback?.onExploreDevice(mac: device.identifier, atr: Atributes.ModelNumber, value: modelNumber)
    }
    
    internal func getSerial(device: CBPeripheral){
        let response: Data = String("serial").data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    internal func getMac(device: CBPeripheral){
        let response: Data = String("mac").data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    internal func setTime(device: CBPeripheral){
        let timeNow = Date()
        let time = EltaGlucometr.FormatDeviceTime.string(from: timeNow)
        DeviceService.getInstance().ls.addLogs(text:"Settime: " + String(describing:time))
        let response: Data = String("settime." + time).data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    internal func getBattery(device: CBPeripheral){
        let response: Data = String("bat").data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    
}

