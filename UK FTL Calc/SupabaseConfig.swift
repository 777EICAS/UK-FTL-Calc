import Foundation
import Supabase

// MARK: - Supabase Configuration
struct SupabaseConfig {
    static var shared = SupabaseConfig()
    
    // Your Supabase project details
    let supabaseURL = "https://qdrymjtimxrqilrrjxnh.supabase.co"
    let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkcnltanRpbXhycWlscnJqeG5oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2MzQ5NDUsImV4cCI6MjA3MTIxMDk0NX0.Gw3yg2ulnDQpjbxyWEyX8maMmtjUUfMK_oKoeflyF9g"
    
    // Service role key for admin operations
    // WARNING: This should only be used server-side in production
    let supabaseServiceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkcnltanRpbXhycWlscnJqeG5oIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTYzNDk0NSwiZXhwIjoyMDcxMjEwOTQ1fQ.gTQadZHvruuEk9kqFskpj42beVRKWIVz-HArjETzHm0"
    
    lazy var client: SupabaseClient = {
        SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseAnonKey
        )
    }()
    
    // Admin client for user deletion operations
    lazy var adminClient: SupabaseClient = {
        SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseServiceRoleKey
        )
    }()
    
    private init() {}
}
