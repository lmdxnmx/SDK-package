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
   
    // Ленивая инициализация persistentContainer
    lazy var persistentContainer: NSPersistentContainer = {
        guard let modelURL = Bundle.module.url(forResource: "Observation-2", withExtension: "momd"),
              let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Не удалось найти модель данных в пакете.")
        }

        let container = NSPersistentContainer(name: "Observation-2", managedObjectModel: managedObjectModel)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Ошибка при загрузке хранилища: \(error), \(error.userInfo)")
            }
        }
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
