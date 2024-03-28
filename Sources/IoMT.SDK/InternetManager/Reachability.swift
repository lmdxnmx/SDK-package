import Foundation
import Reachability
class ReachabilityManager {

    
    let reachability: Reachability
    var im:InternetManager
    internal init(manager:InternetManager) {
        // Инициализируем Reachability
        guard let reachability = try? Reachability() else {
            fatalError("Unable to create Reachability")
        }
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
        case .wifi:
            DeviceService.getInstance().ls.addLogs(text:"Wifi enable")
            
            self.im.dropTimer()
        case .cellular:
            DeviceService.getInstance().ls.addLogs(text:"Network reachable via cellular data")
            self.im.dropTimer()
        default:
            DeviceService.getInstance().ls.addLogs(text:"Unknown network status")
        }
    }
}
