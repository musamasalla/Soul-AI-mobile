import Foundation
import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var showingAlert = false
    
    private let supabaseService: SupabaseServiceProtocol
    
    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
        
        // Defer authentication check to improve startup time
        Task {
            // Add a small delay to prioritize UI rendering
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await checkAuthStatus()
        }
    }
    
    func checkAuthStatus() {
        print("DEBUG: Checking auth status")
        Task {
            let result = await supabaseService.getCurrentUser()
            
            await MainActor.run {
                switch result {
                case .success(let user):
                    print("DEBUG: Auth status check - User: \(String(describing: user))")
                    self.currentUser = user
                    self.isAuthenticated = user != nil
                case .failure(let error):
                    print("DEBUG: Auth status check failed - Error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to check authentication status: \(error.localizedDescription)"
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
        }
    }
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter both email and password."
            self.showingAlert = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            print("DEBUG: Calling supabaseService.signIn")
            let result = await supabaseService.signIn(email: email, password: password)
            
            await MainActor.run {
                self.isLoading = false
                
                switch result {
                case .success(let user):
                    print("DEBUG: Sign in successful - User: \(user)")
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.email = ""
                    self.password = ""
                case .failure(let error):
                    print("DEBUG: Sign in failed - Error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to sign in: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
    
    func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter both email and password."
            self.showingAlert = true
            return
        }
        
        guard password == confirmPassword else {
            self.errorMessage = "Passwords do not match."
            self.showingAlert = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await supabaseService.signUp(email: email, password: password)
            
            await MainActor.run {
                self.isLoading = false
                
                switch result {
                case .success(let user):
                    print("DEBUG: Sign up successful - User: \(user)")
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.email = ""
                    self.password = ""
                    self.confirmPassword = ""
                case .failure(let error):
                    print("DEBUG: Sign up failed - Error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to sign up: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
    
    func signOut() {
        isLoading = true
        
        Task {
            let result = await supabaseService.signOut()
            
            await MainActor.run {
                self.isLoading = false
                
                switch result {
                case .success:
                    print("DEBUG: Sign out successful")
                    self.currentUser = nil
                    self.isAuthenticated = false
                case .failure(let error):
                    print("DEBUG: Sign out failed - Error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
    
    func resetPassword() {
        guard !email.isEmpty else {
            self.errorMessage = "Please enter your email address."
            self.showingAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            let result = await supabaseService.resetPassword(email: email)
            
            await MainActor.run {
                self.isLoading = false
                
                switch result {
                case .success:
                    print("DEBUG: Password reset email sent")
                    self.errorMessage = "Password reset instructions have been sent to your email."
                    self.showingAlert = true
                case .failure(let error):
                    print("DEBUG: Password reset failed - Error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to send password reset: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
} 