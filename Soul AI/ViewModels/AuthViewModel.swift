import Foundation
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let supabaseService = SupabaseService.shared
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        Task {
            let result = await supabaseService.getCurrentUser()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(let user):
                    self.currentUser = user
                    self.isAuthenticated = user != nil
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await supabaseService.signIn(email: email, password: password)
            
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