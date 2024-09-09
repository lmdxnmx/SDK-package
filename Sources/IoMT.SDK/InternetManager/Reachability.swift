import Foundation
import Reachability
class ReachabilityManager {

    
    let reachability: Reachability
    var im:InternetManager
    var _callback:DeviceCallback
    internal init(manager:InternetManager,callback:DeviceCallback) {
        // Инициализируем Reachability
        guard let reachability = try? Reachability() else {
            fatalError("Unable to create Reachability")
        }
        self._callback = callback
        self.reachability = reachability
        im = manager
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            DeviceService.getInstance().ls.addLogs(text:"Could not start reachability notifier")
        }
    }
    
    func stopMonitoring() {
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
    }
    
    @objc func reachabilityChanged(_ notification: Notification) {
        guard let reachability = notification.object as? Reachability else {
            DeviceService.getInstance().ls.addLogs(text:"Invalid reachability object")
            DeviceService.getInstance().ls.addLogs(text: "Invalid reachability object")
            return
        }
        
        switch reachability.connection {
        case .none:
            DeviceService.getInstance().ls.addLogs(text:"Network unreachable")
            _callback.internetStatus(status: "Network unreachable")
        case .wifi:
            DeviceService.getInstance().ls.addLogs(text:"Wifi enable")
            _callback.internetStatus(status: "Wifi enable")
            self.im.dropTimer()
        case .cellular:
            DeviceService.getInstance().ls.addLogs(text:"Network reachable via cellular data")
            _callback.internetStatus(status: "Network reachable via cellular data")
            self.im.dropTimer()
        default:
            DeviceService.getInstance().ls.addLogs(text:"Unknown network status")
            _callback.internetStatus(status: "Unknown network status")
        }
    }
}
