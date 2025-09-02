//
//  PartyDetailTab.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-07-30.
//
import Foundation

enum PartyDetailTab: String, CaseIterable, Identifiable {
    case overview, crew, chat, itinerary, vendors, lodging, transport, expenses
    case packing, tasks, gallery, ai, games, merch, map

    var id: String { self.rawValue }

    var label: String {
        switch self {
        case .overview: return "Overview"
        case .crew: return "Crew"
        case .chat: return "Chat"
        case .itinerary: return "Itinerary"
        case .vendors: return "Experiences"
        case .lodging: return "Lodging"
        case .transport: return "Transport"
        case .expenses: return "Expenses"
        case .packing: return "Packing"
        case .tasks: return "Tasks"
        case .gallery: return "Album"
        case .ai: return "AI"
        case .games: return "Games"
        case .merch: return "Merch"
        case .map: return "Map"
        }
    }

    var iconName: String {
        switch self {
        case .overview: return "rectangle.grid.1x2"
        case .crew: return "person.3"
        case .chat: return "bubble.left.and.bubble.right"
        case .itinerary: return "calendar"
        case .vendors: return "cart"
        case .lodging: return "bed.double"
        case .transport: return "airplane"
        case .expenses: return "dollarsign.circle"
        case .packing: return "shippingbox"
        case .tasks: return "checkmark.square"
        case .gallery: return "photo.on.rectangle"
        case .ai: return "brain"
        case .games: return "gamecontroller"
        case .merch: return "tshirt"
        case .map: return "map"
        }
    }
}
