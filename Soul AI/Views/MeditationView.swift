import SwiftUI
import Combine

// Add a class to hold cancellables
private class CancellableHolder: ObservableObject {
    var cancellables = Set<AnyCancellable>()
}

struct MeditationView: View {
    @StateObject private var viewModel = MeditationViewModel()
    @EnvironmentObject private var preferences: UserPreferences
    @State private var isPlaying: Bool = false
    @State private var progress: Float = 0.0
    @State private var timer: Timer?
    @State private var showCopyConfirmation: Bool = false
    @State private var selectedTab = 0
    
    private var basicTopics = ["Peace", "Faith", "Hope", "Love"]
    private var premiumTopics = ["Forgiveness", "Gratitude", "Wisdom", "Patience", "Kindness", "Self-Control", "Gentleness", "Joy"]
    
    var body: some View {
        ZStack {
            // Background
            Color.AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Tab selector for Basic and Advanced meditations
                Picker("Meditation Type", selection: $selectedTab) {
                    Text("Basic").tag(0)
                    Text("Advanced").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .colorMultiply(.brandMint)
                
                // Content based on selected tab
                if selectedTab == 0 {
                    // Basic meditation content
                    basicMeditationView
                } else {
                    // Advanced meditation content (premium)
                    PremiumFeatureView(
                        featureName: "Advanced Meditation",
                        featureDescription: "Access personalized guided meditations tailored to your spiritual journey",
                        featureIcon: "heart.fill"
                    ) {
                        advancedMeditationView
                    }
                }
            }
        }
        .navigationTitle("Meditation")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Basic meditation view
    private var basicMeditationView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                Text("Christian Meditation")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.brandMint)
                    .padding(.top, 20)
                
                // Input Section
                VStack(spacing: 20) {
                    // Mood input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How are you feeling today?")
                            .font(.headline)
                            .foregroundColor(.brandMint)
                        
                        TextEditor(text: $viewModel.moodText)
                            .frame(height: 100)
                            .padding(12)
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                            )
                            .font(.body)
                    }
                    
                    // Topic selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select a topic:")
                            .font(.headline)
                            .foregroundColor(.brandMint)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(basicTopics, id: \.self) { topic in
                                    Button(action: {
                                        viewModel.selectedTopic = topic
                                    }) {
                                        Text(topic)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                viewModel.selectedTopic == topic ?
                                                Color.brandMint :
                                                Color(.systemGray6).opacity(0.3)
                                            )
                                            .foregroundColor(
                                                viewModel.selectedTopic == topic ?
                                                .black :
                                                .white
                                            )
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Generate button
                    Button(action: {
                        viewModel.generateMeditation()
                    }) {
                        HStack {
                            Text("Generate Meditation")
                                .font(.headline)
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .padding(.leading, 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandMint)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.7 : 1.0)
                }
                .padding(.horizontal)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 5)
                }
                
                // Display meditation content if available
                if let meditation = viewModel.meditation {
                    VStack(spacing: 16) {
                        Text(meditation.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.brandMint)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text(meditation.content)
                            .font(.body)
                            .foregroundColor(.white)
                            .lineSpacing(6)
                            .padding()
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(12)
                        
                        // Share button
                        Button(action: {
                            let textToShare = "\(meditation.title)\n\n\(meditation.content)"
                            let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
                            
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                rootViewController.present(activityVC, animated: true, completion: nil)
                            }
                        }) {
                            Label("Share Meditation", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6).opacity(0.3))
                                .foregroundColor(.brandMint)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // Advanced meditation view (premium)
    private var advancedMeditationView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                Text("Advanced Christian Meditation")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.brandMint)
                    .padding(.top, 20)
                
                // Input Section
                VStack(spacing: 20) {
                    // Mood input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How are you feeling today?")
                            .font(.headline)
                            .foregroundColor(.brandMint)
                        
                        TextEditor(text: $viewModel.moodText)
                            .frame(height: 100)
                            .padding(12)
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                            )
                            .font(.body)
                    }
                    
                    // Scripture input (premium feature)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Specific scripture (optional):")
                            .font(.headline)
                            .foregroundColor(.brandMint)
                        
                        TextField("e.g., Psalm 23, John 3:16", text: $viewModel.scriptureReference)
                            .padding()
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                            )
                    }
                    
                    // Duration selection (premium feature)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Meditation duration:")
                            .font(.headline)
                            .foregroundColor(.brandMint)
                        
                        Picker("Duration", selection: $viewModel.meditationDuration) {
                            Text("5 minutes").tag(5)
                            Text("10 minutes").tag(10)
                            Text("15 minutes").tag(15)
                            Text("20 minutes").tag(20)
                            Text("30 minutes").tag(30)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .colorMultiply(.brandMint)
                    }
                    
                    // Topic selection with premium topics
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select a topic:")
                            .font(.headline)
                            .foregroundColor(.brandMint)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(basicTopics + premiumTopics, id: \.self) { topic in
                                    Button(action: {
                                        viewModel.selectedTopic = topic
                                    }) {
                                        Text(topic)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                viewModel.selectedTopic == topic ?
                                                Color.brandMint :
                                                Color(.systemGray6).opacity(0.3)
                                            )
                                            .foregroundColor(
                                                viewModel.selectedTopic == topic ?
                                                .black :
                                                .white
                                            )
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Generate button
                    Button(action: {
                        viewModel.generateAdvancedMeditation()
                    }) {
                        HStack {
                            Text("Generate Advanced Meditation")
                                .font(.headline)
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .padding(.leading, 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandMint)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.7 : 1.0)
                }
                .padding(.horizontal)
                
                // Display meditation content if available
                if let meditation = viewModel.meditation {
                    VStack(spacing: 16) {
                        Text(meditation.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.brandMint)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text(meditation.content)
                            .font(.body)
                            .foregroundColor(.white)
                            .lineSpacing(6)
                            .padding()
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(12)
                        
                        // Share button
                        Button(action: {
                            let textToShare = "\(meditation.title)\n\n\(meditation.content)"
                            let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
                            
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                rootViewController.present(activityVC, animated: true, completion: nil)
                            }
                        }) {
                            Label("Share Meditation", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6).opacity(0.3))
                                .foregroundColor(.brandMint)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .padding(.bottom, 40)
        }
    }
}

// Custom paragraph card component
struct ParagraphCard: View {
    let text: String
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.body)
                .foregroundColor(.white)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.brandMint.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.brandMint.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    MeditationView()
} 