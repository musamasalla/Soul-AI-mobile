import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var preferences: UserPreferences
    @State private var username: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                Form {
                    Section(header: Text("Profile").foregroundColor(Color.brandMint)) {
                        HStack {
                            Text("Name")
                                .foregroundColor(.white)
                            Spacer()
                            TextField("Your name", text: $username)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.brandMint)
                                .onChange(of: username) { oldValue, newValue in
                                    preferences.userName = newValue
                                }
                        }
                    }
                    
                    Section(header: Text("Appearance").foregroundColor(Color.brandMint)) {
                        Toggle("Dark Mode", isOn: $preferences.isDarkMode)
                            .foregroundColor(.white)
                            .tint(Color.brandMint)
                        
                        Picker("Font Size", selection: $preferences.fontSize) {
                            ForEach(FontSize.allCases) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        .foregroundColor(.white)
                        .accentColor(Color.brandMint)
                    }
                    
                    Section(header: Text("About").foregroundColor(Color.brandMint)) {
                        HStack {
                            Text("Version")
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(Color.brandMint.opacity(0.8))
                        }
                        
                        NavigationLink(destination: PrivacyPolicyView()) {
                            Text("Privacy Policy")
                                .foregroundColor(.white)
                        }
                        
                        NavigationLink(destination: TermsOfServiceView()) {
                            Text("Terms of Service")
                                .foregroundColor(.white)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            // Reset welcome screen
                            preferences.hasSeenWelcome = false
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Reset Welcome Screen")
                                .foregroundColor(Color.brandMint)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(Color.brandMint))
            .preferredColorScheme(.dark)
            .onAppear {
                username = preferences.userName
            }
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
                    .foregroundColor(Color.brandMint)
                
                Text("Soul AI is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our application.")
                    .foregroundColor(.white)
                
                Text("Information We Collect")
                    .font(.headline)
                    .foregroundColor(Color.brandMint)
                
                Text("We collect information you provide directly to us when you use the app, including your conversations with the AI assistant. These conversations are used to improve the quality of responses and provide personalized assistance.")
                    .foregroundColor(.white)
                
                Text("How We Use Your Information")
                    .font(.headline)
                    .foregroundColor(Color.brandMint)
                
                Text("We use the information we collect to provide, maintain, and improve our services, develop new features, and protect our users.")
                    .foregroundColor(.white)
                
                Text("Data Security")
                    .font(.headline)
                    .foregroundColor(Color.brandMint)
                
                Text("We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.")
                    .foregroundColor(.white)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(Color.black)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
                    .foregroundColor(Color.brandMint)
                
                Text("By using Soul AI, you agree to these terms. Please read them carefully.")
                    .foregroundColor(.white)
                
                Text("Acceptable Use")
                    .font(.headline)
                    .foregroundColor(Color.brandMint)
                
                Text("You agree to use Soul AI only for lawful purposes and in accordance with these Terms. You agree not to use Soul AI for any illegal or unauthorized purpose.")
                    .foregroundColor(.white)
                
                Text("Content Responsibility")
                    .font(.headline)
                    .foregroundColor(Color.brandMint)
                
                Text("You are responsible for all content you submit to Soul AI. The app is designed to provide Christian guidance, but responses should not replace professional advice from qualified religious leaders, counselors, or healthcare providers.")
                    .foregroundColor(.white)
                
                Text("Intellectual Property")
                    .font(.headline)
                    .foregroundColor(Color.brandMint)
                
                Text("Soul AI and its original content, features, and functionality are owned by the app developers and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.")
                    .foregroundColor(.white)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(Color.black)
    }
}

#Preview {
    SettingsView(preferences: UserPreferences())
} 