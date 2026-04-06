//
//  South_Lambeth_Food_and_Wine_Store_Inventory_sysApp.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 17/01/2026.
//

import SwiftUI
import FirebaseCore

@main
struct South_Lambeth_Food_and_Wine_Store_Inventory_sysApp: App {
    init () {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
