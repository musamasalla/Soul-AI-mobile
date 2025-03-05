import SwiftUI
import Combine
import AVFoundation

// Add a class to hold cancellables
private class PodcastCancellableHolder: ObservableObject {
    var cancellables = Set<AnyCancellable>()
}

struct PodcastView: View {
    @StateObject private var viewModel = PodcastViewModel()
    @EnvironmentObject private var preferences: UserPreferences
    @State private var showingSettings = false
    @State private var showingScriptureSelector = false
    @State private var showingTopicSelector = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.AppTheme.background.edgesIgnoringSafeArea(.all)
                
                VStack {
                    if viewModel.showPodcast {
                        PodcastPlayerView(viewModel: viewModel)
                    } else {
                        PodcastGeneratorView(
                            viewModel: viewModel,
                            preferences: preferences,
                            showingTopicSelector: $showingTopicSelector,
                            showingScriptureSelector: $showingScriptureSelector
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(preferences.isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbarBackground(Color.AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarItems(
                trailing: Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(Color.brandMint)
                }
            )
            .sheet(isPresented: $showingSettings) {
                SettingsView(preferences: preferences)
                    .environmentObject(preferences)
            }
            .sheet(isPresented: $showingTopicSelector) {
                TopicSelectorView(selectedTopic: $viewModel.selectedTopic)
            }
            .sheet(isPresented: $showingScriptureSelector) {
                ScriptureSelectorView(
                    selectedTestament: $viewModel.selectedTestament,
                    selectedBook: $viewModel.selectedBook,
                    selectedChapter: $viewModel.selectedChapter
                )
            }
            .onAppear {
                viewModel.loadPodcasts()
            }
        }
        .preferredColorScheme(preferences.isDarkMode ? .dark : .light)
    }
}

// MARK: - Podcast Player View
struct PodcastPlayerView: View {
    @ObservedObject var viewModel: PodcastViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                podcastHeader
                playerControls
                
                Divider()
                    .background(Color.brandMint.opacity(0.5))
                
                contentSection
                
                if !viewModel.scriptureReferences.isEmpty {
                    scriptureSection
                }
                
                Spacer(minLength: 40)
                
                newPodcastButton
            }
            .padding()
        }
    }
    
    private var podcastHeader: some View {
        Text(viewModel.podcast?.title ?? "Podcast")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(Color.AppTheme.primaryText)
            .padding(.top)
    }
    
    private var playerControls: some View {
        VStack(spacing: 16) {
            // Audio player with wave animation
            HStack {
                AudioWaveAnimation(isPlaying: viewModel.isPlaying) {
                    if viewModel.isPlaying {
                        viewModel.stopPlayback()
                    } else {
                        // Check if there's a podcast entry with the current ID
                        if let podcastId = viewModel.currentPodcastId,
                           let podcastEntry = viewModel.podcasts.first(where: { $0.id == podcastId }) {
                            viewModel.playPodcast(podcast: podcastEntry)
                        }
                    }
                }
                
                Spacer()
                
                // Duration info
                Text("Duration: \(viewModel.podcast?.duration ?? 0) min")
                    .font(.subheadline)
                    .foregroundColor(Color.AppTheme.secondaryText)
                    .padding(.trailing, 8)
            }
            
            // Status text
            Text(viewModel.isPlaying ? "Playing Bible study..." : "Bible study ready to play")
                .font(.subheadline)
                .foregroundColor(Color.AppTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
        }
        .padding(.vertical, 8)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Content")
                .font(.headline)
                .foregroundColor(Color.brandMint)
            
            Text(viewModel.podcast?.content ?? "")
                .font(.body)
                .foregroundColor(Color.AppTheme.primaryText)
                .lineSpacing(6)
        }
    }
    
    private var scriptureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .background(Color.brandMint.opacity(0.5))
                .padding(.vertical)
            
            Text("Scripture References")
                .font(.headline)
                .foregroundColor(Color.brandMint)
            
            Text(viewModel.scriptureReferences)
                .font(.subheadline)
                .foregroundColor(Color.AppTheme.primaryText)
                .padding(.vertical, 2)
        }
    }
    
    private var newPodcastButton: some View {
        Button(action: {
            viewModel.showPodcast = false
        }) {
            Text("Generate New Podcast")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.brandMint)
                .cornerRadius(10)
        }
    }
}

