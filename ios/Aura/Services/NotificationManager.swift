//
//  NotificationManager.swift
//  Aura
//
//  Schedules a daily local notification with a random motivational message.
//

import Foundation
import UserNotifications

enum NotificationManager {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Schedules (or reschedules) the daily reminder at the given minutes-from-midnight.
    static func scheduleDaily(minutes: Int, enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["aura.daily.reminder"])
        guard enabled else { return }

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "Aura"
            content.body = NotificationMessages.all.randomElement() ?? "Музыка ждёт тебя!"
            content.sound = .default

            var date = DateComponents()
            date.hour = minutes / 60
            date.minute = minutes % 60

            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            let request = UNNotificationRequest(
                identifier: "aura.daily.reminder",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
}
