import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleDailyReminder(isEnabled: Bool, time: Date = Date()) {
        // 1. Always clear old requests first so we don't stack them
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 2. If disabled, stop here
        guard isEnabled else { return }
        
        // 3. Create Content
        let content = UNMutableNotificationContent()
        content.title = "Interview Ready 🎯"
        content.body = "Time for your daily 5-minute drill. Keep your answers sharp!"
        content.sound = .default
        
        // 4. Create Trigger (e.g., 9:00 AM or User Selected Time)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 5. Schedule
        let request = UNNotificationRequest(identifier: "daily_drill", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
