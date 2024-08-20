//
//  CoreDataStack.swift
//  MedicalApp
//
//  Created by Никита on 08.02.2024.
//
import CoreData
import Foundation
class PersistentContainer: NSPersistentContainer { }
class CoreDataStack {
    
    // Создание shared экземпляра для использования во всем приложении
    static let shared = CoreDataStack()
   
    // Создание подкласса NSPersistentContainer
    open class PersistentContainer: NSPersistentContainer { }

    lazy public var persistentContainer: PersistentContainer! = {
        // Попытка получить URL модели данных в пакете
        guard let modelURL = Bundle.module.url(forResource: "Observation-2", withExtension: "momd") else {
            return nil
        }
        
        // Загрузка модели данных из указанного URL
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            return nil
        }
        
        // Инициализация контейнера с именем и моделью данных
        let container = PersistentContainer(name: "Observation-2", managedObjectModel: model)
        
        // Загрузка персистентного хранилища
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Ошибка при загрузке персистентного хранилища: \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()


    
    // Контекст для работы с данными в основной очереди
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Сохранение изменений в контексте
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                // Сохранение контекста
                try context.save()
            } catch {
                // Обработка ошибок сохранения контекста
                let nserror = error as NSError
                fatalError("Не удалось сохранить контекст: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}
