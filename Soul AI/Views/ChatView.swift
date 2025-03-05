import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var preferences: UserPreferences
    @State private var showSidebar = false
    
    var body: some View {
        ZStack {
            // Background
            Color.AppTheme.background
                .ignoresSafeArea()
            
            // Main chat view
            VStack(spacing: 0) {
                // Navigation bar
                navBar
                
                // Messages list
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isProcessing {
                                TypingIndicatorView()
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewModel.messages.count) { oldCount, newCount in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isProcessing) { wasProcessing, isProcessing in
                        withAnimation {
                            scrollView.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                .background(Color.AppTheme.background)
                
                // Input area
                inputArea
            }
            
            // Sidebar overlay
            if showSidebar {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showSidebar = false
                        }
                    }
                
                HStack {
                    sidebarView
                        .frame(width: UIScreen.main.bounds.width * 0.75)
                        .transition(.move(edge: .leading))
                    
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(preferences.isDarkMode ? .dark : .light)
        .onAppear {
            viewModel.addWelcomeMessage()
        }
    }
    
    private var navBar: some View {
        HStack {
            Button(action: {
                withAnimation {
                    showSidebar = true
                }
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 20))
                    .foregroundColor(Color.brandMint)
            }
            
            Spacer()
            
            Text("Soul AI")
                .font(.headline)
                .bold()
                .foregroundColor(Color.brandMint)
            
            Spacer()
            
            Button(action: {
                // Add functionality for new chat
                viewModel.messages = []
                viewModel.addWelcomeMessage()
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20))
                    .foregroundColor(Color.brandMint)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.AppTheme.background)
        .shadow(color: Color.brandMint.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.brandMint.opacity(0.3))
            
            HStack(alignment: .bottom) {
                // Text input field
                TextField("Message Soul AI...", text: $viewModel.inputMessage, axis: .vertical)
                    .padding(12)
                    .background(Color.AppTheme.inputBackground)
                    .foregroundColor(Color.AppTheme.primaryText)
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .lineLimit(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                    )
                
                // Send button
                Button(action: {
                    viewModel.sendMessage()
                    isInputFocused = false
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                            Color.brandMint.opacity(0.3) : Color.brandMint)
                }
                .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.AppTheme.background)
        }
    }
    
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.AppTheme.secondaryText)
                
                Text("Search")
                    .foregroundColor(Color.AppTheme.secondaryText)
                
                Spacer()
            }
            .padding()
            .background(Color.AppTheme.inputBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.brandMint.opacity(0.3), lineWidth: 1)
            )
            .padding()
            
            // Main option
            HStack {
                Image(systemName: "cross.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.brandMint)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.AppTheme.background))
                
                Text("Soul AI")
                    .font(.headline)
                    .foregroundColor(Color.brandMint)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.AppTheme.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.brandMint.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
            
            // Explore option
            HStack {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 20))
                    .foregroundColor(Color.brandMint)
                
                Text("Explore Bible Verses")
                    .font(.headline)
                    .foregroundColor(Color.brandMint)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .padding(.top, 8)
            
            Divider()
                .background(Color.brandMint.opacity(0.3))
                .padding(.vertical, 8)
                .padding(.horizontal)
            
            // Recent conversations section
            Text("Recent Conversations")
                .font(.subheadline)
                .foregroundColor(Color.brandMint.opacity(0.7))
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
            // Sample conversations
            conversationRow(title: "Faith and Doubt", days: "Yesterday")
            conversationRow(title: "Prayer Guidance", days: "Yesterday")
            conversationRow(title: "Understanding Scripture", days: "2 days ago")
            conversationRow(title: "Finding Peace", days: "4 days ago")
            
            Spacer()
            
            // User info at bottom
            HStack {
                Circle()
                    .fill(Color.brandMint)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(preferences.userName.prefix(2)))
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .medium))
                    )
                
                Text(preferences.userName)
                    .foregroundColor(Color.AppTheme.primaryText)
                
                Spacer()
                
                Button(action: {
                    // Show settings
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Color.brandMint)
                        .rotationEffect(.degrees(90))
                }
            }
            .padding()
        }
        .background(Color.AppTheme.background)
        .edgesIgnoringSafeArea(.vertical)
    }
    
    private func conversationRow(title: String, days: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(days)
                .font(.caption)
                .foregroundColor(Color.AppTheme.secondaryText)
                .padding(.horizontal)
            
            HStack {
                Text(title)
                    .foregroundColor(Color.AppTheme.primaryText)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(UserPreferences())
} 