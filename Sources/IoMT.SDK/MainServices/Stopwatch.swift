import Foundation
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
class Stopwatch {
    private var startTime: Date?
    private var isRunning = false
    
    func start() {
        guard !isRunning else { return }
        startTime = Date()
        isRunning = true
    }
    
    func stop() {
        guard isRunning else { return }
        isRunning = false
    }
    
    func elapsedTimeInSeconds() -> TimeInterval {
        if let startTime = startTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            return elapsedTime.rounded(toPlaces: 3)
        } else {
            return 0
        }
    }
}
