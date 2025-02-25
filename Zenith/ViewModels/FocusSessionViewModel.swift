import SwiftUI
import Combine

class FocusSessionViewModel: ObservableObject {
    @Published var isActive = false
    @Published var isMinimized = false
    @Published var isExpanded = false
    @Published var selectedTask: TodoTask?
    @Published var timerDuration: TimeInterval = 25 * 60
    @Published var remainingTime: TimeInterval = 25 * 60
    @Published var timeWorkedToday: TimeInterval = 0
    @Published var showingForfeitAlert = false
    @Published var blockDistractions = true
    
    private var timer: AnyCancellable?
    
    var progress: Double {
        1.0 - (remainingTime / timerDuration)
    }
    
    func startSession() {
        isActive = true
        isExpanded = true
        startTimer()
    }
    
    func dismissSession() {
        isExpanded = false
    }
    
    func minimizeSession() {
        isMinimized = true
        isExpanded = false
    }
    
    func expandSession() {
        isMinimized = false
        isExpanded = true
    }
    
    func forfeitSession() {
        stopTimer()
        resetSession()
    }
    
    func completeSession() {
        stopTimer()
        timeWorkedToday += timerDuration
        resetSession()
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingTime > 0 {
                    self.remainingTime -= 1
                } else {
                    self.completeSession()
                }
            }
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func resetSession() {
        isActive = false
        isMinimized = false
        isExpanded = false
        remainingTime = timerDuration
        selectedTask = nil
    }
} 