// MARK: - Podcast Generator View
struct PodcastGeneratorView: View {
    @ObservedObject var viewModel: PodcastViewModel
    var preferences: UserPreferences
    @Binding var showingTopicSelector: Bool
    @Binding var showingScriptureSelector: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Generate a Podcast")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.brandMint)
                    .padding(.top)
                
                topicSelector
                
                // Duration info with range
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration")
                        .font(.headline)
                        .foregroundColor(Color.AppTheme.primaryText)
                    
                    HStack {
                        Text("1-5 minutes")
                            .foregroundColor(Color.AppTheme.primaryText)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.AppTheme.cardBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                if preferences.subscriptionTier != .free {
                    scriptureSelector
                }
                
                Spacer(minLength: 30)
                
                generateButton
                
                if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if !viewModel.podcasts.isEmpty {
                    previousPodcasts
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    private var topicSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Topic")
                .font(.headline)
                .foregroundColor(Color.AppTheme.primaryText)
            
            Button(action: {
                showingTopicSelector = true
            }) {
                HStack {
                    Text(viewModel.selectedTopic.isEmpty ? "Select a topic" : viewModel.selectedTopic)
                        .foregroundColor(viewModel.selectedTopic.isEmpty ? Color.AppTheme.secondaryText : Color.AppTheme.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color.AppTheme.secondaryText)
                }
                .padding()
                .background(Color.AppTheme.cardBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var scriptureSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Scripture Reference")
                    .font(.headline)
                    .foregroundColor(Color.AppTheme.primaryText)
                
                Text("(Premium)")
                    .font(.caption)
                    .foregroundColor(Color.brandMint)
            }
            
            Button(action: {
                showingScriptureSelector = true
            }) {
                HStack {
                    if viewModel.selectedTestament.isEmpty || viewModel.selectedBook.isEmpty || viewModel.selectedChapter.isEmpty {
                        Text("Select scripture")
                            .foregroundColor(Color.AppTheme.secondaryText)
                    } else {
                        Text("\(viewModel.selectedBook) \(viewModel.selectedChapter)")
                            .foregroundColor(Color.AppTheme.primaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color.AppTheme.secondaryText)
                }
                .padding()
                .background(Color.AppTheme.cardBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var generateButton: some View {
        Button(action: {
            if viewModel.selectedTopic.isEmpty {
                viewModel.selectedTopic = PodcastTopics.allTopics.randomElement() ?? "Faith"
            }
            
            if preferences.subscriptionTier != .free &&
                !viewModel.selectedTestament.isEmpty &&
                !viewModel.selectedBook.isEmpty &&
                !viewModel.selectedChapter.isEmpty {
                viewModel.generatePremiumPodcast()
            } else {
                viewModel.generatePodcast()
            }
        }) {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Generate Podcast")
                    .font(.headline)
            }
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.brandMint)
        .cornerRadius(10)
        .padding(.horizontal)
        .disabled(viewModel.isLoading)
    }
    
    private var previousPodcasts: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Previous Podcasts")
                .font(.headline)
                .foregroundColor(Color.AppTheme.primaryText)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.podcasts) { podcast in
                        PodcastCard(
                            podcast: podcast,
                            isPlaying: viewModel.isPlaying && viewModel.currentPodcastId == podcast.id
                        ) {
                            if viewModel.isPlaying && viewModel.currentPodcastId == podcast.id {
                                viewModel.stopPlayback()
                            } else {
                                viewModel.playPodcast(podcast: podcast)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }
}

struct PodcastCard: View {
    let podcast: PodcastEntry
    let isPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(podcast.title)
                .font(.headline)
                .foregroundColor(Color.AppTheme.primaryText)
                .lineLimit(2)
            
            HStack {
                Text(podcast.chapter)
                    .font(.caption)
                    .foregroundColor(Color.AppTheme.secondaryText)
                
                Spacer()
                
                AudioWaveAnimation(isPlaying: isPlaying, color: .brandMint, onTap: action)
                    .scaleEffect(0.7)
                    .frame(width: 60)
            }
        }
        .padding()
        .frame(width: 200, height: 100)
        .background(Color.AppTheme.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
        )
    }
}

struct TopicSelectorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedTopic: String
    @State private var searchText = ""
    @EnvironmentObject private var preferences: UserPreferences
    
    var filteredTopics: [String] {
        if searchText.isEmpty {
            return PodcastTopics.allTopics
        } else {
            return PodcastTopics.allTopics.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.AppTheme.background.edgesIgnoringSafeArea(.all)
                
                VStack {
                    SearchBar(text: $searchText, placeholder: "Search topics")
                        .padding()
                    
                    List {
                        ForEach(filteredTopics, id: \.self) { topic in
                            Button(action: {
                                selectedTopic = topic
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text(topic)
                                    .foregroundColor(Color.AppTheme.primaryText)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.AppTheme.background)
                }
            }
            .navigationTitle("Select Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(preferences.isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbarBackground(Color.AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(Color.brandMint))
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.AppTheme.secondaryText)
            
            TextField(placeholder, text: $text)
                .foregroundColor(Color.AppTheme.primaryText)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.AppTheme.secondaryText)
                }
            }
        }
        .padding(10)
        .background(Color.AppTheme.inputBackground)
        .cornerRadius(10)
    }
}

struct ScriptureSelectorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedTestament: String
    @Binding var selectedBook: String
    @Binding var selectedChapter: String
    @State private var selectionStep = 0
    @EnvironmentObject private var preferences: UserPreferences
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.AppTheme.background.edgesIgnoringSafeArea(.all)
                
                VStack {
                    if selectionStep == 0 {
                        testamentSelectionView
                    } else if selectionStep == 1 {
                        bookSelectionView
                    } else {
                        chapterSelectionView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(preferences.isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbarBackground(Color.AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarItems(
                leading: selectionStep > 0 ? Button("Back") {
                    selectionStep -= 1
                }
                .foregroundColor(Color.brandMint) : nil,
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color.brandMint)
            )
        }
    }
    
    private var testamentSelectionView: some View {
        List {
            ForEach(BibleStructure.structure.map { $0.name }, id: \.self) { testament in
                Button(action: {
                    selectedTestament = testament
                    selectionStep = 1
                }) {
                    Text(testament)
                        .foregroundColor(Color.AppTheme.primaryText)
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.AppTheme.background)
        .navigationTitle("Select Testament")
    }
    
    private var bookSelectionView: some View {
        List {
            let books = BibleStructure.structure.first(where: { $0.name == selectedTestament })?.books.map { $0.name } ?? []
            ForEach(books, id: \.self) { book in
                Button(action: {
                    selectedBook = book
                    selectionStep = 2
                }) {
                    Text(book)
                        .foregroundColor(Color.AppTheme.primaryText)
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.AppTheme.background)
        .navigationTitle("Select Book")
    }
    
    private var chapterSelectionView: some View {
        List {
            let chapterCount = BibleStructure.structure
                .first(where: { $0.name == selectedTestament })?
                .books.first(where: { $0.name == selectedBook })?
                .chapters ?? 0
            
            ForEach(1...chapterCount, id: \.self) { chapter in
                Button(action: {
                    selectedChapter = String(chapter)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Chapter \(chapter)")
                        .foregroundColor(Color.AppTheme.primaryText)
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.AppTheme.background)
        .navigationTitle("Select Chapter")
    }
}

struct PodcastView_Previews: PreviewProvider {
    static var previews: some View {
        PodcastView()
            .environmentObject(UserPreferences())
    }
} 