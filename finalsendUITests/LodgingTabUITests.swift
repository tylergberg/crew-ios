//
//  LodgingTabUITests.swift
//  finalsendUITests
//
//  Created by Tyler Greenberg on 2025-01-27.
//

import XCTest

final class LodgingTabUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        
        // Navigate to a party with lodging tab
        // This assumes there's a way to navigate to a party detail view
        // You may need to adjust this based on your app's navigation structure
    }
    
    override func tearDownWithError() throws {
        // Clean up after each test
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyStateDisplay() throws {
        // Navigate to lodging tab
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Verify empty state elements
        let emptyStateImage = app.images["house.fill"]
        XCTAssertTrue(emptyStateImage.exists, "Empty state house icon should be visible")
        
        let emptyStateTitle = app.staticTexts["No lodging yet"]
        XCTAssertTrue(emptyStateTitle.exists, "Empty state title should be visible")
        
        let emptyStateSubtext = app.staticTexts["Add where everyone's staying"]
        XCTAssertTrue(emptyStateSubtext.exists, "Empty state subtext should be visible")
        
        // Verify FAB is visible for organizers/admins
        let fabButton = app.buttons["Add lodging"]
        XCTAssertTrue(fabButton.exists, "FAB should be visible for users with manage permissions")
    }
    
    func testEmptyStateAddButtonAction() throws {
        // Navigate to lodging tab
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Tap the add button in empty state
        let addButton = app.buttons["Add lodging"]
        addButton.tap()
        
        // Verify add lodging sheet appears
        let addLodgingSheet = app.sheets.firstMatch
        XCTAssertTrue(addLodgingSheet.exists, "Add lodging sheet should appear when tapping add button")
    }
    
    // MARK: - Single Lodging Tests
    
    func testSingleLodgingCardDisplay() throws {
        // Navigate to lodging tab with existing lodging
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Verify lodging card exists
        let lodgingCard = app.otherElements.containing(.staticText, identifier: "Dream House | Pool | Austin!").firstMatch
        XCTAssertTrue(lodgingCard.exists, "Lodging card should be visible")
        
        // Verify card content
        let lodgingTitle = app.staticTexts["Dream House | Pool | Austin!"]
        XCTAssertTrue(lodgingTitle.exists, "Lodging title should be visible")
        
        let lodgingLocation = app.staticTexts["Austin, TX"]
        XCTAssertTrue(lodgingLocation.exists, "Lodging location should be visible")
        
        let sleepingArrangements = app.staticTexts["Sleeping Arrangements"]
        XCTAssertTrue(sleepingArrangements.exists, "Sleeping arrangements label should be visible")
    }
    
    func testSingleLodgingCardMetrics() throws {
        // Navigate to lodging tab with existing lodging
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Verify metrics are displayed
        let roomsMetric = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '5'")).firstMatch
        XCTAssertTrue(roomsMetric.exists, "Rooms count should be visible")
        
        let bedsMetric = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '12'")).firstMatch
        XCTAssertTrue(bedsMetric.exists, "Beds count should be visible")
        
        let assignedMetric = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '14'")).firstMatch
        XCTAssertTrue(assignedMetric.exists, "Assigned count should be visible")
    }
    
    // MARK: - Multiple Lodgings Tests
    
    func testMultipleLodgingsDisplay() throws {
        // Navigate to lodging tab with multiple lodgings
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Verify multiple cards exist
        let lodgingCards = app.otherElements.containing(.staticText, identifier: "Dream House | Pool | Austin!").allElementsBoundByIndex
        XCTAssertGreaterThan(lodgingCards.count, 1, "Multiple lodging cards should be visible")
        
        // Verify scrolling works
        let firstCard = lodgingCards[0]
        let lastCard = lodgingCards[lodgingCards.count - 1]
        
        firstCard.swipeUp()
        XCTAssertTrue(lastCard.isHittable, "Should be able to scroll to last card")
    }
    
    // MARK: - Role-Gated Overflow Tests
    
    func testOrganizerOverflowMenuVisibility() throws {
        // Navigate to lodging tab as organizer
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Verify overflow menu is visible for organizers
        let overflowButton = app.buttons["More options"]
        XCTAssertTrue(overflowButton.exists, "Overflow menu should be visible for organizers")
        
        // Tap overflow menu
        overflowButton.tap()
        
        // Verify menu options
        let editOption = app.buttons["Edit"]
        XCTAssertTrue(editOption.exists, "Edit option should be available for organizers")
        
        let manageRoomsOption = app.buttons["Manage Rooms & Beds"]
        XCTAssertTrue(manageRoomsOption.exists, "Manage Rooms & Beds option should be available for organizers")
        
        let assignGuestsOption = app.buttons["Assign Guests"]
        XCTAssertTrue(assignGuestsOption.exists, "Assign Guests option should be available for organizers")
        
        let deleteOption = app.buttons["Delete"]
        XCTAssertTrue(deleteOption.exists, "Delete option should be available for organizers")
    }
    
    func testAttendeeOverflowMenuVisibility() throws {
        // Navigate to lodging tab as attendee
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Verify overflow menu is NOT visible for attendees
        let overflowButton = app.buttons["More options"]
        XCTAssertFalse(overflowButton.exists, "Overflow menu should NOT be visible for attendees")
    }
    
    // MARK: - FAB Tests
    
    func testFABVisibilityForOrganizers() throws {
        // Navigate to lodging tab as organizer
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Verify FAB is visible
        let fabButton = app.buttons.containing(.image, identifier: "plus").firstMatch
        XCTAssertTrue(fabButton.exists, "FAB should be visible for organizers")
        
        // Verify FAB position (bottom-right)
        let screenBounds = app.windows.firstMatch.frame
        let fabFrame = fabButton.frame
        
        XCTAssertGreaterThan(fabFrame.midX, screenBounds.midX, "FAB should be on the right side")
        XCTAssertGreaterThan(fabFrame.midY, screenBounds.midY, "FAB should be on the bottom half")
    }
    
    func testFABVisibilityForAttendees() throws {
        // Navigate to lodging tab as attendee
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Verify FAB is NOT visible for attendees
        let fabButton = app.buttons.containing(.image, identifier: "plus").firstMatch
        XCTAssertFalse(fabButton.exists, "FAB should NOT be visible for attendees")
    }
    
    func testFABAction() throws {
        // Navigate to lodging tab as organizer
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Tap FAB
        let fabButton = app.buttons.containing(.image, identifier: "plus").firstMatch
        fabButton.tap()
        
        // Verify add lodging sheet appears
        let addLodgingSheet = app.sheets.firstMatch
        XCTAssertTrue(addLodgingSheet.exists, "Add lodging sheet should appear when tapping FAB")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        // Navigate to lodging tab
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Verify accessibility labels are set
        let overflowButton = app.buttons["More options"]
        XCTAssertTrue(overflowButton.exists, "Overflow button should have accessibility label")
        
        let fabButton = app.buttons.containing(.image, identifier: "plus").firstMatch
        XCTAssertTrue(fabButton.exists, "FAB should be accessible")
    }
    
    // MARK: - Scrolling Tests
    
    func testFullHeightScrolling() throws {
        // Navigate to lodging tab
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Verify the entire tab scrolls (no nested scroll views)
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Main scroll view should exist")
        
        // Verify no nested scroll views
        let nestedScrollViews = app.scrollViews.allElementsBoundByIndex
        XCTAssertLessThanOrEqual(nestedScrollViews.count, 1, "Should not have nested scroll views")
    }
    
    // MARK: - Card Interaction Tests
    
    func testCardTapNavigation() throws {
        // Navigate to lodging tab
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Tap on a lodging card
        let lodgingCard = app.otherElements.containing(.staticText, identifier: "Dream House | Pool | Austin!").firstMatch
        lodgingCard.tap()
        
        // Verify navigation to details (this would depend on your navigation implementation)
        // For now, we'll just verify the tap doesn't crash
        XCTAssertTrue(lodgingCard.exists, "Card should still exist after tap")
    }
    
    func testSleepingArrangementsTap() throws {
        // Navigate to lodging tab
        let lodgingTab = app.buttons["Lodging"]
        lodgingTab.tap()
        
        // Tap on sleeping arrangements row
        let sleepingArrangements = app.staticTexts["Sleeping Arrangements"]
        sleepingArrangements.tap()
        
        // Verify navigation to details (this would depend on your navigation implementation)
        // For now, we'll just verify the tap doesn't crash
        XCTAssertTrue(sleepingArrangements.exists, "Sleeping arrangements should still exist after tap")
    }
}
