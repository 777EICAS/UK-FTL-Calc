import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Set up your pilot profile")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Sign Up Form
                    VStack(spacing: 20) {
                        // Name Fields
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("First Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("First name", text: $firstName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.givenName)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Last Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("Last name", text: $lastName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.familyName)
                            }
                        }
                        
                        // Email Field
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
                        
                        // Password Fields
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            SecureField("Create a password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.newPassword)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.newPassword)
                        }
                        
                        // Sign Up Button
                        Button(action: {
                            Task {
                                await authService.signUp(
                                    email: email,
                                    password: password,
                                    firstName: firstName,
                                    lastName: lastName
                                )
                                
                                if authService.isAuthenticated {
                                    dismiss()
                                }
                            }
                        }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || authService.isLoading)
                        
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        !confirmPassword.isEmpty && 
        !firstName.isEmpty && 
        !lastName.isEmpty && 
        password == confirmPassword &&
        password.count >= 8
    }
}
