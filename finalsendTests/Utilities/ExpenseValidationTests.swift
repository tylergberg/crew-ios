import XCTest
@testable import finalsend

final class ExpenseValidationTests: XCTestCase {
    
    func testValidExpense() {
        let title = "Dinner"
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let splits = [
            ExpenseSplitInput(userId: paidBy, owedShare: 50.00, paidShare: 100.00),
            ExpenseSplitInput(userId: UUID(), owedShare: 50.00, paidShare: 0)
        ]
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.message)
    }
    
    func testEmptyTitle() {
        let title = ""
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let splits = [
            ExpenseSplitInput(userId: paidBy, owedShare: 50.00, paidShare: 100.00),
            ExpenseSplitInput(userId: UUID(), owedShare: 50.00, paidShare: 0)
        ]
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Title is required")
    }
    
    func testWhitespaceTitle() {
        let title = "   "
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let splits = [
            ExpenseSplitInput(userId: paidBy, owedShare: 50.00, paidShare: 100.00),
            ExpenseSplitInput(userId: UUID(), owedShare: 50.00, paidShare: 0)
        ]
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Title is required")
    }
    
    func testZeroAmount() {
        let title = "Dinner"
        let amount: Decimal = 0
        let paidBy = UUID()
        let splits = [
            ExpenseSplitInput(userId: paidBy, owedShare: 0, paidShare: 0),
            ExpenseSplitInput(userId: UUID(), owedShare: 0, paidShare: 0)
        ]
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Amount must be greater than 0")
    }
    
    func testNegativeAmount() {
        let title = "Dinner"
        let amount: Decimal = -50.00
        let paidBy = UUID()
        let splits = [
            ExpenseSplitInput(userId: paidBy, owedShare: -25.00, paidShare: -50.00),
            ExpenseSplitInput(userId: UUID(), owedShare: -25.00, paidShare: 0)
        ]
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Amount must be greater than 0")
    }
    
    func testEmptySplits() {
        let title = "Dinner"
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let splits: [ExpenseSplitInput] = []
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "At least one person must be selected")
    }
    
    func testDuplicateUserIds() {
        let title = "Dinner"
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let userId = UUID()
        let splits = [
            ExpenseSplitInput(userId: userId, owedShare: 50.00, paidShare: 100.00),
            ExpenseSplitInput(userId: userId, owedShare: 50.00, paidShare: 0)
        ]
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Duplicate participants found")
    }
    
    func testOwedShareNotEqualToAmount() {
        let title = "Dinner"
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let splits = [
            ExpenseSplitInput(userId: paidBy, owedShare: 50.00, paidShare: 100.00),
            ExpenseSplitInput(userId: UUID(), owedShare: 40.00, paidShare: 0)
        ]
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Total owed amount must equal expense amount")
    }
    
    func testPaidShareNotEqualToAmount() {
        let title = "Dinner"
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let splits = [
            ExpenseSplitInput(userId: paidBy, owedShare: 50.00, paidShare: 80.00),
            ExpenseSplitInput(userId: UUID(), owedShare: 50.00, paidShare: 20.00)
        ]
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Total paid amount must equal expense amount")
    }
    
    func testPayerNotInSplits() {
        let title = "Dinner"
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let splits = [
            ExpenseSplitInput(userId: UUID(), owedShare: 50.00, paidShare: 100.00),
            ExpenseSplitInput(userId: UUID(), owedShare: 50.00, paidShare: 0)
        ]
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Payer must have paid the full amount")
    }
    
    func testPayerNotPaidFullAmount() {
        let title = "Dinner"
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let splits = [
            ExpenseSplitInput(userId: paidBy, owedShare: 50.00, paidShare: 80.00),
            ExpenseSplitInput(userId: UUID(), owedShare: 50.00, paidShare: 20.00)
        ]
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Payer must have paid the full amount")
    }
    
    func testNegativeShares() {
        let title = "Dinner"
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let splits = [
            ExpenseSplitInput(userId: paidBy, owedShare: -50.00, paidShare: 100.00),
            ExpenseSplitInput(userId: UUID(), owedShare: 150.00, paidShare: 0)
        ]
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Amounts cannot be negative")
    }
    
    func testNoOwedShares() {
        let title = "Dinner"
        let amount: Decimal = 100.00
        let paidBy = UUID()
        let splits = [
            ExpenseSplitInput(userId: paidBy, owedShare: 0, paidShare: 100.00),
            ExpenseSplitInput(userId: UUID(), owedShare: 0, paidShare: 0)
        ]
        
        let result = ExpenseValidation.validateExpense(
            title: title,
            amount: amount,
            paidBy: paidBy,
            splits: splits
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "At least one person must owe something")
    }
    
    func testValidSettlement() {
        let payerId = UUID()
        let receiverId = UUID()
        let amount: Decimal = 50.00
        let existingSettlements: [Expense] = []
        
        let result = ExpenseValidation.validateSettlement(
            payerId: payerId,
            receiverId: receiverId,
            amount: amount,
            existingSettlements: existingSettlements
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.message)
    }
    
    func testSettlementSamePayerReceiver() {
        let payerId = UUID()
        let amount: Decimal = 50.00
        let existingSettlements: [Expense] = []
        
        let result = ExpenseValidation.validateSettlement(
            payerId: payerId,
            receiverId: payerId,
            amount: amount,
            existingSettlements: existingSettlements
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Payer and receiver cannot be the same person")
    }
    
    func testSettlementZeroAmount() {
        let payerId = UUID()
        let receiverId = UUID()
        let amount: Decimal = 0
        let existingSettlements: [Expense] = []
        
        let result = ExpenseValidation.validateSettlement(
            payerId: payerId,
            receiverId: receiverId,
            amount: amount,
            existingSettlements: existingSettlements
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Settlement amount must be greater than 0")
    }
    
    func testSettlementNegativeAmount() {
        let payerId = UUID()
        let receiverId = UUID()
        let amount: Decimal = -50.00
        let existingSettlements: [Expense] = []
        
        let result = ExpenseValidation.validateSettlement(
            payerId: payerId,
            receiverId: receiverId,
            amount: amount,
            existingSettlements: existingSettlements
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Settlement amount must be greater than 0")
    }
}
