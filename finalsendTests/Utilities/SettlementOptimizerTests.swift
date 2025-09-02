import XCTest
@testable import finalsend

final class SettlementOptimizerTests: XCTestCase {
    
    func testSimpleSettlement() {
        let balances = [
            UserExpenseBalance(
                partyId: UUID(),
                userId: UUID(),
                totalPaid: 100.00,
                totalOwed: 50.00,
                netBalance: 50.00
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: UUID(),
                totalPaid: 0.00,
                totalOwed: 50.00,
                netBalance: -50.00
            )
        ]
        
        let suggestions = SettlementOptimizer.optimizeSettlements(balances: balances)
        
        XCTAssertEqual(suggestions.count, 1)
        XCTAssertEqual(suggestions[0].amount, 50.00)
        XCTAssertEqual(suggestions[0].from, balances[1].userId)
        XCTAssertEqual(suggestions[0].to, balances[0].userId)
    }
    
    func testMultipleSettlements() {
        let user1 = UUID()
        let user2 = UUID()
        let user3 = UUID()
        
        let balances = [
            UserExpenseBalance(
                partyId: UUID(),
                userId: user1,
                totalPaid: 100.00,
                totalOwed: 50.00,
                netBalance: 50.00
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: user2,
                totalPaid: 0.00,
                totalOwed: 30.00,
                netBalance: -30.00
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: user3,
                totalPaid: 0.00,
                totalOwed: 20.00,
                netBalance: -20.00
            )
        ]
        
        let suggestions = SettlementOptimizer.optimizeSettlements(balances: balances)
        
        XCTAssertEqual(suggestions.count, 2)
        
        // Should have one 30.00 payment and one 20.00 payment
        let amounts = suggestions.map { $0.amount }.sorted()
        XCTAssertEqual(amounts, [20.00, 30.00])
        
        // All payments should be to user1
        for suggestion in suggestions {
            XCTAssertEqual(suggestion.to, user1)
        }
    }
    
    func testComplexSettlement() {
        let user1 = UUID()
        let user2 = UUID()
        let user3 = UUID()
        let user4 = UUID()
        
        let balances = [
            UserExpenseBalance(
                partyId: UUID(),
                userId: user1,
                totalPaid: 200.00,
                totalOwed: 50.00,
                netBalance: 150.00
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: user2,
                totalPaid: 100.00,
                totalOwed: 100.00,
                netBalance: 0.00
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: user3,
                totalPaid: 0.00,
                totalOwed: 100.00,
                netBalance: -100.00
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: user4,
                totalPaid: 0.00,
                totalOwed: 50.00,
                netBalance: -50.00
            )
        ]
        
        let suggestions = SettlementOptimizer.optimizeSettlements(balances: balances)
        
        XCTAssertEqual(suggestions.count, 2)
        
        // Should have one 100.00 payment and one 50.00 payment
        let amounts = suggestions.map { $0.amount }.sorted()
        XCTAssertEqual(amounts, [50.00, 100.00])
        
        // All payments should be to user1
        for suggestion in suggestions {
            XCTAssertEqual(suggestion.to, user1)
        }
    }
    
    func testNoSettlementsNeeded() {
        let balances = [
            UserExpenseBalance(
                partyId: UUID(),
                userId: UUID(),
                totalPaid: 100.00,
                totalOwed: 100.00,
                netBalance: 0.00
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: UUID(),
                totalPaid: 50.00,
                totalOwed: 50.00,
                netBalance: 0.00
            )
        ]
        
        let suggestions = SettlementOptimizer.optimizeSettlements(balances: balances)
        
        XCTAssertEqual(suggestions.count, 0)
    }
    
    func testOnlyCreditors() {
        let balances = [
            UserExpenseBalance(
                partyId: UUID(),
                userId: UUID(),
                totalPaid: 100.00,
                totalOwed: 50.00,
                netBalance: 50.00
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: UUID(),
                totalPaid: 50.00,
                totalOwed: 25.00,
                netBalance: 25.00
            )
        ]
        
        let suggestions = SettlementOptimizer.optimizeSettlements(balances: balances)
        
        XCTAssertEqual(suggestions.count, 0)
    }
    
    func testOnlyDebtors() {
        let balances = [
            UserExpenseBalance(
                partyId: UUID(),
                userId: UUID(),
                totalPaid: 0.00,
                totalOwed: 100.00,
                netBalance: -100.00
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: UUID(),
                totalPaid: 0.00,
                totalOwed: 50.00,
                netBalance: -50.00
            )
        ]
        
        let suggestions = SettlementOptimizer.optimizeSettlements(balances: balances)
        
        XCTAssertEqual(suggestions.count, 0)
    }
    
    func testEmptyBalances() {
        let balances: [UserExpenseBalance] = []
        
        let suggestions = SettlementOptimizer.optimizeSettlements(balances: balances)
        
        XCTAssertEqual(suggestions.count, 0)
    }
    
    func testPrecisionTolerance() {
        let balances = [
            UserExpenseBalance(
                partyId: UUID(),
                userId: UUID(),
                totalPaid: 100.01,
                totalOwed: 50.00,
                netBalance: 50.01
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: UUID(),
                totalPaid: 0.00,
                totalOwed: 50.00,
                netBalance: -50.00
            )
        ]
        
        let suggestions = SettlementOptimizer.optimizeSettlements(balances: balances)
        
        XCTAssertEqual(suggestions.count, 1)
        XCTAssertEqual(suggestions[0].amount, 50.00)
    }
    
    func testValidateSettlementPlan() {
        let user1 = UUID()
        let user2 = UUID()
        let user3 = UUID()
        
        let balances = [
            UserExpenseBalance(
                partyId: UUID(),
                userId: user1,
                totalPaid: 100.00,
                totalOwed: 50.00,
                netBalance: 50.00
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: user2,
                totalPaid: 0.00,
                totalOwed: 30.00,
                netBalance: -30.00
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: user3,
                totalPaid: 0.00,
                totalOwed: 20.00,
                netBalance: -20.00
            )
        ]
        
        let suggestions = [
            DebtSuggestion(from: user2, to: user1, amount: 30.00),
            DebtSuggestion(from: user3, to: user1, amount: 20.00)
        ]
        
        let isValid = SettlementOptimizer.validateSettlementPlan(
            suggestions: suggestions,
            balances: balances
        )
        
        XCTAssertTrue(isValid)
    }
    
    func testInvalidSettlementPlan() {
        let user1 = UUID()
        let user2 = UUID()
        
        let balances = [
            UserExpenseBalance(
                partyId: UUID(),
                userId: user1,
                totalPaid: 100.00,
                totalOwed: 50.00,
                netBalance: 50.00
            ),
            UserExpenseBalance(
                partyId: UUID(),
                userId: user2,
                totalPaid: 0.00,
                totalOwed: 30.00,
                netBalance: -30.00
            )
        ]
        
        let suggestions = [
            DebtSuggestion(from: user2, to: user1, amount: 40.00) // Wrong amount
        ]
        
        let isValid = SettlementOptimizer.validateSettlementPlan(
            suggestions: suggestions,
            balances: balances
        )
        
        XCTAssertFalse(isValid)
    }
}
