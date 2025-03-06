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
    
    var body: some View {
        Group {
            if !preferences.hasSeenWelcome {
                WelcomeView(hasSeenWelcome: $preferences.hasSeenWelcome)
                    .preferredColorScheme(preferences.isDarkMode ? .dark : .light)
            } else if !authViewModel.isAuthenticated {
                AuthView()
                    .environmentObject(authViewModel)
                    .preferredColorScheme(preferences.isDarkMode ? .dark : .light)
            } else {
                TabView(selection: $selectedTab) {
                    // Chat Tab
                    NavigationView {
                        ChatView()
                            .navigationBarItems(trailing: Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 18))
                                    .foregroundColor(.brandMint)
                            })
                    }
                    .tabItem {
                        Label("Chat", systemImage: "message.fill")
                    }
                    .tag(0)
                    
                    // Daily Inspiration Tab
                    NavigationView {
                        DailyInspirationView()
                            .navigationBarItems(trailing: Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 18))
                                    .foregroundColor(.brandMint)
                            })
                    }
                    .tabItem {
                        Label("Inspiration", systemImage: "sun.max.fill")
                    }
                    .tag(1)
                    
                    // Meditation Tab
                    NavigationView {
                        MeditationView()
                            .navigationBarItems(trailing: Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 18))
                                    .foregroundColor(.brandMint)
                            })
                    }
                    .tabItem {
                        Label("Meditation", systemImage: "heart.fill")
                    }
                    .tag(2)
                    
                    // Bible Study Tab
                    NavigationView {
                        BibleStudyView()
                            .navigationBarItems(trailing: Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 18))
                                    .foregroundColor(.brandMint)
                            })
                    }
                    .tabItem {
                        Label("Bible Study", systemImage: "book.fill")
                    }
                    .tag(3)
                    
                    // Premium Podcasts Tab (only visible for premium subscribers)
                    if preferences.isSubscriptionActive && preferences.subscriptionTier == .premium {
                        NavigationView {
                            PremiumPodcastView()
                                .navigationBarItems(trailing: Button(action: {
                                    showSettings = true
                                }) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 18))
                                        .foregroundColor(.brandMint)
                                })
                        }
                        .tabItem {
                            Label("Premium", systemImage: "star.fill")
                        }
                        .tag(4)
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(preferences: preferences, authViewModel: authViewModel)
                }
                .accentColor(.brandMint)
                .preferredColorScheme(preferences.isDarkMode ? .dark : .light)
            }
        }
        .environmentObject(preferences)
        .environmentObject(authViewModel)
        .onAppear {
            // Update user preferences if authenticated
            if let user = authViewModel.currentUser {
                preferences.userName = user.name
            }
        }
    }
}

#Preview {
    ContentView()
}
