import Foundation

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

class Stopwatch {
    private var startTime: Date?
    private var accumulatedTime: TimeInterval = 0
    private var isRunning = false
    
    func start() {
        guard !isRunning else { return }
        startTime = Date()
        isRunning = true
    }
    
    func pause() {
        guard isRunning else { return }
        if let startTime = startTime {
            accumulatedTime += Date().timeIntervalSince(startTime)
        }
        isRunning = false
    }

    
    func reset() {
        startTime = nil
        accumulatedTime = 0
        isRunning = false
    }
    
    func elapsedTimeInSeconds() -> TimeInterval {
        if isRunning, let startTime = startTime {
            let elapsedTime = accumulatedTime + Date().timeIntervalSince(startTime)
            return elapsedTime.rounded(toPlaces: 3)
        } else {
            return accumulatedTime.rounded(toPlaces: 3)
        }
    }
}
