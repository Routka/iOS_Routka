//
//  AppDelegate.swift
//  Routka
//
//  Created by vladukha on 20.04.2026.
//


import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Custom initialization code if needed
        print("AppDelegate didFinishLaunchingWithOptions called.")
        registerProviderFactories()
        return true
    }
}
