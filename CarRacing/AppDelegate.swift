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
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        let viewController = Globals.rootViewController
        viewController.modalPresentationStyle = .fullScreen
        viewController.modalTransitionStyle = .crossDissolve
        
        window.backgroundColor = UIColor.road
        window.rootViewController = viewController
        self.window = window
        
        window.makeKeyAndVisible()
        return true
    }
}

