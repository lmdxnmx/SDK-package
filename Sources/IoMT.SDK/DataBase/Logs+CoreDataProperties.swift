//
//  Logs+CoreDataProperties.swift
//  IoMT.SDK
//
//  Created by Никита on 19.02.2024.
//
//

import Foundation
import CoreData


extension Logs {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Logs> {
        return NSFetchRequest<Logs>(entityName: "Logs")
    }

    @NSManaged public var log: String?
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?

}

extension Logs : Identifiable {

}
