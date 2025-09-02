import Foundation

// MARK: - Realtime Change Handler
struct RealtimeChange {
    let event: RealtimeEvent
    let table: String
    let schema: String
    let record: [String: Any]?
    let oldRecord: [String: Any]?
    
    enum RealtimeEvent: String {
        case insert = "INSERT"
        case update = "UPDATE"
        case delete = "DELETE"
        case all = "*"
    }
    
    init(event: RealtimeEvent, table: String, schema: String, record: [String: Any]?, oldRecord: [String: Any]?) {
        self.event = event
        self.table = table
        self.schema = schema
        self.record = record
        self.oldRecord = oldRecord
    }
}

