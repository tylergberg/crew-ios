import SwiftUI

// MARK: - Main Itinerary Tab View
struct ItineraryTabView: View {
    let partyId: String
    let currentUserId: String
    let userRole: UserRole
    let cityTimezone: String?
    
    @StateObject private var itineraryService: ItineraryService
    @State private var selectedDate: Date = Date()
    @State private var showAddEventSheet = false
    @State private var showEditEventSheet = false
    @State private var eventToEdit: ItineraryEvent?
    @State private var itineraryView: ItineraryViewType = .list
    
    enum ItineraryViewType: String, CaseIterable {
        case list = "List"
        case calendar = "Calendar"
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .calendar: return "calendar"
            }
        }
    }
    
    init(partyId: String, currentUserId: String, userRole: UserRole, cityTimezone: String?) {
        self.partyId = partyId
        self.currentUserId = currentUserId
        self.userRole = userRole
        self.cityTimezone = cityTimezone
        
        let supabase = SupabaseManager.shared.client
        self._itineraryService = StateObject(wrappedValue: ItineraryService(supabase: supabase))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented control under the nav bar - fixed position
            VStack(spacing: 0) {
                Picker("View", selection: $itineraryView) {
                    ForEach(ItineraryViewType.allCases, id: \.self) { viewType in
                        Text(viewType.rawValue).tag(viewType)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])
                .padding(.bottom, 8)
            }
            .background(Color(.systemBackground))
            
            // Content based on view type
            Group {
                if itineraryView == .list {
                    ItineraryListView(
                        itineraryService: itineraryService,
                        selectedDate: $selectedDate,
                        cityTimezone: cityTimezone,
                        onEditEvent: { event in
                            eventToEdit = event
                            showEditEventSheet = true
                        }
                    )
                } else {
                    ItineraryCalendarView(
                        events: itineraryService.events,
                        selectedDate: $selectedDate,
                        cityTimezone: cityTimezone,
                        onEditEvent: { event in
                            eventToEdit = event
                            showEditEventSheet = true
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Itinerary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if canManageItinerary {
                    Button(action: { showAddEventSheet = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                    .accessibilityLabel("Add Event")
                }
            }
        }
        .onAppear {
            Task {
                await itineraryService.fetchEvents(for: partyId)
            }
        }
        .sheet(isPresented: $showAddEventSheet) {
            AddEventSheet(
                partyId: partyId,
                currentUserId: currentUserId,
                cityTimezone: cityTimezone,
                onEventAdded: { event in
                    Task {
                        do {
                            try await itineraryService.addEvent(event)
                        } catch {
                            itineraryService.errorMessage = "Failed to add event: \(error.localizedDescription)"
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showEditEventSheet) {
            if let event = eventToEdit {
                EditEventSheet(
                    event: event,
                    cityTimezone: cityTimezone,
                    onEventUpdated: { updatedEvent in
                        Task {
                            do {
                                try await itineraryService.updateEvent(updatedEvent)
                            } catch {
                                itineraryService.errorMessage = "Failed to update event: \(error.localizedDescription)"
                            }
                        }
                    },
                    onEventDeleted: { eventId in
                        Task {
                            do {
                                try await itineraryService.deleteEvent(eventId)
                            } catch {
                                itineraryService.errorMessage = "Failed to delete event: \(error.localizedDescription)"
                            }
                        }
                    }
                )
            }
        }
    }
    
    private var canManageItinerary: Bool {
        userRole == .admin || userRole == .organizer
    }
}

// MARK: - List View
struct ItineraryListView: View {
    @ObservedObject var itineraryService: ItineraryService
    @Binding var selectedDate: Date
    let cityTimezone: String?
    let onEditEvent: (ItineraryEvent) -> Void
    
    @State private var groupedEvents: [String: [ItineraryEvent]] = [:]
    
    private var events: [ItineraryEvent] {
        itineraryService.events
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if events.isEmpty {
                    ItineraryEmptyStateView()
                } else {
                    ForEach(sortedDates, id: \.self) { dateString in
                        if let eventsForDate = groupedEvents[dateString] {
                            DateSectionView(
                                dateString: dateString,
                                events: eventsForDate,
                                cityTimezone: cityTimezone,
                                onEditEvent: onEditEvent
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            print("🔍 [ItineraryListView] onAppear - events count: \(events.count)")
            groupEventsByDate()
        }
        .onChange(of: itineraryService.events) { newEvents in
            print("🔍 [ItineraryListView] onChange(itineraryService.events) - new count: \(newEvents.count)")
            groupEventsByDate()
        }
    }
    
    private var sortedDates: [String] {
        groupedEvents.keys.sorted { date1, date2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let date1Obj = formatter.date(from: date1),
                  let date2Obj = formatter.date(from: date2) else {
                return false
            }
            return date1Obj < date2Obj
        }
    }
    
    private func groupEventsByDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var grouped: [String: [ItineraryEvent]] = [:]
        
        print("🔍 [ItineraryListView] Grouping \(events.count) events by date")
        
        for event in events {
            if let startTime = event.startTime {
                let dateString = formatter.string(from: startTime)
                if grouped[dateString] == nil {
                    grouped[dateString] = []
                }
                grouped[dateString]?.append(event)
                print("🔍 [ItineraryListView] Added event '\(event.title)' to date \(dateString)")
            } else {
                print("⚠️ [ItineraryListView] Event '\(event.title)' has no startTime")
            }
        }
        
        // Sort events within each date by start time
        for dateString in grouped.keys {
            grouped[dateString]?.sort { event1, event2 in
                guard let time1 = event1.startTime,
                      let time2 = event2.startTime else {
                    return false
                }
                return time1 < time2
            }
        }
        
        groupedEvents = grouped
        print("🔍 [ItineraryListView] Grouped events into \(grouped.keys.count) dates: \(Array(grouped.keys))")
    }
}

// MARK: - Calendar View
struct ItineraryCalendarView: View {
    let events: [ItineraryEvent]
    @Binding var selectedDate: Date
    let cityTimezone: String?
    let onEditEvent: (ItineraryEvent) -> Void
    
    @State private var currentMonth = Date()
    
    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Day headers
                ForEach(dayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(height: 30)
                }
                
                // Calendar days
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            events: eventsForDate(date),
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            onTap: { selectedDate = date }
                        )
                    } else {
                        Color.clear
                            .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal)
            
            // Events for selected date
            if let selectedDateEvents = eventsForDate(selectedDate), !selectedDateEvents.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Events for \(formatSelectedDate(selectedDate))")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(selectedDateEvents.count) event\(selectedDateEvents.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(selectedDateEvents) { event in
                                CompactEventRowView(
                                    event: event,
                                    cityTimezone: cityTimezone,
                                    onEdit: { onEditEvent(event) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Text("No events on \(formatSelectedDate(selectedDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Add Event") {
                        // This will be handled by the parent view
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
            }
        }
        .onAppear {
            currentMonth = Date()
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var dayHeaders: [String] {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
    
    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days of the month
        for day in 1...daysInMonth {
            let calendar = Calendar.current
            let dayComponents = calendar.dateComponents([.year, .month], from: startOfMonth)
            var newComponents = dayComponents
            newComponents.day = day
            if let date = calendar.date(from: newComponents) {
                days.append(date)
            }
        }
        
        // Add empty cells to complete the last week
        let remainingCells = 7 - (days.count % 7)
        if remainingCells < 7 {
            for _ in 0..<remainingCells {
                days.append(nil)
            }
        }
        
        return days
    }
    
    private func eventsForDate(_ date: Date) -> [ItineraryEvent]? {
        let calendar = Calendar.current
        return events.filter { event in
            guard let eventDate = event.startTime else { return false }
            return calendar.isDate(eventDate, inSameDayAs: date)
        }
    }
    
    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let today = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func previousMonth() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        if let currentMonthInt = components.month,
           let currentYear = components.year {
            let newMonth = currentMonthInt == 1 ? 12 : currentMonthInt - 1
            let newYear = currentMonthInt == 1 ? currentYear - 1 : currentYear
            var newComponents = DateComponents()
            newComponents.year = newYear
            newComponents.month = newMonth
            newComponents.day = 1
            if let newDate = calendar.date(from: newComponents) {
                currentMonth = newDate
            }
        }
    }
    
    private func nextMonth() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        if let currentMonthInt = components.month,
           let currentYear = components.year {
            let newMonth = currentMonthInt == 12 ? 1 : currentMonthInt + 1
            let newYear = currentMonthInt == 12 ? currentYear + 1 : currentYear
            var newComponents = DateComponents()
            newComponents.year = newYear
            newComponents.month = newMonth
            newComponents.day = 1
            if let newDate = calendar.date(from: newComponents) {
                currentMonth = newDate
            }
        }
    }
}

// MARK: - Supporting Views
struct DateSectionView: View {
    let dateString: String
    let events: [ItineraryEvent]
    let cityTimezone: String?
    let onEditEvent: (ItineraryEvent) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date header
            HStack {
                Text(formatDateHeader(dateString))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Events for this date
            VStack(spacing: 8) {
                ForEach(events) { event in
                    EventRowView(
                        event: event,
                        cityTimezone: cityTimezone,
                        onEdit: { onEditEvent(event) }
                    )
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func formatDateHeader(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let today = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

struct EventRowView: View {
    let event: ItineraryEvent
    let cityTimezone: String?
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Event image or placeholder
            if let imageUrl = event.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                    )
            }
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let location = event.location, !location.isEmpty {
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let startTime = event.startTime {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatEventTime(startTime, endTime: event.endTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func formatEventTime(_ startTime: Date, endTime: Date?) -> String {
        if let cityTimezone = cityTimezone {
            print("🔍 [EventRowView] formatEventTime - cityTimezone: '\(cityTimezone)', startTime: \(startTime)")
            // Use TimezoneUtils to format in the party's city timezone
            let startTimeString = TimezoneUtils.formatInTimezone(startTime, timezone: cityTimezone, format: "h:mm a")
            print("🔍 [EventRowView] formatEventTime - formatted startTime: '\(startTimeString)'")
            
            if let endTime = endTime {
                let endTimeString = TimezoneUtils.formatInTimezone(endTime, timezone: cityTimezone, format: "h:mm a")
                return "\(startTimeString) - \(endTimeString)"
            } else {
                return startTimeString
            }
        } else {
            // Fallback to local timezone if no city timezone available
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            
            if let endTime = endTime {
                return "\(timeFormatter.string(from: startTime)) - \(timeFormatter.string(from: endTime))"
            } else {
                return timeFormatter.string(from: startTime)
            }
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let events: [ItineraryEvent]?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Event indicators
                if let events = events, !events.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(events.prefix(3), id: \.id) { _ in
                            Circle()
                                .fill(isSelected ? .white : .blue)
                                .frame(width: 4, height: 4)
                        }
                        
                        if events.count > 3 {
                            Text("+\(events.count - 3)")
                                .font(.system(size: 8))
                                .foregroundColor(isSelected ? .white : .blue)
                        }
                    }
                }
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompactEventRowView: View {
    let event: ItineraryEvent
    let cityTimezone: String?
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Event indicator
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
            
            // Event details
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let startTime = event.startTime {
                    Text(formatEventTime(startTime, endTime: event.endTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(6)
    }
    
    private func formatEventTime(_ startTime: Date, endTime: Date?) -> String {
        if let cityTimezone = cityTimezone {
            // Use TimezoneUtils to format in the party's city timezone
            let startTimeString = TimezoneUtils.formatInTimezone(startTime, timezone: cityTimezone, format: "h:mm a")
            
            if let endTime = endTime {
                let endTimeString = TimezoneUtils.formatInTimezone(endTime, timezone: cityTimezone, format: "h:mm a")
                return "\(startTimeString) - \(endTimeString)"
            } else {
                return startTimeString
            }
        } else {
            // Fallback to local timezone if no city timezone available
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            
            if let endTime = endTime {
                return "\(timeFormatter.string(from: startTime)) - \(timeFormatter.string(from: endTime))"
            } else {
                return timeFormatter.string(from: startTime)
            }
        }
    }
}

struct ItineraryEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No events scheduled")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Add your first event to get started with planning your trip!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ItineraryTabView(
        partyId: "test-party-id",
        currentUserId: "test-user-id",
        userRole: .organizer,
        cityTimezone: "America/New_York"
    )
}
