//
//  SimulateGearKeyboradApp.swift
//  SimulateGearKeyborad
//
//  Created by LuckyE on 1/13/26.
//  test good

import SwiftUI

@main
struct SimulateGearKeyboradApp: App {
    var body: some Scene {
        MenuBarExtra("BarSound", systemImage: "keyboard") {
            ContentView()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
