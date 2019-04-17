//
//  AppDelegate.swift
//  LoginDemoApplication
//
//  Created by CPU12071 on 4/17/19.
//  Copyright © 2019 Le Duy Bach. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let loginVC = LoginScreenViewController()
        window?.rootViewController = loginVC
        window?.makeKeyAndVisible()
        return true
    }
}

