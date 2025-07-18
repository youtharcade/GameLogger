//
//  ContentView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CollectionHomePageView()
                .tabItem {
                    Label("Collection", systemImage: "gamecontroller.fill")
                }
            
            HardwareListView()
                .tabItem { Label("Hardware", systemImage: "desktopcomputer") }
            
            BacklogView()
                .tabItem {
                    Label("Backlog", systemImage: "books.vertical.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
        }
    }
}
