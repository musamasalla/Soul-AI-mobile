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
    @State private var showingDurationSelector = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.AppTheme.background.edgesIgnoringSafeArea(.all)
                
                VStack {
                    if viewModel.showPodcast {
                        // Podcast player view
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text(viewModel.podcast?.title ?? "Podcast")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color.AppTheme.primaryText)
                                    .padding(.top)
                                
                                // Player controls
                                HStack {
                                    Button(action: {
                                        if viewModel.isPlaying {
                                            viewModel.stopPlayback()
                                        } else {
                                            if let podcast = viewModel.podcast {
                                                viewModel.playPodcast(podcast)
                                            }
                                        }
                                    }) {
                                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(Color.brandMint)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("Duration: \(viewModel.podcast?.duration ?? 0) min")
                                            .font(.subheadline)
                                            .foregroundColor(Color.AppTheme.secondaryText)
                                        
                                        if let date = viewModel.podcast?.createdAt {
                                            Text("Created: \(date.formatted(date: .abbreviated, time: .shortened))")
                                                .font(.subheadline)
                                                .foregroundColor(Color.AppTheme.secondaryText)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical)
                                
                                Divider()
                                    .background(Color.brandMint.opacity(0.5))
                                
                                Text("Content")
                                    .font(.headline)
                                    .foregroundColor(Color.brandMint)
                                
                                Text(viewModel.podcast?.content ?? "")
                                    .font(.body)
                                    .foregroundColor(Color.AppTheme.primaryText)
                                    .lineSpacing(6)
                                
                                if !viewModel.scriptureReferences.isEmpty {
                                    Divider()
                                        .background(Color.brandMint.opacity(0.5))
                                        .padding(.vertical)
                                    
                                    Text("Scripture References")
                                        .font(.headline)
                                        .foregroundColor(Color.brandMint)
                                    
                                    ForEach(viewModel.scriptureReferences, id: \.self) { reference in
                                        Text(reference)
                                            .font(.subheadline)
                                            .foregroundColor(Color.AppTheme.primaryText)
                                            .padding(.vertical, 2)
                                    }
                                }
                                
                                Spacer(minLength: 40)
                                
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
                            .padding()
                        }
                    } else {
                        // Podcast generator view
                        ScrollView {
                            VStack(spacing: 25) {
                                Text("Generate a Podcast")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color.brandMint)
                                    .padding(.top)
                                
                                // Topic selector
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
                                
                                // Duration selector
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Duration")
                                        .font(.headline)
                                        .foregroundColor(Color.AppTheme.primaryText)
                                    
                                    Button(action: {
                                        showingDurationSelector = true
                                    }) {
                                        HStack {
                                            Text("\(viewModel.podcastDuration) minutes")
                                                .foregroundColor(Color.AppTheme.primaryText)
                                            
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
                                
                                // Scripture reference selector (for premium)
                                if preferences.subscriptionTier != .free {
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
                                
                                Spacer(minLength: 30)
                                
                                // Generate button
                                Button(action: {
                                    if viewModel.selectedTopic.isEmpty {
                                        viewModel.selectedTopic = viewModel.getRandomSelection(from: PodcastTopics.allTopics)
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
                                
                                if !viewModel.errorMessage.isEmpty {
                                    Text(viewModel.errorMessage)
                                        .foregroundColor(.red)
                                        .padding()
                                }
                                
                                // Previous podcasts
                                if !viewModel.podcasts.isEmpty {
                                    VStack(alignment: .leading, spacing: 15) {
                                        Text("Previous Podcasts")
                                            .font(.headline)
                                            .foregroundColor(Color.AppTheme.primaryText)
                                            .padding(.horizontal)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 15) {
                                                ForEach(viewModel.podcasts) { podcast in
                                                    PodcastCard(podcast: podcast, isPlaying: viewModel.isPlaying && viewModel.currentPodcastId == podcast.id) {
                                                        if viewModel.isPlaying && viewModel.currentPodcastId == podcast.id {
                                                            viewModel.stopPlayback()
                                                        } else {
                                                            viewModel.playPodcast(podcast)
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
                            .padding(.bottom, 30)
                        }
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
            .sheet(isPresented: $showingDurationSelector) {
                DurationSelectorView(selectedDuration: $viewModel.podcastDuration)
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

struct PodcastCard: View {
    let podcast: Podcast
    let isPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(podcast.title)
                .font(.headline)
                .foregroundColor(Color.AppTheme.primaryText)
                .lineLimit(2)
            
            HStack {
                Text("\(podcast.duration) min")
                    .font(.caption)
                    .foregroundColor(Color.AppTheme.secondaryText)
                
                Spacer()
                
                Button(action: action) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color.brandMint)
                }
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

struct DurationSelectorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDuration: Int
    @EnvironmentObject private var preferences: UserPreferences
    
    let durations = [5, 10, 15, 20, 30]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.AppTheme.background.edgesIgnoringSafeArea(.all)
                
                List {
                    ForEach(durations, id: \.self) { duration in
                        Button(action: {
                            selectedDuration = duration
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text("\(duration) minutes")
                                    .foregroundColor(Color.AppTheme.primaryText)
                                
                                Spacer()
                                
                                if selectedDuration == duration {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.brandMint)
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.AppTheme.background)
            }
            .navigationTitle("Select Duration")
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
                        // Testament selection
                        List {
                            ForEach(BibleData.testaments, id: \.self) { testament in
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
                    } else if selectionStep == 1 {
                        // Book selection
                        List {
                            ForEach(BibleData.books[selectedTestament] ?? [], id: \.self) { book in
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
                    } else {
                        // Chapter selection
                        let chapters = BibleData.chapters[selectedBook] ?? 1
                        List {
                            ForEach(1...chapters, id: \.self) { chapter in
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
}

struct PodcastView_Previews: PreviewProvider {
    static var previews: some View {
        PodcastView()
            .environmentObject(UserPreferences())
    }
} 