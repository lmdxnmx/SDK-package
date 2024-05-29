//
//  File.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 04.07.2023.
//

import Foundation

///Статусы при работе с перефирийными устройствами
public enum BluetoothStatus{
    ///Начато подключение к периферийному устройству
    case ConnectStart
    ///Ошибка при подключение к устройству
    case ConnectFail
    ///Статус возвращающийся при попытке повторно подключиться к устройству
    case Connected
    ///Статус возвращающийся при успешном подключение к перефирийному устройству
    case ConnectSuccess
    ///Статус возвращающийся при отключение от перефирийного устройства
    case ConnectDisconnect
    ///Не правильный пин код при подключение к устройству
    case NotCorrectPin
    ///Не правильный шаблон для подключения к перефирийным устройствами
    case InvalidDeviceTemplate
}

///Статусы при отправке данных на платформу
public enum PlatformStatus{
    ///Отправка успешна
    case Success
    ///При отправке возникла ошибка
    case Failed
    ///Нет новых данных
    case NoDataSend
    ///Данные сохранены в результате ошибке при отправке
    case DataCashed
}

///Атрибуты при собираемых данных
public enum Atributes : String{
    ///Серийный номер устройства, объект String
    case SerialNumber
    ///Уровень батареи, объект Integer
    case BatteryLevel
    ///Температура в кельвинах, объект Integer
    case TemperatureLevel
    ///Время когда было сделано измерения, объект Date
    case TimeStamp
    case BleTime
    case Temperature
    ///Показатель глюкозы в крови
    case Glucose
    case Toco
    case HeartRate
    ///Объект измерений
    case Measurements
    ///Модель устройства, объект String
    case ModelNumber
    
    //case Systolic
    
    //case Diastolic
    
    //case HeartRat
}
