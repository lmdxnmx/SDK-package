import Foundation

internal class BundleTemplate {
    
    static public func ApplyObservation(dataArray: [Data]) {
        var entryArray: [[String: Any]] = []
        
        for data in dataArray {
            if let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let resourceDict: [String: Any] = ["resource": jsonData]
                entryArray.append(resourceDict)
            }
        }
        
        let bundleData: [String: Any] = [
            "resourceType": "Bundle",
            "entry": entryArray
        ]
        
        // Вручную собираем JSON-строку
        var jsonString = "{"
        for (key, value) in bundleData {
            jsonString += "\"\(key)\":\(convertValueToString(value)),"
        }
        jsonString.removeLast() // Удаляем последнюю запятую
        jsonString += "}"
        print(jsonString)
        DeviceService.getInstance().im.postResource(data: Data(jsonString.utf8), bundle: true)
    }
    
    static private func convertValueToString(_ value: Any) -> String {
          if let intValue = value as? Int {
              return "\(intValue)"
          } else if let doubleValue = value as? Double {
              return "\(doubleValue)"
          } else if let boolValue = value as? Bool {
              return boolValue ? "true" : "false" // Преобразование значения типа Bool в строку
          } else if let stringValue = value as? String {
              return "\"\(stringValue)\""
          } else if let arrayValue = value as? [Any] {
              var arrayString = "["
              for element in arrayValue {
                  arrayString += "\(convertValueToString(element)),"
              }
              arrayString.removeLast() // Удаляем последнюю запятую
              arrayString += "]"
              return arrayString
          } else if let dictValue = value as? [String: Any] {
              var dictString = "{"
              for (key, value) in dictValue {
                  dictString += "\"\(key)\":\(convertValueToString(value)),"
              }
              dictString.removeLast() // Удаляем последнюю запятую
              dictString += "}"
              return dictString
          } else {
              return ""
          }
      }
}
