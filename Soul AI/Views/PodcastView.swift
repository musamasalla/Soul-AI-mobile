import SwiftUI
import Combine
import AVFoundation

// Add a class to hold cancellables
private class PodcastCancellableHolder: ObservableObject {
    var cancellables = Set<AnyCancellable>()
}

struct PodcastView: View {
    @StateObject private var viewModel = PodcastViewModel()
    
    var body: some View {
        ZStack {
            // Background
            Color.brandBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Text("Bible Study")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.brandMint)
                    .padding(.top, 20)
                
                // Selection controls
                VStack(spacing: 15) {
                    // Testament selection
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Testament:")
                            .font(.headline)
                            .foregroundColor(.brandMint)
                        
                        Picker("Testament", selection: $viewModel.selectedTestament) {
                            ForEach(BibleStructure.structure.map { $0.name }, id: \.self) { testament in
                                Text(testament).tag(testament)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(8)
                        .background(Color(.systemGray6).opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                    // Book selection
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Book:")
                            .font(.headline)
                            .foregroundColor(.brandMint)
                        
                        Picker("Book", selection: $viewModel.selectedBook) {
                            Text("Select a book").tag("")
                            ForEach(viewModel.availableBooks.map { $0.name }, id: \.self) { book in
                                Text(book).tag(book)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(8)
                        .background(Color(.systemGray6).opacity(0.3))
                        .cornerRadius(8)
                        .disabled(viewModel.selectedTestament.isEmpty)
                    }
                    
                    // Chapter selection
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Chapter:")
                            .font(.headline)
                            .foregroundColor(.brandMint)
                        
                        Picker("Chapter", selection: $viewModel.selectedChapter) {
                            Text("Select a chapter").tag("")
                            ForEach(1...max(1, viewModel.availableChapters), id: \.self) { chapter in
                                Text("\(chapter)").tag("\(chapter)")
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(8)
                        .background(Color(.systemGray6).opacity(0.3))
                        .cornerRadius(8)
                        .disabled(viewModel.selectedBook.isEmpty)
                    }
                    
                    HStack {
                        // Random selection button
                        Button(action: {
                            viewModel.getRandomSelection()
                        }) {
                            Label("Random", systemImage: "shuffle")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 15)
                                .background(Color.brandMint.opacity(0.7))
                                .cornerRadius(8)
                        }
                        
                        // Generate button
                        Button(action: {
                            viewModel.generatePodcast()
                        }) {
                            HStack {
                                Text("Generate Bible Study")
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                }
                            }
                            .foregroundColor(.black)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 15)
                            .background(Color.brandMint)
                            .cornerRadius(8)
                        }
                        .disabled(viewModel.isLoading || viewModel.selectedBook.isEmpty || viewModel.selectedChapter.isEmpty)
                        .opacity((viewModel.isLoading || viewModel.selectedBook.isEmpty || viewModel.selectedChapter.isEmpty) ? 0.5 : 1.0)
                    }
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 5)
                    }
                }
                .padding(.horizontal)
                
                // Podcast list
                if viewModel.podcasts.isEmpty && !viewModel.isLoading {
                    VStack {
                        Spacer()
                        Image(systemName: "book.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.bottom, 10)
                        Text("No Bible studies generated yet.")
                            .foregroundColor(.gray)
                        Text("Create your first one above!")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(viewModel.podcasts) { podcast in
                                PodcastItemView(podcast: podcast, viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            // Stop playback when leaving the view
            viewModel.stopPlayback()
        }
    }
}

struct PodcastItemView: View {
    let podcast: PodcastEntry
    @ObservedObject var viewModel: PodcastViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(podcast.title)
                        .font(.headline)
                        .foregroundColor(.brandMint)
                    
                    Text(podcast.chapter)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(formatDate(podcast.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if podcast.status == .ready, podcast.audioUrl != nil {
                    Button(action: {
                        viewModel.playPodcast(podcast: podcast)
                    }) {
                        Image(systemName: viewModel.isPlaying && viewModel.currentPodcastId == podcast.id ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.brandMint)
                    }
                } else if podcast.status == .generating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .brandMint))
                        .scaleEffect(1.0)
                } else {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                }
            }
            
            if !podcast.description.isEmpty {
                Text(podcast.description)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(3)
            }
            
            // Audio visualization (only when playing)
            if podcast.status == .ready && podcast.audioUrl != nil && viewModel.isPlaying && viewModel.currentPodcastId == podcast.id {
                HStack(spacing: 2) {
                    ForEach(0..<10, id: \.self) { index in
                        AudioBar(index: index)
                    }
                }
                .frame(height: 30)
                .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.2))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct AudioBar: View {
    let index: Int
    @State private var height: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.brandMint)
            .frame(width: 3, height: height)
            .onAppear {
                // Randomize the initial height
                height = CGFloat.random(in: 5...20)
                
                // Animate the height changes
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever().delay(Double(index) * 0.05)) {
                    height = CGFloat.random(in: 5...30)
                }
            }
    }
}

#Preview {
    PodcastView()
} 