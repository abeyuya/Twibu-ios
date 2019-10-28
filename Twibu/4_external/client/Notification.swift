//
//  Notification.swift
//  Twibu
//
//  Created by abeyuya on 2019/10/27.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import UserNotifications
import Embedded

enum Notification {
    private static let appDelegate = UIApplication.shared.delegate as! AppDelegate

    enum NoticeType: String {
        case localRemind
    }

    static func requestPermission(completion: @escaping (Result<Void, TwibuError>) -> Void) {
        UNUserNotificationCenter
            .current()
            .requestAuthorization(options: [.badge, .sound, .alert]) { granted, error in
                if let error = error {
                    completion(.failure(.notificationPermissionError(error.localizedDescription)))
                    return
                }

                guard granted else {
                    completion(.failure(.notificationPermissionError("通知を拒否した")))
                    return
                }

                DispatchQueue.main.async {
                    UNUserNotificationCenter.current().delegate = appDelegate
                    completion(.success(Void()))
                }
        }
    }

    static func setLocalNotification(
        bookmarkUid: String,
        title: String,
        message: String,
        image: UIImage?,
        date: DateComponents,
        completion: @escaping (Result<Void, TwibuError>) -> Void
    ) {
        allowNotificationState { result in
            switch result {
            case .failure(let e):
                completion(.failure(e))
            case .success:
                let content: UNMutableNotificationContent = {
                    let c = UNMutableNotificationContent()
                    c.title = "読みかけの記事がありました"
                    c.body = ["【\(title)】", message].joined(separator: "\n")
                    c.sound = .default
                    c.userInfo = [
                        "type": NoticeType.localRemind.rawValue,
                        "bookmarkUid": bookmarkUid
                    ]
                    if let i = image,
                        let url = saveImageToLocalTmp(image: i),
                        let a = try? UNNotificationAttachment(identifier: "thumbnail", url: url, options: nil) {
                        c.attachments = [a]
                    }
                    return c
                }()

                let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
                let request = UNNotificationRequest(identifier: "normal", content: content, trigger: trigger)

                DispatchQueue.main.async {
                    let center = UNUserNotificationCenter.current()
                    center.delegate = appDelegate
                    center.add(request) { error in
                        if let error = error {
                            completion(.failure(.notificationPermissionError(error.localizedDescription)))
                            return
                        }

                        completion(.success(Void()))
                    }
                }
            }
        }
    }

    private static func allowNotificationState(completion: @escaping (Result<Void, TwibuError>) -> Void) {
        DispatchQueue.main.async {
            let center = UNUserNotificationCenter.current()
            center.delegate = appDelegate
            center.getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .authorized:
                    completion(.success(Void()))
                case .provisional:
                    completion(.success(Void()))
                case .notDetermined:
                    // NOTE: provisionalと競合しないのかな？
                    completion(.success(Void()))
                case .denied:
                    completion(.failure(.notificationPermissionError("拒否されている")))
                @unknown default:
                    completion(.failure(.notificationPermissionError("未知のstatus")))
                }
            }
        }
    }

    private static func saveImageToLocalTmp(image: UIImage) -> URL? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)

        do {
            try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
            let imageFileIdentifier = ProcessInfo.processInfo.globallyUniqueString + ".png"
            let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
            guard let imageData = image.pngData() else { return nil }
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            Logger.print(error.localizedDescription)
        }

        return nil
    }
}
