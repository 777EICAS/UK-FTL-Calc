import Foundation
import Supabase
import Combine

// MARK: - Notification Names
extension Notification.Name {
    static let authenticationStateChanged = Notification.Name("authenticationStateChanged")
}

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var supabase: SupabaseClient {
        SupabaseConfig.shared.client
    }
    
    init() {
        // Don't auto-check current user on init to avoid race conditions
        // User will be checked when they explicitly sign in
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create user account
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
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
            print("DEBUG: User properties - email: \(user.email)")
            print("DEBUG: User properties - confirmedAt: \(String(describing: user.confirmedAt))")
            
            // Try different ways to check email confirmation
            let isEmailConfirmed = user.emailConfirmedAt != nil || user.confirmedAt != nil
            
            // TEMPORARY: Allow sign in regardless of email confirmation for testing
            print("DEBUG: Email confirmation check - emailConfirmedAt: \(String(describing: user.emailConfirmedAt)), confirmedAt: \(String(describing: user.confirmedAt))")
            print("DEBUG: Allowing sign in for testing purposes")
            
            // Load user profile
            await loadUserProfile(userId: user.id)
            
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

// MARK: - Custom Errors
enum AuthError: LocalizedError {
    case userNotFound
    case profileCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User account not found"
        case .profileCreationFailed:
            return "Failed to create user profile"
        }
    }
}
