import Foundation
import Supabase

class PackingService {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // Basic service methods - can be implemented later
}

class PackingRealtime {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    // Basic realtime methods - can be implemented later
}

