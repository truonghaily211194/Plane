//
//  AppDelegate.swift
//  CarRacing
//
//  Created by Ly Truong H. VN.Danang on 08/05/2023.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        let vc = GameViewController()
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        return true
    }
}

