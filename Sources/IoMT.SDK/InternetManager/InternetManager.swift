import Foundation
import CoreData

private var sharedManager: InternetManager? = nil

fileprivate class _baseCallback: DeviceCallback {
    func onExploreDevice(mac: UUID, atr: Atributes, value: Any){}
    
    func onStatusDevice(mac: UUID, status: BluetoothStatus){ }
    
    func onSendData(mac: UUID, status: PlatformStatus){ }
    
    func onExpection(mac: UUID, ex: Error){ }
    
    func onDisconnect(mac: UUID, data: ([Atributes: Any], Array<Measurements>)){}
    
    func findDevice(peripheral: DisplayPeripheral){}
    
    func searchedDevices(peripherals: [DisplayPeripheral]){}
}


 class InternetManager{
    internal var baseAddress: String
    //Url's variabls
    internal var urlGateWay: URL
    //Encoded login/password
    internal var auth: String
    internal var sdkVersion: String?
    internal var instanceId:UUID
    internal var callback: DeviceCallback
    
    static internal func getManager () -> InternetManager {
        if sharedManager == nil {
                   sharedManager = InternetManager(login: "", password: "", debug: true, callback: _baseCallback())
        }
        return sharedManager!
    }
    var timer: Timer? = nil
    var interval: TimeInterval = 1
     private var isSavingContext = false;
     private var timerIsScheduled = false
    
     internal init(login: String, password: String, debug: Bool, callback: DeviceCallback) {
        self.auth = Data((login + ":" + password).utf8).base64EncodedString()
        if(!debug){
            baseAddress = "https://ppma.ru"
        }
        else{ baseAddress = "https://test.ppma.ru" }
        self.urlGateWay = URL(string: (self.baseAddress))!
        self.callback = callback
        self.sdkVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
         if let storedUUIDString = UserDefaults.standard.string(forKey: "instanceId"),
            let storedUUID = UUID(uuidString: storedUUIDString) {
             self.instanceId = storedUUID
         }else {
             let newUUID = UUID()
             UserDefaults.standard.set(newUUID.uuidString, forKey: "instanceId")
             self.instanceId = newUUID
         }
        sharedManager = self
         let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
         backgroundContext.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
         NotificationCenter.default.addObserver(self, selector: #selector(contextDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
    }
     let dispatchGroup = DispatchGroup()
     @objc func contextDidChange(_ notification: Notification) {
         guard !isSavingContext else {
                    // Пропускаем сохранение, если уже происходит сохранение контекста
                    return
                }

                // Установим флаг перед сохранением контекста
                isSavingContext = true
                defer {
                    // Сбрасываем флаг после сохранения контекста, чтобы разрешить следующее сохранение
                    isSavingContext = false
                }

             guard let userInfo = notification.userInfo else { return }

         let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
         backgroundContext.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator

             var updatedObjects: [NSManagedObject] = []
             var insertedObjects: [NSManagedObject] = []
             var deletedObjects: [NSManagedObject] = []

             if let updatedSet = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                 updatedObjects = Array(updatedSet)
             }
             if let insertedSet = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> {
                 insertedObjects = Array(insertedSet)
             }
             if let deletedSet = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> {
                 deletedObjects = Array(deletedSet)
             }

             for object in insertedObjects {
                 guard let entity = object.entity as? NSEntityDescription, entity.name == "Entity" else {
                     continue
                 }
                 // Действия, если объект типа Entity
                 if self.timer == nil && self.isCoreDataNotEmpty() && !self.timerIsScheduled {
                     // Отмечаем, что таймер уже запланирован
                     self.timerIsScheduled = true
                     
                     // Отменяем предыдущий таймер, если он существует
                     self.stopTimer()
                     
                     // Создаем и запускаем таймер только если его нет
                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                         self.timer = Timer.scheduledTimer(timeInterval: self.interval, target: self, selector: #selector(self.sendDataToServer), userInfo: nil, repeats: false)
                         self.timerIsScheduled = false // Сбрасываем флаг после создания таймера
                     }
                     
                     // Выходим из цикла после создания первого таймера
                     break
                 }
             }

             for object in deletedObjects {
                 guard let entity = object.entity as? NSEntityDescription, entity.name == "Entity" else {
                     continue
                 }
                 
                 // Действия, если объект типа Entity
                 if !self.isCoreDataNotEmpty() && self.timer != nil {
                     self.stopTimer()
                     self.interval = 1
                 }
             }

             do {
                 try backgroundContext.save()
             } catch {
                 print("Failed to save context: \(error)")
             }
         }

     func getDocumentsDirectory() -> URL {
         let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
         return paths[0]
     }
    func isCoreDataNotEmpty() -> Bool {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        
        do {
            let count = try backgroundContext.count(for: fetchRequest)
            return count > 0
        } catch {
            DeviceService.getInstance().ls.addLogs(text:"Ошибка при получении объектов из Core Data: \(error)")
            return false
        }
    }
    func stopTimer() {

        self.timer?.invalidate()
        self.timer = nil
    }
    func increaseInterval(){
            self.stopTimer()
            self.interval = interval*2
            self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(sendDataToServer), userInfo: nil, repeats: false)
    
    }
    func dropTimer(){
        if(isCoreDataNotEmpty()){
            self.stopTimer()
            self.interval = 1
            DeviceService.getInstance().ls.addLogs(text:"Таймер сброшен")
            self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(sendDataToServer), userInfo: nil, repeats: false)
        }
    }

    
    internal func postResource(identifier: UUID, data: Data) {

        let timeUrl  = URL(string: (self.baseAddress + "/gateway/iiot/api/Observation/data"))!
        print(timeUrl)
        var urlRequest: URLRequest = URLRequest(url: timeUrl)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Basic " + self.auth, forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("I2024-03-20T10:12:22Z", forHTTPHeaderField: "SDK-VERSION")
        urlRequest.addValue("Id " + self.instanceId.uuidString, forHTTPHeaderField: "InstanceID")
        //urlRequest
        urlRequest.httpBody = data
        let jsonString = String(data: data, encoding: .utf8)
    
        
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                self.callback.onExpection(mac: identifier, ex: error)
                DeviceService.getInstance().ls.addLogs(text:"Error: \(error)")
                let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                context.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
                let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "title == %@", identifier as CVarArg)
                do{
                    let existingEntities = try context.fetch(fetchRequest)
                    if existingEntities.isEmpty {
                        // Нет существующих объектов с таким же идентификатором, поэтому добавляем новый объект
                        let newTask = Entity(context: context)
                        newTask.title = identifier
                        newTask.body = jsonString
                        newTask.deviceType = "EltaGlucometer"
                        do {
                            try context.save()
                        } catch {
                            DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                        }}}catch{
                            DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                    }
            }
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if(statusCode <= 202){


                    self.callback.onSendData(mac: identifier, status: PlatformStatus.Success)

                    
                }
                else{
                    if(statusCode != 400 && statusCode != 401  && statusCode != 403){
                        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                        context.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
                        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "title == %@", identifier as CVarArg)
                        do{
                        let existingEntities = try context.fetch(fetchRequest)
                        for entity in existingEntities {
                            DeviceService.getInstance().ls.addLogs(text:"Title: \(entity.title?.uuidString ?? "No title"), JSON Body: \(entity.body ?? "No body")")
                            
                        }
                        if existingEntities.isEmpty {
                            // Нет существующих объектов с таким же идентификатором, поэтому добавляем новый объект
                            let newTask = Entity(context: context)
                            newTask.title = identifier
                            newTask.body = jsonString
                            newTask.deviceType = "EltaGlucometer"
                            do {
                                try context.save()
                            } catch {
                                DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                            }}}catch{
                                DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                            }
                }
                    self.callback.onSendData(mac: identifier, status: PlatformStatus.Failed)
                }
            }
            if let responseData = data {
                if let responseString = String(data: responseData, encoding: .utf8) {
                    DeviceService.getInstance().ls.addLogs(text:"Response: \(responseString)")
                }
            }
        }
        task.resume()
    }
     internal func postResource(data: Data, id:UUID) {
         self.dispatchGroup.enter()
        let timeUrl  = URL(string: (self.baseAddress + ":/fetal/iiot/api/Observation/data"))!
        print(timeUrl)
        var urlRequest: URLRequest = URLRequest(url: timeUrl)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Basic " + self.auth, forHTTPHeaderField: "Authorization")
        urlRequest.addValue("I2024-03-20T10:12:22Z", forHTTPHeaderField: "SDK-VERSION")
        urlRequest.addValue("Id " + self.instanceId.uuidString, forHTTPHeaderField: "InstanceID")
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = data
        let jsonString = String(data: data, encoding: .utf8)
        var result = urlRequest.allHTTPHeaderFields;
        
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                self.callback.onExpection(mac: id, ex: error)
                
                DeviceService.getInstance().ls.addLogs(text:"Error: \(error)")
                let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                context.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
                let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "title == %@", id as CVarArg)
                do{
                    let existingEntities = try context.fetch(fetchRequest)
                    if existingEntities.isEmpty {
                        // Нет существующих объектов с таким же идентификатором, поэтому добавляем новый объект
                        let newTask = Entity(context: context)
                        newTask.title = id
                        newTask.body = jsonString
                        newTask.deviceType = "DoctisFetal"
                        do {
                            try context.save()
                        } catch {
                            DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                        }}}catch{
                        DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                    }
            }
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                print(statusCode)
                if(statusCode <= 202 || statusCode == 401 || statusCode == 403 || statusCode == 400 || statusCode == 207){
                    if(statusCode <= 202 || statusCode == 207){
                        self.postFile(id: id)
                    }
                    let backgroundQueue = DispatchQueue.global(qos: .background)
                    backgroundQueue.async {
                        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                        backgroundContext.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator

                        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Entity")
                        fetchRequest.returnsObjectsAsFaults = false
                        fetchRequest.predicate = NSPredicate(format: "deviceType == %@", "DoctisFetal" as CVarArg)
                        fetchRequest.predicate = NSPredicate(format: "title == %@", id as CVarArg)
                        do {
                            let results = try backgroundContext.fetch(fetchRequest)
                            for object in results {
                                guard let objectData = object as? NSManagedObject else { continue }
                                guard objectData.managedObjectContext == backgroundContext else { continue }
                                backgroundContext.delete(objectData)
                            }
                            try backgroundContext.save()

                            self.stopTimer()
                            self.interval = 1
                        } catch let error {
                            print("Delete all data error :", error)
                        }
                    }
                       
                       // Вызов колбэка
                       self.callback.onSendData(mac: id, status: PlatformStatus.Success)
                   }
                else{
                    if(statusCode != 400 && statusCode != 401  && statusCode != 403){
                        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                        context.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
                        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "title == %@", id as CVarArg)
                        do{
                        let existingEntities = try context.fetch(fetchRequest)
                        for entity in existingEntities {
                            DeviceService.getInstance().ls.addLogs(text:"Title: \(entity.title?.uuidString ?? "No title"), JSON Body: \(entity.body ?? "No body")")
                            
                        }
                        if existingEntities.isEmpty {
                            // Нет существующих объектов с таким же идентификатором, поэтому добавляем новый объект
                            let newTask = Entity(context: context)
                            newTask.title = id
                            newTask.body = jsonString
                            newTask.deviceType = "DoctisFetal"
                            do {
                                try context.save()
                            } catch {
                                DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                            }}}catch{
                                DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                            }
                }
                    self.callback.onSendData(mac: id, status: PlatformStatus.Failed)
                }
            }
            if let responseData = data {
                if let responseString = String(data: responseData, encoding: .utf8) {
                    DeviceService.getInstance().ls.addLogs(text:"Response: \(responseString)")
                }
            }
            self.dispatchGroup.leave()
        }
        task.resume()
    }
     internal func postFile(id: UUID) {
         let timeUrl = URL(string: (self.baseAddress + "/fetal/iiot/api/Observation/audio"))!
         let documentsDirectory = getDocumentsDirectory()
         let filePath = documentsDirectory.appendingPathComponent(id.uuidString).appendingPathExtension("mp3")
         let fileUrl = URL(fileURLWithPath: filePath.path)
             var urlRequest = URLRequest(url: timeUrl)
             urlRequest.httpMethod = "POST"
             urlRequest.addValue("Basic " + self.auth, forHTTPHeaderField: "Authorization")
             urlRequest.addValue("I2024-03-20T10:12:22Z", forHTTPHeaderField: "SDK-VERSION")
             urlRequest.addValue("Id " + self.instanceId.uuidString, forHTTPHeaderField: "InstanceID")
             let boundary = "Boundary-\(UUID().uuidString)"
             urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
             var body = Data()
             let idString = "\(id.uuidString)\r\n"
             if let idData = idString.data(using: .utf8) {
                 body.append(contentsOf: "--\(boundary)\r\n".data(using: .utf8)!)
                 body.append(contentsOf: "Content-Disposition: form-data; name=\"id\"\r\n\r\n".data(using: .utf8)!)
                 body.append(idData)
             }

                 let fileManager = FileManager.default
                     do {
                         // Читаем данные из файла
                         let fileData = try Data(contentsOf: fileUrl)

                         // Добавляем заголовок файла к телу запроса
                         if let fileHeaderData = "--\(boundary)\r\nContent-Disposition: form-data; name=\"audio\"; filename=\"\(id)\"\r\nContent-Type: audio/mp3\r\n\r\n".data(using: .utf8),
                            let endLineData = "\r\n".data(using: .utf8) {
                             body.append(contentsOf: fileHeaderData)
                             body.append(fileData)
                             body.append(contentsOf: endLineData)
                         }
                     } catch {
                         print("Ошибка чтения файла: \(error)")
                         return
                     }
                 

             body.append(contentsOf: "--\(boundary)--\r\n".data(using: .utf8)!)
             
             urlRequest.httpBody = body
             var result = urlRequest.allHTTPHeaderFields;
             let session = URLSession.shared
             let task = session.dataTask(with: urlRequest) { (data, response, error) in
                 if let error = error {
                     self.callback.onExpection(mac: id, ex: error)
                     
                     DeviceService.getInstance().ls.addLogs(text:"Error: \(error)")
                 }
                 if let httpResponse = response as? HTTPURLResponse {
                     let statusCode = httpResponse.statusCode
                     print(statusCode)
                     if(statusCode <= 202 || statusCode == 207){
                         print("File success")
                         self.callback.onSendData(mac: id, status: PlatformStatus.Success)
                     }
                     else{
                         print("File failed")
                         self.callback.onSendData(mac: id, status: PlatformStatus.Failed)
                     }
                 }
                 if let responseData = data {
                     if let responseString = String(data: responseData, encoding: .utf8) {
                         DeviceService.getInstance().ls.addLogs(text:"Response: \(responseString)")
                     }
                 }
             }; task.resume()}



     internal func postResource(data: Data, bundle: Bool) {
         self.dispatchGroup.enter()
         let timeUrl = URL(string: (self.baseAddress + "/gateway/iiot/api/Observation/data"))!
         var urlRequest: URLRequest = URLRequest(url: timeUrl)
         let identifier = UUID()
         urlRequest.httpMethod = "POST"
         urlRequest.addValue("Basic " + self.auth, forHTTPHeaderField: "Authorization")
         urlRequest.addValue("I2024-03-20T10:12:22Z", forHTTPHeaderField: "SDK-VERSION")
         urlRequest.addValue("Id " + self.instanceId.uuidString, forHTTPHeaderField: "InstanceID")
         urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
         urlRequest.httpBody = data

         let session = URLSession.shared
         let task = session.dataTask(with: urlRequest) { (data, response, error) in

             if let error = error {
                 self.callback.onExpection(mac: identifier, ex: error)
                 DeviceService.getInstance().ls.addLogs(text: "Error: \(error)")
             }

             if let httpResponse = response as? HTTPURLResponse {
                 let statusCode = httpResponse.statusCode
                 if (statusCode <= 202 || statusCode == 400 || statusCode == 401 || statusCode == 403 || statusCode == 207) {
                     if(statusCode <= 202 || statusCode == 207){
                         self.callback.onSendData(mac: UUID(), status: PlatformStatus.Success)
                     }
                     if(statusCode == 400 || statusCode == 401 || statusCode == 403){
                         self.callback.onSendData(mac: UUID(), status: PlatformStatus.Failed)
                     }
                     let backgroundQueue = DispatchQueue.global(qos: .background)
                     backgroundQueue.async {
                         let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                         backgroundContext.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator

                         let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Entity")
                         fetchRequest.returnsObjectsAsFaults = false
                         fetchRequest.predicate = NSPredicate(format: "deviceType == %@", "EltaGlucometer" as CVarArg)
                         do {
                             let results = try backgroundContext.fetch(fetchRequest)
                             for object in results {
                                 guard let objectData = object as? NSManagedObject else { continue }
                                 guard objectData.managedObjectContext == backgroundContext else { continue }
                                 backgroundContext.delete(objectData)
                             }
                             try backgroundContext.save()

                             self.stopTimer()
                             self.interval = 1
                         } catch let error {
                             print("Delete all data error :", error)
                         }
                     }

                 } else {
                     self.callback.onSendData(mac: identifier, status: PlatformStatus.Failed)
                 }
             }

             if let responseData = data {
                 if let responseString = String(data: responseData, encoding: .utf8) {
                     DeviceService.getInstance().ls.addLogs(text: "Response: \(responseString)")
                 }
             }

             self.dispatchGroup.leave() // Покидаем группу после обработки ответа
         }
         task.resume()
     }

    internal func getTime(serial: String){
        let timeUrl  = URL(string: (self.baseAddress + "/gateway/iiot/api/Observation/data" + "?serial=\(serial)&type=effectiveDateTime"))!
        var urlRequest: URLRequest = URLRequest(url: timeUrl)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("Basic " + self.auth, forHTTPHeaderField: "Authorization")
        urlRequest.addValue("I2024-03-20T10:12:22Z", forHTTPHeaderField: "SDK-VERSION")
        urlRequest.addValue("Id " + self.instanceId.uuidString, forHTTPHeaderField: "InstanceID")
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                DeviceService.getInstance().ls.addLogs(text:"Error: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                
            }
            if let responseData = data {
                if let responseString = String(data: responseData, encoding: .utf8) {
                    let time = EltaGlucometr.FormatPlatformTime.date(from: responseString)
                    UserDefaults.standard.set(time, forKey: serial)
                }
            }
        }
        task.resume()
    }
     internal func sendLogsToServer(data: Data) {
         let timeUrl  = URL(string: (self.baseAddress + "/logs/sdk/save"))!
         var urlRequest: URLRequest = URLRequest(url: timeUrl)
         urlRequest.httpMethod = "POST"
         urlRequest.addValue("Basic " + self.auth, forHTTPHeaderField: "Authorization")
         urlRequest.addValue("I2024-03-20T10:12:22Z", forHTTPHeaderField: "SDK-VERSION")
         urlRequest.addValue("Id " + self.instanceId.uuidString, forHTTPHeaderField: "InstanceID")
         urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
         urlRequest.httpBody = data
         let session = URLSession.shared
         let task = session.dataTask(with: urlRequest) { (responseData, response, error) in
             if let error = error {
                 DeviceService.getInstance().ls.addLogs(text:"Ошибка при отправке логов на сервер: \(error)")
                 return
             }
             
             guard let httpResponse = response as? HTTPURLResponse else {
                 DeviceService.getInstance().ls.addLogs(text:"Ошибка: Ответ от сервера не является HTTPURLResponse")
                 return
             }
             
             if httpResponse.statusCode <=  202 {
                 // Очищаем только объекты типа Logs из CoreData
                 print("clearLOGS()")
                 DeviceService.getInstance().ls.clearLogsFromCoreData()
             } else {
                 DeviceService.getInstance().ls.addLogs(text:"Ошибка: Не удалось очистить Logs из CoreData. Код ответа сервера: \(httpResponse.statusCode)")
             }
         }
         task.resume()
     }
     @objc func sendDataToServer() {
         DispatchQueue.main.async {
             if(self.isCoreDataNotEmpty()){
                 let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                 context.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
                 let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                 
                 var dataArray: [[Data]] = [] // Массив массивов для сбора данных
                 
                 do {
                     let objects = try context.fetch(fetchRequest)
                     DeviceService.getInstance().ls.addLogs(text: "Попытка отправить: \(String(describing: objects.count)) через \(String(describing:self.interval))")
                     
                     var currentArray: [Data] = [] // Текущий массив данных
                     
                     for (index, object) in objects.enumerated() {
                         if(object.deviceType == "EltaGlucometer" || object.deviceType == nil){
                             if let body = object.body?.data(using: .utf8) {
                                 currentArray.append(body) // Добавляем данные в текущий массив
                             } else {
                                 DeviceService.getInstance().ls.addLogs(text: "Ошибка: Не удалось преобразовать тело объекта в Data")
                             }
                             
                             if currentArray.count == 100 || index == objects.count - 1 {
                                 dataArray.append(currentArray)
                                 currentArray = []
                             }}
                         if(object.deviceType == "DoctisFetal"){
                             if let body = object.body?.data(using: .utf8) {
                                 if let title = object.title {
                                     self.postResource(data: body, id: title)
                                 }
                             } else {
                                 DeviceService.getInstance().ls.addLogs(text: "Ошибка: Не удалось преобразовать тело объекта в Data")
                             }
                         }
                     }
                     for dataSubArray in dataArray {
                         BundleTemplate.ApplyObservation(dataArray: dataSubArray)
                     }
                 } catch {
                     DeviceService.getInstance().ls.addLogs(text: "Ошибка при получении объектов из Core Data: \(error)")
                 }
                 self.dispatchGroup.notify(queue: .main) {
                     self.increaseInterval()
                 }
             }else{
                 self.stopTimer()
                 self.interval = 1;
             }
         }
   
     }



    
}
