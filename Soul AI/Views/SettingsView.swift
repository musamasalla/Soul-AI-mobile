import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var preferences: UserPreferences
    @ObservedObject var authViewModel: AuthViewModel
    @State private var username: String = ""
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        // Extract the navigation view content to a separate variable
        let content = ZStack {
            Color.AppTheme.background
                .edgesIgnoringSafeArea(.all)
            
            settingsForm
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(preferences.isDarkMode ? .dark : .light, for: .navigationBar)
        .toolbarBackground(Color.AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarItems(trailing: Button("Done") {
            presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(Color.AppTheme.brandMint))
        .preferredColorScheme(preferences.isDarkMode ? .dark : .light)
        .onAppear {
            username = preferences.userName
        }
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        
        return NavigationView {
            content
        }
    }
    
    // Extract the form into a separate computed property
    private var settingsForm: some View {
        Form {
            // Profile section
            profileSection
            
            // Account section
            accountSection
            
            // Subscription section
            subscriptionSection
            
            // Appearance section
            appearanceSection
            
            // Notifications section
            notificationsSection
            
            // About section
            aboutSection
            
            // Debug section (only in DEBUG builds)
            #if DEBUG
            debugSection
            #endif
            
            // Reset section
            resetSection
        }
        .scrollContentBackground(.hidden)
    }
    
    // Profile section
    private var profileSection: some View {
        Section(header: Text("Profile").foregroundColor(Color.AppTheme.brandMint)) {
            HStack {
                Text("Name")
                    .foregroundColor(.AppTheme.primaryText)
                Spacer()
                TextField("Your name", text: $username)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(Color.AppTheme.brandMint)
                    .onChange(of: username) { oldValue, newValue in
                        preferences.userName = newValue
                    }
            }
            
            if let email = authViewModel.currentUser?.email {
                HStack {
                    Text("Email")
                        .foregroundColor(.AppTheme.primaryText)
                    Spacer()
                    Text(email)
                        .foregroundColor(Color.AppTheme.secondaryText)
                }
            }
        }
    }
    
    // Account section
    private var accountSection: some View {
        Section(header: Text("Account").foregroundColor(Color.AppTheme.brandMint)) {
            Button(action: {
                showSignOutConfirmation = true
            }) {
                HStack {
                    Text("Sign Out")
                        .foregroundColor(.red)
                    Spacer()
                    Image(systemName: "arrow.right.square")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // Subscription section
    private var subscriptionSection: some View {
        Section(header: Text("Subscription").foregroundColor(Color.AppTheme.brandMint)) {
            HStack {
                Text("Current Plan")
                    .foregroundColor(.AppTheme.primaryText)
                Spacer()
                Text(preferences.subscriptionTier.rawValue.capitalized)
                    .foregroundColor(Color.AppTheme.brandMint.opacity(0.8))
            }
            
            if preferences.subscriptionTier != .free, let expiryDate = preferences.subscriptionExpiryDate {
                HStack {
                    Text("Renews")
                        .foregroundColor(.AppTheme.primaryText)
                    Spacer()
                    Text(expiryDate, style: .date)
                        .foregroundColor(Color.AppTheme.brandMint.opacity(0.8))
                }
            }
            
            NavigationLink(destination: SubscriptionView()) {
                if preferences.subscriptionTier == .free {
                    Text("Upgrade to Premium")
                        .foregroundColor(.AppTheme.primaryText)
                } else {
                    Text("Manage Subscription")
                        .foregroundColor(.AppTheme.primaryText)
                }
            }
        }
    }
    
    // Appearance section
    private var appearanceSection: some View {
        Section(header: Text("Appearance").foregroundColor(Color.AppTheme.brandMint)) {
            Toggle("Dark Mode", isOn: $preferences.isDarkMode)
                .foregroundColor(.AppTheme.primaryText)
                .tint(Color.AppTheme.brandMint)
                .onChange(of: preferences.isDarkMode) { oldValue, newValue in
                    print("DEBUG: SettingsView - Dark mode toggle changed to \(newValue)")
                    // Force UI update
                    NotificationCenter.default.post(name: Notification.Name("DarkModeChanged"), object: nil)
                }
            
            Picker("Font Size", selection: $preferences.fontSize) {
                ForEach(FontSize.allCases) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .foregroundColor(.AppTheme.primaryText)
            .accentColor(Color.AppTheme.brandMint)
        }
    }
    
    // Notifications section
    private var notificationsSection: some View {
        Section(header: Text("Notifications").foregroundColor(Color.AppTheme.brandMint)) {
            Toggle("Daily Inspiration", isOn: $preferences.dailyInspirationNotifications)
                .foregroundColor(.AppTheme.primaryText)
                .tint(Color.AppTheme.brandMint)
            Toggle("Prayer Reminders", isOn: $preferences.prayerReminderNotifications)
                .foregroundColor(.AppTheme.primaryText)
                .tint(Color.AppTheme.brandMint)
        }
    }
    
    // About section
    private var aboutSection: some View {
        Section(header: Text("About").foregroundColor(Color.AppTheme.brandMint)) {
            HStack {
                Text("Version")
                    .foregroundColor(.AppTheme.primaryText)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(Color.AppTheme.brandMint.opacity(0.8))
            }
            
            NavigationLink(destination: PrivacyPolicyView()) {
                Text("Privacy Policy")
                    .foregroundColor(.AppTheme.primaryText)
                }
            
            NavigationLink(destination: TermsOfServiceView()) {
                Text("Terms of Service")
                    .foregroundColor(.AppTheme.primaryText)
                }
        }
    }
    
    // Debug section for testing subscription tiers
    #if DEBUG
    private var debugSection: some View {
        Section(header: Text("Debug Options").foregroundColor(Color.AppTheme.brandMint)) {
            Button(action: {
                preferences.subscriptionTier = .free
                preferences.subscriptionExpiryDate = nil
            }) {
                Text("Set to Free Plan")
                    .foregroundColor(.AppTheme.primaryText)
            }
            
            Button(action: {
                preferences.subscriptionTier = .premium
                let calendar = Calendar.current
                if let expiryDate = calendar.date(byAdding: .month, value: 1, to: Date()) {
                    preferences.subscriptionExpiryDate = expiryDate
                }
            }) {
                Text("Set to Premium Plan")
                    .foregroundColor(.AppTheme.primaryText)
            }
            
            Button(action: {
                preferences.subscriptionTier = .guided
                let calendar = Calendar.current
                if let expiryDate = calendar.date(byAdding: .month, value: 1, to: Date()) {
                    preferences.subscriptionExpiryDate = expiryDate
                }
            }) {
                Text("Set to Guided Plan")
                    .foregroundColor(.AppTheme.primaryText)
            }
        }
    }
    #endif
    
    // Reset section
    private var resetSection: some View {
        Section {
            Button(action: {
                // Reset action
                preferences.clearUserData()
                preferences.hasSeenWelcome = false
            }) {
                Text("Reset All Settings")
                    .foregroundColor(.red)
            }
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        // Extract content to a separate variable
        let content = VStack(alignment: .leading, spacing: 20) {
            Text("Privacy Policy")
                .font(.largeTitle)
                .bold()
                .padding(.bottom)
                .foregroundColor(Color.AppTheme.brandMint)
            
            Text("Soul AI is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our application.")
                .foregroundColor(.AppTheme.primaryText)
            
            Text("Information We Collect")
                .font(.headline)
                .foregroundColor(Color.AppTheme.brandMint)
            
            Text("We collect information you provide directly to us when you use the app, including your conversations with the AI assistant. These conversations are used to improve the quality of responses and provide personalized assistance.")
                .foregroundColor(.AppTheme.primaryText)
            
            Text("How We Use Your Information")
                .font(.headline)
                .foregroundColor(Color.AppTheme.brandMint)
            
            Text("We use the information we collect to provide, maintain, and improve our services, develop new features, and protect our users.")
                .foregroundColor(.AppTheme.primaryText)
            
            Text("Data Security")
                .font(.headline)
                .foregroundColor(Color.AppTheme.brandMint)
            
            Text("We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.")
                .foregroundColor(.AppTheme.primaryText)
        }
        .padding()
        
        return ScrollView {
            content
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(Color.AppTheme.background)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        // Extract content to a separate variable
        let content = VStack(alignment: .leading, spacing: 20) {
            Text("Terms of Service")
                .font(.largeTitle)
                .bold()
                .padding(.bottom)
                .foregroundColor(Color.AppTheme.brandMint)
            
            Text("By using Soul AI, you agree to these terms. Please read them carefully.")
                .foregroundColor(.AppTheme.primaryText)
            
            Text("Acceptable Use")
                .font(.headline)
                .foregroundColor(Color.AppTheme.brandMint)
            
            Text("You agree to use Soul AI only for lawful purposes and in accordance with these Terms. You agree not to use Soul AI for any illegal or unauthorized purpose.")
                .foregroundColor(.AppTheme.primaryText)
            
            Text("Content Responsibility")
                .font(.headline)
                .foregroundColor(Color.AppTheme.brandMint)
            
            Text("You are responsible for all content you submit to Soul AI. The app is designed to provide Christian guidance, but responses should not replace professional advice from qualified religious leaders, counselors, or healthcare providers.")
                .foregroundColor(.AppTheme.primaryText)
            
            Text("Intellectual Property")
                .font(.headline)
                .foregroundColor(Color.AppTheme.brandMint)
            
            Text("Soul AI and its original content, features, and functionality are owned by the app developers and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.")
                .foregroundColor(.AppTheme.primaryText)
        }
        .padding()
        
        return ScrollView {
            content
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(Color.AppTheme.background)
    }
}

#Preview {
    SettingsView(preferences: UserPreferences(), authViewModel: AuthViewModel())
} 