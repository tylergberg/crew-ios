import XCTest
@testable import finalsend

final class PartyChatServiceTests: XCTestCase {
    
    func testChatMessageDecoding() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "party_id": "123e4567-e89b-12d3-a456-426614174001",
            "user_id": "123e4567-e89b-12d3-a456-426614174002",
            "message": "Hello, world!",
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": null
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let chatMessage = try decoder.decode(ChatMessage.self, from: json)
        
        XCTAssertEqual(chatMessage.id.uuidString, "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertEqual(chatMessage.partyId.uuidString, "123e4567-e89b-12d3-a456-426614174001")
        XCTAssertEqual(chatMessage.userId.uuidString, "123e4567-e89b-12d3-a456-426614174002")
        XCTAssertEqual(chatMessage.message, "Hello, world!")
        XCTAssertNil(chatMessage.updatedAt)
    }
    
    func testAIMessageDecoding() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "party_id": "123e4567-e89b-12d3-a456-426614174001",
            "sender_role": "user",
            "content": "What are the best activities?",
            "created_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let aiMessage = try decoder.decode(AIMessage.self, from: json)
        
        XCTAssertEqual(aiMessage.id.uuidString, "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertEqual(aiMessage.partyId.uuidString, "123e4567-e89b-12d3-a456-426614174001")
        XCTAssertEqual(aiMessage.senderRole, .user)
        XCTAssertEqual(aiMessage.content, "What are the best activities?")
    }
}
