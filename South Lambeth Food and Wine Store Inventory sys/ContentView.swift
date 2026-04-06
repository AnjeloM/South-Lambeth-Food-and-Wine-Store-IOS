//
//  ContentView.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 17/01/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        AppRootView(sessionChecker: DemoSessionChecker(signedIn: false))
    }
}

#Preview {
    ContentView()
}
