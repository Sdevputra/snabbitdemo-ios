//
//  SnabbitDemoApp.swift
//  SnabbitDemo
//
//  Created by Shubham Sharma on 06/03/26.
//

import SwiftUI
import FirebaseCore

@main
struct SnabbitDemoApp: App {
    @State private var appCoordinator: AppCoordinator
    
    init() {
        FirebaseApp.configure()
        _appCoordinator = State(initialValue: AppCoordinator())
    }
    
    var body: some Scene {
        WindowGroup {
            CoordinatorView()
                .environment(appCoordinator)
        }
    }
}
