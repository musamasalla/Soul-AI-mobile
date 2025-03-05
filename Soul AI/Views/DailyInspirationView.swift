import SwiftUI
import UIKit

struct DailyInspirationView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @StateObject private var viewModel = DailyInspirationViewModel()
    @State private var showShareSheet = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.AppTheme.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.brandMint))
                            .scaleEffect(1.5)
                            .padding(.top, 100)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Daily Inspiration")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color.brandMint)
                                    .padding(.top, 20)
                                
                                Text(viewModel.currentDate)
                                    .font(.subheadline)
                                    .foregroundColor(Color.AppTheme.secondaryText)
                                
                                Divider()
                                    .background(Color.brandMint.opacity(0.5))
                                
                                Text(viewModel.inspiration.verse)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Color.AppTheme.primaryText)
                                    .padding(.vertical, 10)
                                    .lineSpacing(6)
                                
                                Text(viewModel.inspiration.reference)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.brandMint)
                                
                                Divider()
                                    .background(Color.brandMint.opacity(0.5))
                                    .padding(.vertical, 10)
                                
                                Text(viewModel.inspiration.reflection)
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.AppTheme.primaryText)
                                    .lineSpacing(6)
                                
                                Text("Prayer")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color.brandMint)
                                    .padding(.top, 20)
                                
                                Text(viewModel.inspiration.prayer)
                                    .font(.system(size: 18, weight: .regular, design: .serif))
                                    .italic()
                                    .foregroundColor(Color.AppTheme.primaryText)
                                    .lineSpacing(6)
                                    .padding(.bottom, 30)
                                
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        showShareSheet = true
                                    }) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Share")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.brandMint)
                                        .cornerRadius(20)
                                    }
                                    Spacer()
                                }
                                .padding(.bottom, 20)
                            }
                            .padding(.horizontal)
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
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [viewModel.shareText])
            }
            .onAppear {
                viewModel.loadInspiration()
            }
        }
        .preferredColorScheme(preferences.isDarkMode ? .dark : .light)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct DailyInspirationView_Previews: PreviewProvider {
    static var previews: some View {
        DailyInspirationView()
            .environmentObject(UserPreferences())
    }
} 