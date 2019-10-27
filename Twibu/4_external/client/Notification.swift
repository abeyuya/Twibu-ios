//
//  Notification.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/27.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import NotificationCenter
import Embedded

enum Notification {
    static func requestPermission(completion: @escaping (Result<Void, TwibuError>) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.badge, .sound, .alert]) { (granted, error) in
            if let error = error {
                debugPrint(error)
                return
            }

            guard granted else {
                completion(.failure(TwibuError.notificationPermissionError("通知を拒否した")))
                return
            }

            completion(.success(Void()))
        }
    }
}
