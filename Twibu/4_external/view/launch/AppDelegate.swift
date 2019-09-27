//
//  AppDelegate.swift
//  Twibu
//
//  Created by abeyuya on 2019/06/15.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import UIKit
import Firebase
import TwitterKit
import Embedded
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let _ = TwibuFirebase.shared
        Fabric.with([Crashlytics.self])
        TWTRTwitter.sharedInstance().start(
            withConsumerKey: Const.twitterConsumerKey,
            consumerSecret: Const.twitterConsumerSecret
        )

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = RootViewController()
        window?.makeKeyAndVisible()

        Router.shared.showLauncingView() {}
        UserDispatcher.setupUser() { result in
            Router.shared.showPagingRootView() {}
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let scheme = url.scheme else {
            return false
        }

        let query = url.queryParams()

        if scheme == "twibu", let buid = query["uid"], let urlStr = query["url"] {
            let b = Bookmark(
                uid: buid,
                title: query["title"],
                image_url: query["image_url"],
                description: query["description"],
                comment_count: Int(query["comment_count"] ?? "0"),
                created_at: Int(query["created_at"] ?? "0"),
                updated_at: Int(query["updated_at"] ?? "0"),
                url: urlStr,
                category: Category(rawValue: query["category"] ?? "unknown")
            )
            let vc = WebViewController.initFromStoryBoard()
            vc.set(bookmark: b)

            Router.shared.openBookmarkWebFromUrlScheme(vc: vc)
            return true
        }

        return TWTRTwitter.sharedInstance().application(app, open: url, options: options)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
