//
//  ContentView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var showOnboarding: Bool
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to GameLogger",
            subtitle: "Your ultimate game collection manager",
            imageName: "gamecontroller.fill",
            description: "Track your games, hardware, and gaming progress all in one place.",
            backgroundColor: Color(red: 0.2, green: 0.4, blue: 0.7)
        ),
        OnboardingPage(
            title: "Add Games to Your Collection",
            subtitle: "Build your digital library",
            imageName: "plus.circle.fill",
            description: "Search for games using IGDB or add them manually. Track purchase dates, prices, and completion status.",
            backgroundColor: Color(red: 0.2, green: 0.6, blue: 0.3)
        ),
        OnboardingPage(
            title: "Create Sub-Collections",
            subtitle: "Organize related games",
            imageName: "folder.fill",
            description: "Group expansions, DLC, and related games together. Perfect for series like Pokémon or Call of Duty.",
            backgroundColor: Color(red: 0.8, green: 0.5, blue: 0.2)
        ),
        OnboardingPage(
            title: "Track Your Hardware",
            subtitle: "Monitor storage and capacity",
            imageName: "externaldrive.fill",
            description: "Add consoles, drives, and storage devices. GameLogger automatically calculates remaining space based on your installed games.",
            backgroundColor: Color(red: 0.5, green: 0.3, blue: 0.7)
        ),
        OnboardingPage(
            title: "Smart Storage Calculations",
            subtitle: "Never run out of space",
            imageName: "chart.bar.fill",
            description: "See exactly how much storage each game uses and how much space you have left on each device.",
            backgroundColor: Color(red: 0.7, green: 0.3, blue: 0.3)
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    pages[currentPage].backgroundColor.opacity(0.6),
                    pages[currentPage].backgroundColor.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Progress indicators
                HStack {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? .white : .white.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Main content
                VStack(spacing: 30) {
                    // Icon
                    Image(systemName: pages[currentPage].imageName)
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    // Title
                    Text(pages[currentPage].title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Subtitle
                    Text(pages[currentPage].subtitle)
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    // Description
                    Text(pages[currentPage].description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.2))
                            .cornerRadius(25)
                        }
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.2))
                            .cornerRadius(25)
                        }
                    } else {
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Get Started")
                                .fontWeight(.semibold)
                                .foregroundColor(pages[currentPage].backgroundColor)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(.white)
                                .cornerRadius(25)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let swipeThreshold: CGFloat = 50
                    if value.translation.width > swipeThreshold && currentPage > 0 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage -= 1
                        }
                    } else if value.translation.width < -swipeThreshold && currentPage < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }
                }
        )
    }
    
    private func completeOnboarding() {
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        showOnboarding = false
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let description: String
    let backgroundColor: Color
}

struct ContentView: View {
    @State private var showOnboarding = false
    
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
        .onAppear {
            checkOnboardingStatus()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(showOnboarding: $showOnboarding)
        }
    }
    
    private func checkOnboardingStatus() {
        // Check if user has seen onboarding before
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        if !hasSeenOnboarding {
            showOnboarding = true
        }
    }
}
