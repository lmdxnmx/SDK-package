//
//  Entity+CoreDataProperties.swift
//  IoMT.SDK
//
//  Created by Никита on 19.02.2024.
//
//

import Foundation
import CoreData


extension Entity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entity> {
        return NSFetchRequest<Entity>(entityName: "Entity")
    }

    @NSManaged public var body: String?
    @NSManaged public var title: UUID?

}

extension Entity : Identifiable {

}
