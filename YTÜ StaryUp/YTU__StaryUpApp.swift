//
//  YTU__StaryUpApp.swift
//  YTÜ StaryUp
//
//  Created by Fatih Kadir Akın on 5.02.2026.
//

import SwiftUI

@main
struct YTU__StaryUpApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var splashFinished = false
    @State private var sessionRestored = false
    
    var body: some Scene {
        WindowGroup {
            if !splashFinished || !sessionRestored {
                SplashView {
                    splashFinished = true
                }
                .task {
                    await authViewModel.restoreSession()
                    sessionRestored = true
                }
            } else if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                AuthView(authViewModel: authViewModel)
            }
        }
    }
}
