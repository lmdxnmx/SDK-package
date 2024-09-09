//
//  DeviceCallback.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 06.06.2023.
//

import Foundation

///Экземпляр для функций обратного вызова из приложения
public protocol DeviceCallback: AnyObject {
    ///Функция вызывающаяся при каждом найденном атрибуте в перефирийном устройстве
    func onExploreDevice(mac: UUID, atr: Atributes, value: Any);
    ///Функция вызывающаяся при изменение статуса при активной сессии с ble устройством
    func onStatusDevice(mac: UUID, status: BluetoothStatus);
    ///Функция вызывающаяся при получение ответа от платформы
    func onSendData(mac: UUID, status: PlatformStatus);
    ///Функция вызывающаяся при возникновения ошибки при работе сервиса
    func onExpection(mac: UUID, ex: Error);
    ///Функция вызывающаяся при отключения от устройства, для возвращения результата работы
    func onDisconnect(mac: UUID, data: ([Atributes: Any], Array<Measurements>));
    ///Функция вызывающаяся при нахождения устройства во время поиска
    func findDevice(peripheral: DisplayPeripheral);
    ///Функция вызывающаяся после окончания поиска, возвращает все найденные устройства
    func searchedDevices(peripherals: [DisplayPeripheral]);
    func internetStatus(status:String)
}



