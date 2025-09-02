import XCTest
@testable import finalsend

final class ExpenseSplitBuilderTests: XCTestCase {
    
    func testEvenSplitWithNoRemainder() {
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let participants = [UUID(), UUID(), UUID(), UUID()]
        let splitType = SplitType.even
        
        let splits = ExpenseSplitBuilder.buildSplits(
            amount: amount,
            paidBy: paidBy,
            selectedUserIds: participants,
            splitType: splitType
        )
        
        XCTAssertEqual(splits.count, 4)
        
        let totalOwed = splits.reduce(0) { $0 + $1.owedShare }
        let totalPaid = splits.reduce(0) { $0 + $1.paidShare }
        
        XCTAssertEqual(totalOwed, amount)
        XCTAssertEqual(totalPaid, amount)
        
        // Each person should owe 25.00
        for split in splits {
            if split.userId == paidBy {
                XCTAssertEqual(split.paidShare, amount)
                XCTAssertEqual(split.owedShare, 25.00)
            } else {
                XCTAssertEqual(split.paidShare, 0)
                XCTAssertEqual(split.owedShare, 25.00)
            }
        }
    }
    
    func testEvenSplitWithRemainder() {
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let participants = [UUID(), UUID(), UUID()] // 3 people
        let splitType = SplitType.even
        
        let splits = ExpenseSplitBuilder.buildSplits(
            amount: amount,
            paidBy: paidBy,
            selectedUserIds: participants,
            splitType: splitType
        )
        
        XCTAssertEqual(splits.count, 3)
        
        let totalOwed = splits.reduce(0) { $0 + $1.owedShare }
        let totalPaid = splits.reduce(0) { $0 + $1.paidShare }
        
        XCTAssertEqual(totalOwed, amount)
        XCTAssertEqual(totalPaid, amount)
        
        // Last participant should absorb the remainder
        let expectedBaseShare: Decimal = 33.33
        let remainder: Decimal = 0.01
        
        for (index, split) in splits.enumerated() {
            if split.userId == paidBy {
                XCTAssertEqual(split.paidShare, amount)
                if index == participants.count - 1 {
                    XCTAssertEqual(split.owedShare, expectedBaseShare + remainder)
                } else {
                    XCTAssertEqual(split.owedShare, expectedBaseShare)
                }
            } else {
                XCTAssertEqual(split.paidShare, 0)
                if index == participants.count - 1 {
                    XCTAssertEqual(split.owedShare, expectedBaseShare + remainder)
                } else {
                    XCTAssertEqual(split.owedShare, expectedBaseShare)
                }
            }
        }
    }
    
    func testCustomSplit() {
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let participant1 = UUID()
        let participant2 = UUID()
        let participants = [participant1, participant2]
        let splitType = SplitType.custom
        let customShares: [UUID: Decimal] = [
            participant1: 60.00,
            participant2: 40.00
        ]
        
        let splits = ExpenseSplitBuilder.buildSplits(
            amount: amount,
            paidBy: paidBy,
            selectedUserIds: participants,
            splitType: splitType,
            customShares: customShares
        )
        
        XCTAssertEqual(splits.count, 2)
        
        let totalOwed = splits.reduce(0) { $0 + $1.owedShare }
        let totalPaid = splits.reduce(0) { $0 + $1.paidShare }
        
        XCTAssertEqual(totalOwed, amount)
        XCTAssertEqual(totalPaid, amount)
        
        for split in splits {
            if split.userId == paidBy {
                XCTAssertEqual(split.paidShare, amount)
                XCTAssertEqual(split.owedShare, customShares[split.userId] ?? 0)
            } else {
                XCTAssertEqual(split.paidShare, 0)
                XCTAssertEqual(split.owedShare, customShares[split.userId] ?? 0)
            }
        }
    }
    
    func testDedupeSplits() {
        let userId = UUID()
        let splits = [
            ExpenseSplitInput(userId: userId, owedShare: 50.00, paidShare: 100.00),
            ExpenseSplitInput(userId: userId, owedShare: 30.00, paidShare: 0),
            ExpenseSplitInput(userId: UUID(), owedShare: 20.00, paidShare: 0)
        ]
        
        let deduped = ExpenseSplitBuilder.dedupeSplits(splits)
        
        XCTAssertEqual(deduped.count, 2) // Should only have 2 unique users
        XCTAssertTrue(deduped.contains { $0.userId == userId })
        XCTAssertTrue(deduped.contains { $0.userId != userId })
    }
    
    func testEmptyParticipants() {
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let participants: [UUID] = []
        let splitType = SplitType.even
        
        let splits = ExpenseSplitBuilder.buildSplits(
            amount: amount,
            paidBy: paidBy,
            selectedUserIds: participants,
            splitType: splitType
        )
        
        XCTAssertEqual(splits.count, 0)
    }
}
