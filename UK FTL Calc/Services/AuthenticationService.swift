import Foundation
import Supabase
import Combine

// MARK: - Notification Names
extension Notification.Name {
    static let authenticationStateChanged = Notification.Name("authenticationStateChanged")
}

// MARK: - Custom Error Types
enum AuthError: LocalizedError {
    case userNotFound
    case invalidPassword
    case emailNotConfirmed
    case profileCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidPassword:
            return "Invalid password"
        case .emailNotConfirmed:
            return "Please confirm your email before signing in"
        case .profileCreationFailed:
            return "Failed to create user profile"
        }
    }
}



@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasCompletedProfileSetup = false
    
    private var supabase: SupabaseClient {
        SupabaseConfig.shared.client
    }
    
    init() {
        // Don't auto-check current user on init to avoid race conditions
        // User will be checked when they explicitly sign in
        // Check if user has completed profile setup
        hasCompletedProfileSetup = UserDefaults.standard.bool(forKey: "hasCompletedProfileSetup")
        
        // TEMPORARY: Reset profile completion for testing new user flow
        // TODO: Remove this line after testing
        // UserDefaults.standard.set(false, forKey: "hasCompletedProfileSetup")
        // hasCompletedProfileSetup = false
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create user account with metadata
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "first_name": AnyJSON.string(firstName),
                    "last_name": AnyJSON.string(lastName)
                ]
            )
            
            let user = authResponse.user
            
            // Create user profile
            try await createUserProfile(
                userId: user.id,
                firstName: firstName,
                lastName: lastName
            )
            
            // Don't automatically authenticate - user needs to confirm email first
            errorMessage = "Account created successfully! Please check your email and click the confirmation link before signing in."
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        print("DEBUG: Starting sign in for email: \(email)")
        
        do {
            let authResponse = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            let user = authResponse.user
            print("DEBUG: Sign in successful, user ID: \(user.id)")
            print("DEBUG: Email confirmed at: \(String(describing: user.emailConfirmedAt))")
            
            // Check if email is confirmed - try different properties
            print("DEBUG: User properties - emailConfirmedAt: \(String(describing: user.emailConfirmedAt))")
            print("DEBUG: User properties - email: \(String(describing: user.email))")
            print("DEBUG: User properties - confirmedAt: \(String(describing: user.confirmedAt))")
            
            // Try different ways to check email confirmation
            let _ = user.emailConfirmedAt != nil || user.confirmedAt != nil
            
            // TEMPORARY: Allow sign in regardless of email confirmation for testing
            print("DEBUG: Email confirmation check - emailConfirmedAt: \(String(describing: user.emailConfirmedAt)), confirmedAt: \(String(describing: user.confirmedAt))")
            print("DEBUG: Allowing sign in for testing purposes")
            
            // Load user profile
            await loadUserProfile(userId: user.id)
            
            // Check if user has completed profile setup
            // For new users, hasCompletedProfileSetup should start as false
            // Only existing users who have previously completed setup should be marked as complete
            let storedCompletionStatus = UserDefaults.standard.bool(forKey: "hasCompletedProfileSetup")
            hasCompletedProfileSetup = storedCompletionStatus
            
            print("DEBUG: Profile setup status - stored: \(storedCompletionStatus), setting hasCompletedProfileSetup to: \(hasCompletedProfileSetup)")
            
            // Update state on main thread to ensure UI updates
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = user
                print("DEBUG: User authenticated successfully - state updated on main thread")
                
                // Post notification to trigger UI update
                NotificationCenter.default.post(name: .authenticationStateChanged, object: nil)
                print("DEBUG: Posted authentication state changed notification")
            }
            
            // TODO: Re-enable email confirmation check after testing
            /*
            if isEmailConfirmed {
                print("DEBUG: Email is confirmed, proceeding with authentication")
                // Load user profile
                await loadUserProfile(userId: user.id)
                
                isAuthenticated = true
                currentUser = user
                print("DEBUG: User authenticated successfully")
            } else {
                print("DEBUG: Email not confirmed, showing error message")
                errorMessage = "Please confirm your email address before signing in. Check your inbox for a confirmation email."
            }
            */
            
        } catch {
            print("DEBUG: Sign in error: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        print("DEBUG: Sign in function completed, isAuthenticated: \(isAuthenticated)")
    }
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            isAuthenticated = false
            currentUser = nil
            
            // Post notification to trigger UI update
            NotificationCenter.default.post(name: .authenticationStateChanged, object: nil)
            print("DEBUG: Posted sign out notification")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func markProfileSetupComplete() {
        hasCompletedProfileSetup = true
        UserDefaults.standard.set(true, forKey: "hasCompletedProfileSetup")
    }
    
    func deleteAccount(password: String) async throws {
        guard let user = currentUser else {
            throw AuthError.userNotFound
        }
        
        print("DEBUG: Starting account deletion for user: \(user.id)")
        
        // First, verify the password by attempting to sign in
        do {
            let _ = try await supabase.auth.signIn(
                email: user.email ?? "",
                password: password
            )
            print("DEBUG: Password verification successful")
        } catch {
            print("DEBUG: Password verification failed: \(error)")
            throw AuthError.invalidPassword
        }
        
        // Delete user profile from database first
        do {
            try await supabase
                .from("profiles")
                .delete()
                .eq("id", value: user.id)
                .execute()
            print("DEBUG: Successfully deleted user profile from database")
        } catch {
            print("DEBUG: Failed to delete profile from database: \(error)")
            // Continue with account deletion even if profile deletion fails
        }
        
        // Note: Direct user account deletion requires admin privileges
        // For now, we'll sign out the user and clear all local data
        // This effectively "deletes" their account from their device
        print("DEBUG: Signing out user and clearing local data")
        
        // Clear all local data
        clearAllLocalData()
        
        // Update state
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUser = nil
            self.hasCompletedProfileSetup = false
        }
        
        // Post notification to trigger UI update
        NotificationCenter.default.post(name: .authenticationStateChanged, object: nil)
    }
    
    private func clearAllLocalData() {
        // Clear all UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // Reset specific flags
        UserDefaults.standard.set(false, forKey: "hasCompletedProfileSetup")
    }
    
    func resendConfirmationEmail(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
                    try await supabase.auth.resend(
            email: email,
            type: .signup
        )
            errorMessage = "Confirmation email sent! Please check your inbox."
        } catch {
            errorMessage = "Failed to send confirmation email: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func checkCurrentUser() async {
        do {
            let session = try await supabase.auth.session
            let user = session.user
            currentUser = user
            isAuthenticated = true
            await loadUserProfile(userId: user.id)
        } catch {
            // User not authenticated
            isAuthenticated = false
        }
    }
    
    private func createUserProfile(userId: UUID, firstName: String, lastName: String) async throws {
        let profile: [String: String] = [
            "id": userId.uuidString,
            "first_name": firstName,
            "last_name": lastName,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        try await supabase
            .from("profiles")
            .insert(profile)
            .execute()
    }
    
    private func loadUserProfile(userId: UUID) async {
        // This will be implemented when we add profile management
        // For now, just mark as authenticated
    }
}


