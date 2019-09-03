//
//  AppDelegate.swift
//  Radio Cybernet
//
//  Created by Antonio Malara on 02/09/2019.
//  Copyright © 2019 Antonio Malara. All rights reserved.
//

import UIKit

func shoutcast_connection_test(
    radioUrl: String,
    port: Int,
    mount: String,
    password: String
) {
    shout_init()
    
    guard let shout = shout_new()
        else { return }
    
    guard radioUrl.withCString({
        shout_set_host(shout, $0)
    }) == SHOUTERR_SUCCESS
        else { return }
    
    guard shout_set_protocol(shout, UInt32(SHOUT_PROTOCOL_HTTP)) == SHOUTERR_SUCCESS
        else { return }

    guard shout_set_port(shout, UInt16(port)) == SHOUTERR_SUCCESS
        else { return }

    guard password.withCString({
        shout_set_password(shout, $0)
    }) == SHOUTERR_SUCCESS
        else { return }
    
    guard mount.withCString({
        shout_set_mount(shout, $0)
    }) == SHOUTERR_SUCCESS
        else { return }
    
    guard shout_set_format(shout, UInt32(SHOUT_FORMAT_MP3)) == SHOUTERR_SUCCESS
        else { return }
    
    guard shout_open(shout) == SHOUTERR_SUCCESS
        else { return }
    
    let test = try! Data(contentsOf: Bundle.main.url(forResource: "test", withExtension: "mp3")!)

    let res = test.withUnsafeBytes { bytes -> Int32 in
        let x = bytes.bindMemory(to: UInt8.self)
        return shout_send(shout, x.baseAddress, x.count)
    }
    
    if res != SHOUTERR_SUCCESS {
        print(shout_get_error(shout))
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool
    {
   
    /*
        shoutcast_connection_test(
            radioUrl: "XXX",
            port: 8000,
            mount: "/test.mp3",
            password: "XXX"
        )
    */
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use thisahaha method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
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

