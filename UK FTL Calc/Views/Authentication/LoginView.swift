import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("UK FTL Calculator")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to access your profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Login Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                    }
                    
                    Button(action: {
                        Task {
                            await authService.signIn(email: email, password: password)
                        }
                    }) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                    
                    if let errorMessage = authService.errorMessage {
                        VStack(spacing: 8) {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                            
                            // Show resend confirmation button if email not confirmed
                            if errorMessage.contains("confirm your email") {
                                Button("Resend Confirmation Email") {
                                    Task {
                                        await authService.resendConfirmationEmail(email: email)
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Debug button to check authentication state
                    Button("Debug: Check Auth State") {
                        print("DEBUG: Manual check - isAuthenticated: \(authService.isAuthenticated)")
                        print("DEBUG: Manual check - currentUser: \(String(describing: authService.currentUser))")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                // Sign Up Link
                VStack(spacing: 16) {
                    Divider()
                    
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        
                        Button("Sign Up") {
                            showingSignUp = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }
}
