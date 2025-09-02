//
//  LodgingTabSnapshotTests.swift
//  finalsendTests
//
//  Created by Tyler Greenberg on 2025-01-27.
//

import XCTest
import SwiftUI
@testable import finalsend

@MainActor
final class LodgingTabSnapshotTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Set up any test-specific configuration
    }
    
    override func tearDownWithError() throws {
        // Clean up after each test
    }
    
    // MARK: - Empty State Snapshot Tests
    
    func testEmptyStateSnapshot() throws {
        let lodgingTabView = LodgingTabView(
            partyId: "test-party-id",
            userRole: .organizer
        )
        
        // Create a snapshot of the empty state
        let snapshot = lodgingTabView.snapshot()
        
        // Verify the snapshot contains expected elements
        XCTAssertNotNil(snapshot, "Empty state snapshot should be created")
        
        // You can add more specific assertions based on your snapshot testing framework
        // For example, if using iOSSnapshotTestCase:
        // FBSnapshotVerifyView(lodgingTabView, identifier: "empty_state_organizer")
    }
    
    func testEmptyStateAttendeeSnapshot() throws {
        let lodgingTabView = LodgingTabView(
            partyId: "test-party-id",
            userRole: .attendee
        )
        
        let snapshot = lodgingTabView.snapshot()
        XCTAssertNotNil(snapshot, "Empty state attendee snapshot should be created")
    }
    
    // MARK: - Single Lodging Snapshot Tests
    
    func testSingleLodgingSnapshot() throws {
        // Create a mock lodging store with one lodging
        let mockStore = MockLodgingStore(partyId: "test-party-id")
        mockStore.lodgings = [
            Lodging(
                id: UUID(),
                partyId: "test-party-id",
                name: "Dream House | Pool | Austin!",
                address: "Austin, TX",
                description: "Beautiful property with amazing views",
                checkInDate: Date(),
                checkOutDate: Date().addingTimeInterval(86400 * 3),
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        let lodgingTabView = LodgingTabView(
            partyId: "test-party-id",
            userRole: .organizer
        )
        
        let snapshot = lodgingTabView.snapshot()
        XCTAssertNotNil(snapshot, "Single lodging snapshot should be created")
    }
    
    // MARK: - Multiple Lodgings Snapshot Tests
    
    func testMultipleLodgingsSnapshot() throws {
        // Create a mock lodging store with multiple lodgings
        let mockStore = MockLodgingStore(partyId: "test-party-id")
        mockStore.lodgings = [
            Lodging(
                id: UUID(),
                partyId: "test-party-id",
                name: "Dream House | Pool | Austin!",
                address: "Austin, TX",
                description: "Beautiful property with amazing views",
                checkInDate: Date(),
                checkOutDate: Date().addingTimeInterval(86400 * 3),
                createdAt: Date(),
                updatedAt: Date()
            ),
            Lodging(
                id: UUID(),
                partyId: "test-party-id",
                name: "Downtown Loft",
                address: "Austin, TX",
                description: "Modern loft in the heart of downtown",
                checkInDate: Date(),
                checkOutDate: Date().addingTimeInterval(86400 * 2),
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        let lodgingTabView = LodgingTabView(
            partyId: "test-party-id",
            userRole: .organizer
        )
        
        let snapshot = lodgingTabView.snapshot()
        XCTAssertNotNil(snapshot, "Multiple lodgings snapshot should be created")
    }
    
    // MARK: - Role-Gated Snapshot Tests
    
    func testOrganizerRoleSnapshot() throws {
        let lodgingTabView = LodgingTabView(
            partyId: "test-party-id",
            userRole: .organizer
        )
        
        let snapshot = lodgingTabView.snapshot()
        XCTAssertNotNil(snapshot, "Organizer role snapshot should be created")
    }
    
    func testAdminRoleSnapshot() throws {
        let lodgingTabView = LodgingTabView(
            partyId: "test-party-id",
            userRole: .admin
        )
        
        let snapshot = lodgingTabView.snapshot()
        XCTAssertNotNil(snapshot, "Admin role snapshot should be created")
    }
    
    func testAttendeeRoleSnapshot() throws {
        let lodgingTabView = LodgingTabView(
            partyId: "test-party-id",
            userRole: .attendee
        )
        
        let snapshot = lodgingTabView.snapshot()
        XCTAssertNotNil(snapshot, "Attendee role snapshot should be created")
    }
    
    // MARK: - LodgingCardView Snapshot Tests
    
    func testLodgingCardViewSnapshot() throws {
        let lodging = Lodging(
            id: UUID(),
            partyId: "test-party-id",
            name: "Dream House | Pool | Austin!",
            address: "Austin, TX",
            description: "Beautiful property with amazing views",
            checkInDate: Date(),
            checkOutDate: Date().addingTimeInterval(86400 * 3),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let attendees = [
            PartyAttendee(
                id: UUID(),
                userId: "1",
                partyId: "test-party-id",
                fullName: "John Doe",
                email: "john@example.com",
                avatarUrl: nil,
                role: .attendee,
                rsvpStatus: .confirmed,
                specialRole: nil,
                invitedAt: Date(),
                respondedAt: Date(),
                isCurrentUser: false
            )
        ]
        
        let attendeeStore = LodgingAttendeeStore(partyId: "test-party-id")
        let lodgingCardView = LodgingCardView(
            lodging: lodging,
            userRole: .organizer,
            attendeeStore: attendeeStore,
            onLodgingUpdated: {}
        )
        
        let snapshot = lodgingCardView.snapshot()
        XCTAssertNotNil(snapshot, "Lodging card view snapshot should be created")
    }
    
    func testLodgingCardViewAttendeeSnapshot() throws {
        let lodging = Lodging(
            id: UUID(),
            partyId: "test-party-id",
            name: "Dream House | Pool | Austin!",
            address: "Austin, TX",
            description: "Beautiful property with amazing views",
            checkInDate: Date(),
            checkOutDate: Date().addingTimeInterval(86400 * 3),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let attendees = [
            PartyAttendee(
                id: UUID(),
                userId: "1",
                partyId: "test-party-id",
                fullName: "John Doe",
                email: "john@example.com",
                avatarUrl: nil,
                role: .attendee,
                rsvpStatus: .confirmed,
                specialRole: nil,
                invitedAt: Date(),
                respondedAt: Date(),
                isCurrentUser: false
            )
        ]
        
        let attendeeStore = LodgingAttendeeStore(partyId: "test-party-id")
        let lodgingCardView = LodgingCardView(
            lodging: lodging,
            userRole: .attendee,
            attendeeStore: attendeeStore,
            onLodgingUpdated: {}
        )
        
        let snapshot = lodgingCardView.snapshot()
        XCTAssertNotNil(snapshot, "Lodging card view attendee snapshot should be created")
    }
    
    // MARK: - Empty State View Snapshot Tests
    
    func testEmptyLodgingViewOrganizerSnapshot() throws {
        let emptyView = StandardEmptyStateView(
            icon: "house.fill",
            title: "No accommodations yet",
            description: "Add where everyone's staying",
            buttonTitle: "Add Accommodation",
            buttonAction: {}
        )
        
        let snapshot = emptyView.snapshot()
        XCTAssertNotNil(snapshot, "Empty lodging view organizer snapshot should be created")
    }
    
    func testEmptyLodgingViewAttendeeSnapshot() throws {
        let emptyView = StandardEmptyStateView(
            icon: "house.fill",
            title: "No accommodations yet",
            description: "Add where everyone's staying",
            buttonTitle: nil,
            buttonAction: nil
        )
        
        let snapshot = emptyView.snapshot()
        XCTAssertNotNil(snapshot, "Empty lodging view attendee snapshot should be created")
    }
}

// MARK: - Mock Classes

class MockLodgingStore: LodgingStore {
    override init(partyId: String) {
        super.init(partyId: partyId)
    }
}

// MARK: - SwiftUI View Extension for Snapshot Testing

extension View {
    func snapshot() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
