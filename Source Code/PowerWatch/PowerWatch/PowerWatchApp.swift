//
//  PowerWatchApp.swift
//  PowerWatch
//
//  Created by Mark Howard on 02/08/2023.
//

import SwiftUI
import WatchConnectivity

@main
struct PowerWatchApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject, WCSessionDelegate {
    var session: WCSession?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session Inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Session Deactivated")
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session Activated")
    }
}

class WatchConnectivityViewModel: ObservableObject {
    func sendMessageToWatch() {
        if WCSession.default.isReachable {
            let message = ["key": "value"]
            WCSession.default.sendMessage(message, replyHandler: { reply in
                // Handle Reply From Watch
                print(reply)
            }, errorHandler: { error in
                // Handle Error
                print(error)
            })
        } else {
            print("Not Reachable")
        }
    }
}
