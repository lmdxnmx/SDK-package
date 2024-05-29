//
//  DeviceService.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 06.06.2023.
//

import Foundation
import CoreBluetooth
import CoreData

fileprivate class _baseCallback: DeviceCallback {
    func onExploreDevice(mac: UUID, atr: Atributes, value: Any){}
    
    func onStatusDevice(mac: UUID, status: BluetoothStatus){ }
    
    func onSendData(mac: UUID, status: PlatformStatus){ }
    
    func onExpection(mac: UUID, ex: Error){ }
    
    func onDisconnect(mac: UUID, data: ([Atributes: Any], Array<Measurements>)){}
    
    func findDevice(peripheral: DisplayPeripheral){}
    
    func searchedDevices(peripherals: [DisplayPeripheral]){}
}

private var instanceDS: DeviceService? = nil

///Основной сервис для взаимодействия с платформой
public class DeviceService {
    internal var deviceService: DeviceService?
    
    internal var _login: String = ""
    
    internal var _password: String = ""
    
    private var _test: Bool = false
    
    internal var im: InternetManager
    internal var rm: ReachabilityManager
    internal var ls: LogService
    private var _callback: DeviceCallback = _baseCallback()
    
    ///Получение экземпляр класса, если до этого он не был иницирован, создаётся пустой объект с базовыми параметрами.
    ///При базовой инициализации login и password - пустые строки, функция обратного вызова, в которой отсутсует любая обработка входящий данных
    public static func getInstance() -> DeviceService {
        if(instanceDS == nil) {
            return DeviceService()
        }
        else{
            return instanceDS!
        }
    }
    
    internal init(){
        if let storedUUIDString = UserDefaults.standard.string(forKey: "instanceId"),
           let storedUUID = UUID(uuidString: storedUUIDString) {
        } else {
            let newUUID = UUID()
            UserDefaults.standard.set(newUUID.uuidString, forKey: "instanceId")
        }
        BLEManager.getSharedBLEManager().initCentralManager(queue: DispatchQueue.global(), options: nil)
        ls = LogService()
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        rm = ReachabilityManager(manager:im)
        instanceDS = self
    }
    
    ///Создание объекта с указанием авторизационных данных и функции обратного вызова для получения текущего состояния работы сервиса
    public init(login: String, password: String, callbackFunction: DeviceCallback? = nil, debug: Bool) {
        BLEManager.getSharedBLEManager().initCentralManager(queue: nil, options: nil)
        _login = login
        _password = password
        _callback = callbackFunction ?? _baseCallback()
        _test = debug
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        rm = ReachabilityManager(manager: im)
        ls = LogService()
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        let logs = """
        \(timestamp) Параметры конфигурации сервиса:
        SDK инициализировано с следующими параметрами:
        Login: \(_login)
        Password: \(_password)
        Callback: \(callbackFunction != nil ? "is not nil" : "nil")
        Платформа: \(_test ? "https://test.ppma.ru" : "https://ppma.ru")
        """
        ls.addLogs(text: logs)
        instanceDS = self
    }
    
    ///Изменение авторизационных данных при работе сервиса
    public func changeCredentials(login: String, password: String){
        _login = login
        _password = password
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        rm = ReachabilityManager(manager:im)
        instanceDS = self
    }
    
    ///Изменение функции обратного вызова
    public func changeCallback(callbackFunction: DeviceCallback){
        _callback = callbackFunction
    }
    
