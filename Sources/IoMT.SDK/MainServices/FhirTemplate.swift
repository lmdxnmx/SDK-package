//
//  Glucometr.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 08.07.2023.
//

import Foundation

internal class FhirTemplate{
    
    static public func Glucometer(serial: String, model: String,effectiveDateTime: Date, value: Double) -> Data?{
        let uuid: String = UUID().uuidString.lowercased()
        let roundedValue = String(format: "%.1f", value)
        let TemplateFhir: String = "{\"id\":\"\(uuid)\",\"resourceType\":\"Observation\",\"effectiveDateTime\":\"\(EltaGlucometr.FormatPlatformTime.string(from: effectiveDateTime))\",\"device\":{\"display\":\"\(model)\",\"identifier\":{\"value\":\"\(serial)\"},\"type\":\"Glucometer\"},\"code\":{\"coding\":[{\"code\":\"3\",\"display\":\"Измерение глюкозы в капиллярной крови\",\"system\":\"https://ppmp.ru/fhir/VP_OC\",\"userSelected\":\"false\"}],\"text\":\"Дистанционное наблюдение за показателями уровня глюкозы крови\"},\"component\":[{\"code\":{\"coding\":[{\"code\":\"4\",\"display\":\"Глюкоза в капиллярной крови натощак\",\"system\":\"https://ppmp.ru/fhir/VP_VT\",\"userSelected\":\"false\"}],\"text\":\"Глюкоза в капиллярной крови натощак\"},\"valueQuantity\":{\"code\":\"mmol/l\",\"system\":\"https://ppmp.ru/fhir/VP_MU\",\"unit\":\"ммоль/л\",\"value\":\(roundedValue)}}]}"
    
        return Data(TemplateFhir.utf8)

    }
    static public func Glucometer(serial: String,id:UUID ,model: String,effectiveDateTime: Date, value: Double) -> Data?{
        let uuid: String = id.uuidString.lowercased()
        let roundedValue = String(format: "%.1f", value)
        let TemplateFhir: String = "{\"id\":\"\(uuid)\",\"resourceType\":\"Observation\",\"effectiveDateTime\":\"\(EltaGlucometr.FormatPlatformTime.string(from: effectiveDateTime))\",\"device\":{\"display\":\"\(model)\",\"identifier\":{\"value\":\"\(serial)\"},\"type\":\"Glucometer\"},\"code\":{\"coding\":[{\"code\":\"3\",\"display\":\"Измерение глюкозы в капиллярной крови\",\"system\":\"https://ppmp.ru/fhir/VP_OC\",\"userSelected\":\"false\"}],\"text\":\"Дистанционное наблюдение за показателями уровня глюкозы крови\"},\"component\":[{\"code\":{\"coding\":[{\"code\":\"4\",\"display\":\"Глюкоза в капиллярной крови натощак\",\"system\":\"https://ppmp.ru/fhir/VP_VT\",\"userSelected\":\"false\"}],\"text\":\"Глюкоза в капиллярной крови натощак\"},\"valueQuantity\":{\"code\":\"mmol/l\",\"system\":\"https://ppmp.ru/fhir/VP_MU\",\"unit\":\"ммоль/л\",\"value\":\(roundedValue)}}]}"
    
        return Data(TemplateFhir.utf8)

    }}
