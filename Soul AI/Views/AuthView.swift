import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showForgotPassword = false
    @State private var forgotPasswordEmail = ""
    @State private var showResetPasswordConfirmation = false
    
    var body: some View {
        ZStack {
            Color.AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo and title
                VStack(spacing: 16) {
                    SoulAILogo(size: 80)
                    
                    Text("Soul AI")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.AppTheme.brandMint)
                    
                    Text(isSignUp ? "Create your account" : "Welcome back")
                        .font(.headline)
                        .foregroundColor(.AppTheme.primaryText)
                }
                .padding(.top, 60)
                
                // Form
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.AppTheme.secondaryText)
                        
                        TextField("Enter your email", text: $email)
                            .padding()
                            .background(Color.AppTheme.inputBackground)
                            .cornerRadius(10)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.AppTheme.secondaryText)
                        
                        SecureField("Enter your password", text: $password)
                            .padding()
                            .background(Color.AppTheme.inputBackground)
                            .cornerRadius(10)
                    }
                    
                    // Forgot password button (only for sign in)
                    if !isSignUp {
                        Button(action: {
                            forgotPasswordEmail = email
                            showForgotPassword = true
                        }) {
                            Text("Forgot password?")
                                .font(.subheadline)
                                .foregroundColor(.AppTheme.brandMint)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, -10)
                    }
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    }
                    
                    // Sign in/up button
                    Button(action: {
                        if isSignUp {
                            viewModel.signUp(email: email, password: password)
                        } else {
                            viewModel.signIn(email: email, password: password)
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.AppTheme.brandMint)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)
                    .opacity((email.isEmpty || password.isEmpty || viewModel.isLoading) ? 0.7 : 1)
                    
                    // Toggle between sign in and sign up
                    Button(action: {
                        isSignUp.toggle()
                        viewModel.errorMessage = nil
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                            .foregroundColor(.AppTheme.brandMint)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            
            // Forgot password sheet
            .sheet(isPresented: $showForgotPassword) {
                forgotPasswordView
            }
            
            // Reset password confirmation alert
            .alert("Password Reset", isPresented: $showResetPasswordConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("If an account exists with that email, we've sent instructions to reset your password.")
            }
        }
    }
    
    private var forgotPasswordView: some View {
        ZStack {
            Color.AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.AppTheme.primaryText)
                
                Text("Enter your email address and we'll send you instructions to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Email", text: $forgotPasswordEmail)
                    .padding()
                    .background(Color.AppTheme.inputBackground)
                    .cornerRadius(10)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                
                Button(action: {
                    viewModel.resetPassword(email: forgotPasswordEmail)
                    showForgotPassword = false
                    showResetPasswordConfirmation = true
                }) {
                    Text("Send Reset Instructions")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.AppTheme.brandMint)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(forgotPasswordEmail.isEmpty)
                .opacity(forgotPasswordEmail.isEmpty ? 0.7 : 1)
                
                Button(action: {
                    showForgotPassword = false
                }) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.AppTheme.brandMint)
                }
                .padding(.top, 10)
            }
            .padding(.vertical, 40)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    AuthView()
} 