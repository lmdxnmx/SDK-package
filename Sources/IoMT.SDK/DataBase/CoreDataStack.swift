// CoreDataStack.swift
// MedicalApp
//
// Created by Никита on 08.02.2024.
//

import CoreData
import Foundation

class PersistentContainer: NSPersistentContainer { }

class CoreDataStack {
    
    // Создание shared экземпляра для использования во всем приложении
    static let shared = CoreDataStack()
    
    // Ленивая инициализация persistentContainer
    lazy var persistentContainer: PersistentContainer = {
        // Создание NSPersistentContainer с именем вашей модели данных
        let container = PersistentContainer(name: "Observation-2", managedObjectModel: self.managedObjectModel)
        
        // Загрузка persistent store для данного контейнера
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Обработка ошибок загрузки persistent store
                fatalError("Не удалось загрузить Persistent Store: \(error), \(error.userInfo)")
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
    
    // Метод для загрузки модели из Bundle.module
    private var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.module.url(forResource: "Observation-2", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
}
