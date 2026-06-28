//
//  ContentView.swift
//  Aura
//
//  Thin entry wrapper around the app's root navigation.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
}
