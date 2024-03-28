//
//  DataCollector.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 08.07.2023.
//

import Foundation

internal struct Collector{
    private var charateristic: [Atributes: Any] = [:]
    private var measurements: Array<Measurements> = Array<Measurements>()
    
    public mutating func addInfo(atr: Atributes, value: Any){
        charateristic[atr] = value
    }
    
    public mutating func addMeasurements(Object: Measurements){
        measurements.append(Object)
    }
    public func returnData() -> ([Atributes: Any], Array<Measurements>){
        let Tuple = (charateristic,measurements)
        return Tuple
    }
    
    internal func returnCharateristic(atribute: Atributes) -> Any?{
        return charateristic[atribute]
    }
    
    internal func returnMeasurements() -> Array<Measurements>{
        return measurements
    }
    
    internal func returnMeasurements(offsetTime: Date) -> Array<Measurements>{
        var retMeasurements = Array<Measurements>()
        for m in measurements{
            let element = m
            let time = m.get(atr: Atributes.TimeStamp) as! Date
            if(time > offsetTime){
                retMeasurements.append(element)
            }
        }
        return retMeasurements
    }
    
}

