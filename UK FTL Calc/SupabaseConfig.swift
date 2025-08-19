import Foundation
import Supabase

// MARK: - Supabase Configuration
struct SupabaseConfig {
    static var shared = SupabaseConfig()
    
    // Your Supabase project details
    let supabaseURL = "https://qdrymjtimxrqilrrjxnh.supabase.co"
    let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkcnltanRpbXhycWlscnJqeG5oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2MzQ5NDUsImV4cCI6MjA3MTIxMDk0NX0.Gw3yg2ulnDQpjbxyWEyX8maMmtjUUfMK_oKoeflyF9g"
    
    lazy var client: SupabaseClient = {
        SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseAnonKey
        )
    }()
    
    private init() {}
}