    ///Организация подключения к устройству.
    ///При подключение к переферийному устройству, требуется шаблонный класс для подключения и объект найденнного устройства
    public func connectToDevice(connectClass: ConnectClass, device: DisplayPeripheral){
        connectClass.callback = self._callback
        let _identifier: UUID = device.peripheral!.identifier
        if(connectClass is AndTonometr){
            if(!AndTonometr.activeExecute) {
                DispatchQueue.global().async {
                    connectClass.connect(device: device.peripheral!)
                }
            }
            else {
                self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.Connected)
            }
            return
        }
        if(connectClass is EltaGlucometr){
            if(connectClass.cred == nil){
                self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.NotCorrectPin)
            }else{
                if(!EltaGlucometr.activeExecute) {
                    DispatchQueue.global().async {
                        connectClass.connect(device: device.peripheral!)
                    }
                }
                else {
                    self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.Connected)
                }
            }
            return
        }
        if(connectClass is DoctisFetal){
                 if(!DoctisFetal.activeExecute){
                     DispatchQueue.global().async {
                         connectClass.connect(device: device.peripheral!)
                         DoctisFetal.time = 0
                     }
                 }
                 return
             }
        self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.InvalidDeviceTemplate)
    }
    
    public func connectToDevice(connectClass: ConnectClass, device: DisplayPeripheral, mail: String){
        connectClass.callback = self._callback
        let _identifier: UUID = device.peripheral!.identifier
        if(connectClass is AndTonometr){
            if(!AndTonometr.activeExecute) {
                DispatchQueue.global().async {
                    connectClass.connect(device: device.peripheral!)
                }
            }
            else {
                self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.Connected)
            }
            return
        }
        if(connectClass is EltaGlucometr){
            if(connectClass.cred == nil){
                self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.NotCorrectPin)
            }else{
                if(!EltaGlucometr.activeExecute) {
                    DispatchQueue.global().async {
                        EltaGlucometr.mail = mail;
                        connectClass.connect(device: device.peripheral!)
                    }
                }
                else {
                    self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.Connected)
                }
            }
            return
        }
        if(connectClass is DoctisFetal){
                 if(!DoctisFetal.activeExecute){
                     DispatchQueue.global().async {
                         connectClass.connect(device: device.peripheral!)
                         DoctisFetal.time = 0
                     }
                 }
                 return
             }
        self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.InvalidDeviceTemplate)
    }
    public func connectToDevice(connectClass: ConnectClass, device: DisplayPeripheral, test: Bool){
        connectClass.callback = self._callback
        let _identifier: UUID = device.peripheral!.identifier
        if(connectClass is AndTonometr){
            if(!AndTonometr.activeExecute) {
                DispatchQueue.global().async {
                    connectClass.connect(device: device.peripheral!)
                }
            }
            else {
                self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.Connected)
            }
            return
        }
        if(connectClass is EltaGlucometr){
            if(connectClass.cred == nil){
                self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.NotCorrectPin)
            }else{
                if(!EltaGlucometr.activeExecute) {
                    DispatchQueue.global().async {
                        connectClass.connect(device: device.peripheral!)
                    }
                }
                else {
                    self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.Connected)
                }
            }
            return
        }
        if(connectClass is DoctisFetal){
                 if(!DoctisFetal.activeExecute){
                     DispatchQueue.global().async {
                         DoctisFetal.test = test
                         connectClass.connect(device: device.peripheral!)
                         DoctisFetal.time = 0
                     }
                 }
                 return
             }
        self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.InvalidDeviceTemplate)
    }
    public func connectToDevice(connectClass: ConnectClass, device: DisplayPeripheral, time: Int){
        connectClass.callback = self._callback
        let _identifier: UUID = device.peripheral!.identifier
        if(connectClass is DoctisFetal){
                 if(!DoctisFetal.activeExecute){
                     DispatchQueue.global().async {
                         DoctisFetal.time = time
                         connectClass.connect(device: device.peripheral!)
                     }
                 }
                 return
             }
        self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.InvalidDeviceTemplate)
    }
    ///Поиск ble устройств, конечный список записывается в шаблон для подключения
    public func search(connectClass: ConnectClass, timeOut: UInt32){
        DispatchQueue.global().async {
            connectClass.callback = self._callback
            connectClass.search(timeout: timeOut)
        }
    }
    
    public func applyObservation(connectClass: ConnectClass, serial: String, model: String, time: Date, value: Double) {
        guard let instanceDS = instanceDS else { return }
        guard connectClass is EltaGlucometr else { return }
        
        // Получаем дату из UserDefaults
        if let savedDate = UserDefaults.standard.object(forKey: serial) as? Date {
            // Сравниваем даты
            if time > savedDate {
                // Делаем запрос
                let identifier = UUID()
                let jsonString = String(data: FhirTemplate.Glucometer(serial: serial, model: model, effectiveDateTime: time, value: value)!, encoding: .utf8)
                
                let context = CoreDataStack.shared.viewContext
                let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "title == %@", identifier as CVarArg)
                do {
                    let existingEntities = try context.fetch(fetchRequest)
                    if existingEntities.isEmpty {
                        let newTask = Entity(context: context)
                        newTask.title = identifier
                        newTask.body = jsonString
                        newTask.deviceType = "EltaGlucometer"
                        do {
                            try context.save()
                        } catch {
                            DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                        }
                    }
                } catch {
                    DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                }
                
                // Обновляем дату в UserDefaults
                UserDefaults.standard.set(time, forKey: serial)
            }else{
                DeviceService.getInstance().ls.addLogs(text:"Эти измерения уже были")
            }
        } else {
            // Если дата отсутствует в UserDefaults, записываем её и выходим из функции
            UserDefaults.standard.set(time, forKey: serial)
        }
    }
    public func applyObservation(connectClass: ConnectClass,id:UUID ,serial: String, model: String, time: Date, value: Double) {
        guard let instanceDS = instanceDS else { return }
        guard connectClass is EltaGlucometr else { return }
        
        // Получаем дату из UserDefaults
        if let savedDate = UserDefaults.standard.object(forKey: serial) as? Date {
            // Сравниваем даты
            if time > savedDate {
                // Делаем запрос
                let identifier = UUID()
                if let glucometerData = FhirTemplate.Glucometer(serial: serial, id: id, model: model, effectiveDateTime: time, value: value),
                   let jsonString = String(data: glucometerData, encoding: .utf8) {
                    
                    let context = CoreDataStack.shared.viewContext
                    let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "title == %@", id as CVarArg)
                    do {
                        let existingEntities = try context.fetch(fetchRequest)
                        if existingEntities.isEmpty {
                            let newTask = Entity(context: context)
                            newTask.title = id
                            newTask.body = jsonString
                            newTask.deviceType = "EltaGlucometer"
                            do {
                                try context.save()
                            } catch {
                                DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                            }
                        }
                    } catch {
                        DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                    }
                    
                    // Обновляем дату в UserDefaults
                    UserDefaults.standard.set(time, forKey: serial)
                }
            }else{
                DeviceService.getInstance().ls.addLogs(text:"Эти измерения уже были")
            }
        } else {
            // Если дата отсутствует в UserDefaults, записываем её и выходим из функции
            UserDefaults.standard.set(time, forKey: serial)
        }
    }
    public func applyObservation(connectClass: ConnectClass, observations: [(id: UUID, serial: String, model: String, time: Date, value: Double)]) {
        guard let instanceDS = instanceDS else { return }

        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Entity")
        fetchRequest.returnsObjectsAsFaults = false
        var entitiesToSave: [Entity] = [] // Массив для хранения объектов, которые нужно сохранить

        guard let firstObservation = observations.first else { return }
        var largestTime: Date? = firstObservation.time // Переменная для хранения наибольшего времени
        let savedDate = UserDefaults.standard.object(forKey: firstObservation.serial) as? Date

        // Флаг для отслеживания необходимости сохранения контекста
        var needsSave = false

        if savedDate != nil {
            for observation in observations {
                let (id, serial, model, time, value) = observation

                // Проверяем, что время наблюдения больше времени, хранящегося в UserDefaults для данного серийного номера
                if let savedDate = savedDate, time > savedDate {
                    if connectClass is EltaGlucometr {
                        if let glucometerData = FhirTemplate.Glucometer(serial: serial, id: id, model: model, effectiveDateTime: time, value: value),
                            let jsonString = String(data: glucometerData, encoding: .utf8) {
                            let entity = Entity(context: backgroundContext)
                            entity.title = id
                            entity.body = jsonString
                            entity.deviceType = "EltaGlucometer"
                            entitiesToSave.append(entity)

                            if let currentLargestTime = largestTime, time > currentLargestTime {
                                largestTime = time
                            }
                            // Устанавливаем флаг, что требуется сохранение
                            needsSave = true
                        }
                    }
                }
            }
            UserDefaults.standard.set(largestTime, forKey: firstObservation.serial)
        }

        // Если времени в UserDefaults нет, отправляем все измерения и устанавливаем время для последнего измерения как время в UserDefaults
        if savedDate == nil {
            for observation in observations {
                let (id, serial, model, time, value) = observation
                if connectClass is EltaGlucometr {
                    if let jsonString = String(data: FhirTemplate.Glucometer(serial: serial, id: id, model: model, effectiveDateTime: time, value: value)!, encoding: .utf8) {
                        let entity = Entity(context: backgroundContext)
                        entity.title = id
                        entity.body = jsonString
                        entitiesToSave.append(entity)
                        if let currentLargestTime = largestTime, time > currentLargestTime {
                            largestTime = time
                        }
                        // Устанавливаем флаг, что требуется сохранение
                        needsSave = true
                    }
                }
            }
            // Устанавливаем время для последнего измерения как время в UserDefaults
            UserDefaults.standard.set(largestTime, forKey: firstObservation.serial)
        }

        if needsSave {
            // Сохраняем все объекты из массива в контекст CoreData
            backgroundContext.perform {
                do {
                    try backgroundContext.save()
                } catch {
                    DeviceService.getInstance().ls.addLogs(text: "Ошибка сохранения: \(error.localizedDescription)")
                }
            }
        }
    }

    
    
    public func getLogs() -> [Logs] {
        return ls.getLogs()
    }
    
    
    ///Отправка данных будет производиться на тестовую площадку <test.ppma.ru>
    public func toTest() {
        _test = true
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        rm = ReachabilityManager(manager:im)
        instanceDS = self
    }
    ///Отправка данных будет производиться на основную площадку <ppma.ru>
    public func toProd() {
        _test = false
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        rm = ReachabilityManager(manager:im)
        instanceDS = self
    }
    public func getCountOfEntities() -> Int {
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<Logs> = Logs.fetchRequest()
        do {
            // Выполняем запрос fetch и получаем массив объектов
            let results = try context.fetch(fetchRequest)
            
            // Получаем количество объектов в массиве
            let count = results.count
            return count
        } catch {
            DeviceService.getInstance().ls.addLogs(text:"Ошибка при выполнении запроса fetch: \(error)")
            return 0
        }
        return 0;
    }
    public func sendLogs(){
        ls.sendLogs();
    }
    public func clearLogs(){
        ls.clearLogsFromCoreData();
    }
    public func finishMeasurments(){
        DoctisFetal.shared.finishMeasurments()
    }
}
    ///Структура для сохранения информации об устройтсве
    public struct DisplayPeripheral: Hashable {
        public var peripheral: CBPeripheral?
        public var lastRSSI: NSNumber?
        public var isConnectable: Bool?
        public var localName: String?
        
        public func hash(into hasher: inout Hasher) { }
        
        public static func == (lhs: DisplayPeripheral, rhs: DisplayPeripheral) -> Bool {
            if (lhs.peripheral! == rhs.peripheral) { return true }
            else { return false }
        }
        public init(peripheral: CBPeripheral? = nil, lastRSSI: NSNumber? = nil, isConnectable: Bool? = false, localName: String? = nil) {
            self.peripheral = peripheral
            self.lastRSSI = lastRSSI
            self.isConnectable = isConnectable
            self.localName = localName
        }
    }
    
    ///Структура для сохранения данных об измерениях
    public struct Measurements{
        internal var data: [Atributes: Any] = [:]
        
        init() {
            data = [Atributes: Any]()
        }
        
        public mutating func add(atr: Atributes, value: Any){
            data.updateValue(value, forKey: atr)
        }
        
        public func get() -> [Atributes: Any]?{
            return data
        }
        
        public func get(atr: Atributes) -> Any?{
            return data[atr]
        }
    }

