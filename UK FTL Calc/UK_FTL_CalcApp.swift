//
//  UK_FTL_CalcApp.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

@main
struct UK_FTL_CalcApp: App {
    @StateObject private var authService = AuthenticationService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}
