import Foundation
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    public let supabaseService = SupabaseService.shared
    
    init() {
        print("DEBUG: AuthViewModel initialized")
        // Test Supabase connection
        supabaseService.testSupabaseConnection()
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        print("DEBUG: Checking auth status")
        Task {
            let result = await supabaseService.getCurrentUser()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(let user):
                    print("DEBUG: Auth status check - User: \(String(describing: user))")
                    self.currentUser = user
                    self.isAuthenticated = user != nil
                case .failure(let error):
                    print("DEBUG: Auth status check failed - Error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        print("DEBUG: Sign in attempt with email: \(email)")
        isLoading = true
        errorMessage = nil
        
        Task {
            print("DEBUG: Calling supabaseService.signIn")
            let result = await supabaseService.signIn(email: email, password: password)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let user):
                    print("DEBUG: Sign in successful - User: \(user)")
                    self.currentUser = user
                    self.isAuthenticated = true
                case .failure(let error):
                    print("DEBUG: Sign in failed - Error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signUp(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await supabaseService.signUp(email: email, password: password)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let user):
                    self.currentUser = user
                    self.isAuthenticated = true
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signOut() {
        isLoading = true
        
        Task {
            let result = await supabaseService.signOut()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success:
                    self.currentUser = nil
                    self.isAuthenticated = false
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func resetPassword(email: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await supabaseService.resetPassword(email: email)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success:
                    // Password reset email sent successfully
                    break
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
} 