//
//  ContentView.swift
//  Soul AI
//
//  Created by Musa Masalla on 2025/03/03.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var preferences = UserPreferences()
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showSettings = false
    @State private var selectedTab = 0
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Group {
            if !preferences.hasSeenWelcome {
                WelcomeView(hasSeenWelcome: $preferences.hasSeenWelcome)
                    .preferredColorScheme(themeManager.colorScheme)
                    .onAppear {
                        print("DEBUG: ContentView - Showing WelcomeView")
                    }
            } else if !authViewModel.isAuthenticated {
                AuthView()
                    .environmentObject(authViewModel)
                    .preferredColorScheme(themeManager.colorScheme)
                    .onAppear {
                        print("DEBUG: ContentView - Showing AuthView because isAuthenticated is \(authViewModel.isAuthenticated)")
                    }
            } else {
                mainTabView
                    .onAppear {
                        print("DEBUG: ContentView - Showing TabView because isAuthenticated is \(authViewModel.isAuthenticated)")
                    }
            }
        }
        .environmentObject(preferences)
        .environmentObject(authViewModel)
        .preferredColorScheme(themeManager.colorScheme)
        .task {
            // Defer authentication check to after view appears
            if authViewModel.isAuthenticated, let user = authViewModel.currentUser {
                preferences.userName = user.name
            }
            
            print("DEBUG: ContentView appeared with colorScheme: \(themeManager.colorScheme)")
        }
    }
    
    // Extract TabView to a computed property
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // Chat Tab
            NavigationView {
                LazyView(ChatView())
                    .navigationBarItems(trailing: settingsButton)
            }
            .preferredColorScheme(themeManager.colorScheme)
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            .tag(0)
            
            // Daily Inspiration Tab
            NavigationView {
                LazyView(DailyInspirationView())
                    .navigationBarItems(trailing: settingsButton)
            }
            .preferredColorScheme(themeManager.colorScheme)
            .tabItem {
                Label("Inspiration", systemImage: "sun.max.fill")
            }
            .tag(1)
            
            // Meditation Tab
            NavigationView {
                LazyView(MeditationView())
                    .navigationBarItems(trailing: settingsButton)
            }
            .preferredColorScheme(themeManager.colorScheme)
            .tabItem {
                Label("Meditation", systemImage: "heart.fill")
            }
            .tag(2)
            
            // Bible Study Tab
            NavigationView {
                LazyView(BibleStudyView())
                    .navigationBarItems(trailing: settingsButton)
            }
            .preferredColorScheme(themeManager.colorScheme)
            .tabItem {
                Label("Bible Study", systemImage: "book.fill")
            }
            .tag(3)
            
            // Premium Podcasts Tab (always included but conditionally shown)
            NavigationView {
                LazyView(
                    Group {
                        if preferences.isSubscriptionActive && preferences.subscriptionTier == .premium {
                            PremiumPodcastView()
                                .navigationBarItems(trailing: settingsButton)
                        } else {
                            // Placeholder view when premium is not active
                            VStack {
                                Text("Premium Content")
                                    .font(.title)
                                Text("Subscribe to access premium podcasts")
                                    .foregroundColor(.secondary)
                                Button("Subscribe Now") {
                                    // Show subscription view
                                    selectedTab = 0 // Switch to main tab
                                    showSettings = true // Open settings which has subscription options
                                }
                                .padding()
                                .background(Color.AppTheme.brandMint)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.top, 20)
                            }
                            .padding()
                            .navigationBarItems(trailing: settingsButton)
                        }
                    }
                )
            }
            .preferredColorScheme(themeManager.colorScheme)
            .tabItem {
                Label("Premium", systemImage: "star.fill")
            }
            .tag(4)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(preferences: preferences, authViewModel: authViewModel)
        }
        .accentColor(.brandMint)
        .preferredColorScheme(themeManager.colorScheme)
    }
    
    // Extract settings button to a computed property
    private var settingsButton: some View {
        Button(action: {
            showSettings = true
        }) {
            Image(systemName: "gear")
                .font(.system(size: 18))
                .foregroundColor(.AppTheme.brandMint)
        }
    }
}

// Add a LazyView struct to defer loading of views
struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}

#Preview {
    ContentView()
}
