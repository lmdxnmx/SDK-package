import CoreData
import Foundation

class CoreDataStack {
    
    // Создание shared экземпляра для использования во всем приложении
    static let shared = CoreDataStack()
    
    // Инициализация контейнера с ленивой загрузкой
    lazy var persistentContainer: NSPersistentContainer = {
        // Попытка получить URL модели данных в пакете
        guard let modelURL = Bundle.module.url(forResource: "Observation-2", withExtension: "momd") else {
            fatalError("Не удалось найти модель данных в пакете.")
        }
        
        // Загрузка модели данных из указанного URL
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Не удалось создать модель данных из URL: \(modelURL).")
        }
        
        // Инициализация контейнера с именем и моделью данных
        let container = NSPersistentContainer(name: "Observation-2", managedObjectModel: model)
        
        // Загрузка персистентного хранилища
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Ошибка при загрузке персистентного хранилища: \(error), \(error.userInfo)")
            }
        }
        
        return container
    }()
    
    // Контекст для работы с данными в основной очереди
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Сохранение изменений в контексте
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Не удалось сохранить контекст: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}
