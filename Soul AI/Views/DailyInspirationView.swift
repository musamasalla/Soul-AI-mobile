import SwiftUI

struct DailyInspirationView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var verse: String = ""
    @State private var reference: String = ""
    @State private var reflection: String = ""
    @State private var prayer: String = ""
    @State private var isLoading: Bool = true
    @State private var currentDate = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.AppTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Date
                        Text(formattedDate)
                            .font(.headline)
                            .foregroundColor(.AppTheme.secondaryText)
                            .padding(.top, 16)
                        
                        if isLoading {
                            VStack(spacing: 20) {
                                Spacer(minLength: 100)
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .AppTheme.brandMint))
                                    .scaleEffect(1.5)
                                Text("Loading today's inspiration...")
                                    .foregroundColor(.AppTheme.secondaryText)
                                Spacer(minLength: 100)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            // Bible verse
                            VStack(alignment: .center, spacing: 24) {
                                // Soul AI Logo
                                SoulAILogo(size: 80)
                                    .padding(.bottom, 8)
                                    .frame(maxWidth: .infinity)
                            }
                            
                            Text(verse)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.AppTheme.primaryText)
                                .lineSpacing(8)
                                .padding(.bottom, 8)
                            
                            // Reference
                            Text(reference)
                                .font(.headline)
                                .foregroundColor(.AppTheme.brandMint)
                                .padding(.bottom, 24)
                            
                            Divider()
                                .background(Color.AppTheme.secondaryText.opacity(0.2))
                                .padding(.vertical, 8)
                            
                            // Reflection
                            Text(reflection)
                                .font(.body)
                                .foregroundColor(.AppTheme.primaryText)
                                .lineSpacing(6)
                                .padding(.bottom, 24)
                            
                            // Prayer section
                            Text("Prayer")
                                .font(.headline)
                                .foregroundColor(.AppTheme.brandMint)
                                .padding(.bottom, 8)
                            
                            Text(prayer)
                                .font(.body)
                                .italic()
                                .foregroundColor(.AppTheme.primaryText)
                                .lineSpacing(6)
                                .padding(.bottom, 24)
                            
                            // Share button
                            Button(action: {
                                shareInspiration()
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16))
                                    Text("Share")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.AppTheme.brandMint.opacity(0.2))
                                .foregroundColor(.AppTheme.brandMint)
                                .cornerRadius(30)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.AppTheme.brandMint.opacity(0.5), lineWidth: 1)
                                )
                            }
                            .padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Daily Inspiration")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadDailyInspiration()
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    private func loadDailyInspiration() {
        isLoading = true
        viewModel.getDailyInspiration { receivedInspiration in
            parseInspiration(receivedInspiration)
            isLoading = false
        }
    }
    
    private func parseInspiration(_ inspiration: String) {
        // This is a simplified parser - in a real app, you might want to receive structured data
        // For now, we'll simulate parsing the content from a single string
        
        // Sample data structure (for testing)
        let components = inspiration.components(separatedBy: "\n\n")
        
        if components.count >= 1 {
            // First component is the verse
            let verseComponents = components[0].components(separatedBy: " - ")
            if verseComponents.count >= 2 {
                verse = verseComponents[0].trimmingCharacters(in: .whitespacesAndNewlines)
                reference = verseComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                verse = components[0]
                reference = "Scripture"
            }
        }
        
        if components.count >= 2 {
            // Second component is the reflection
            reflection = components[1]
        } else {
            reflection = "Reflect on God's word today and how it applies to your life."
        }
        
        if components.count >= 3 {
            // Third component might be the prayer
            prayer = components[2].replacingOccurrences(of: "Prayer: ", with: "")
        } else {
            prayer = "Dear Lord, help me to trust in Your perfect plan for my life. Give me the patience to wait on Your timing and the faith to believe in Your promises. Amen."
        }
    }
    
    private func shareInspiration() {
        let shareText = """
        Daily Inspiration from Soul AI
        
        \(verse)
        \(reference)
        
        \(reflection)
        
        Prayer:
        \(prayer)
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

struct DailyInspirationView_Previews: PreviewProvider {
    static var previews: some View {
        DailyInspirationView()
    }
} 