import SwiftUI

struct ExpenseSplitView: View {
    @Binding var formData: ExpenseFormData
    let attendees: [PartyAttendee]
    
    private var selectedAttendees: [PartyAttendee] {
        attendees.filter { formData.selectedUsers.contains($0.userId) }
    }
    
    private var evenSplitAmount: Double {
        guard !formData.selectedUsers.isEmpty else { return 0 }
        return (formData.amount ?? 0) / Double(formData.selectedUsers.count)
    }
    
    private var customSplitTotal: Double {
        formData.customSplits.values.reduce(0, +)
    }
    
    private var isCustomSplitValid: Bool {
        formData.splitType == .even || abs(customSplitTotal - (formData.amount ?? 0)) < 0.01
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Split Details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Split Type Toggle
                Picker("Split Type", selection: $formData.splitType) {
                    ForEach(SplitType.allCases, id: \.self) { splitType in
                        Text(splitType.displayName)
                            .tag(splitType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                            // User Selection
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Split With")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(formData.selectedUsers.count == attendees.count ? "Deselect All" : "Select All") {
                        if formData.selectedUsers.count == attendees.count {
                            formData.selectedUsers.removeAll()
                        } else {
                            formData.selectedUsers = Set(attendees.map { $0.userId })
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                }
                
                VStack(spacing: 12) {
                    ForEach(attendees, id: \.userId) { attendee in
                        ExpenseSplitRowView(
                            attendee: attendee,
                            isSelected: formData.selectedUsers.contains(attendee.userId),
                            splitAmount: formData.splitType == .even ? evenSplitAmount : (formData.customSplits[attendee.userId] ?? 0),
                            isEvenSplit: formData.splitType == .even,
                            onToggle: {
                                if formData.selectedUsers.contains(attendee.userId) {
                                    formData.selectedUsers.remove(attendee.userId)
                                    formData.customSplits.removeValue(forKey: attendee.userId)
                                } else {
                                    formData.selectedUsers.insert(attendee.userId)
                                    if formData.splitType == .even {
                                        formData.customSplits[attendee.userId] = evenSplitAmount
                                    }
                                }
                            },
                            onAmountChange: { amount in
                                formData.customSplits[attendee.userId] = amount
                            }
                        )
                    }
                }
            }
                
                // Split Summary
                VStack(spacing: 8) {
                    HStack {
                        Text("Total Split")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formData.splitType == .even ? 
                             String(format: "$%.2f", evenSplitAmount * Double(formData.selectedUsers.count)) :
                             String(format: "$%.2f", customSplitTotal))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isCustomSplitValid ? .primary : .red)
                    }
                    
                    HStack {
                        Text("Expense Amount")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f", formData.amount ?? 0))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    if formData.splitType == .custom && !isCustomSplitValid {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Split total doesn't match expense amount")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ExpenseSplitRowView: View {
    let attendee: PartyAttendee
    let isSelected: Bool
    let splitAmount: Double
    let isEvenSplit: Bool
    let onToggle: () -> Void
    let onAmountChange: (Double) -> Void
    
    @State private var customAmount: String = ""
    @FocusState private var isAmountFieldFocused: Bool
    
    var body: some View {
        HStack {
            // Selection Toggle
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            
            // Attendee Info
            Text(attendee.fullName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Amount Display/Input
            if isSelected {
                if isEvenSplit {
                    Text(String(format: "$%.2f", splitAmount))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                } else {
                    HStack {
                        Text("$")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $customAmount)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .font(.system(size: 16))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .focused($isAmountFieldFocused)
                            .onChange(of: customAmount) { newValue in
                                if let amount = Double(newValue) {
                                    onAmountChange(amount)
                                }
                            }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            if !isEvenSplit && isSelected {
                customAmount = String(format: "%.2f", splitAmount)
            }
        }
        .onChange(of: isEvenSplit) { _ in
            if isEvenSplit && isSelected {
                customAmount = String(format: "%.2f", splitAmount)
            }
        }
    }
}

#Preview {
    ExpenseSplitView(
        formData: .constant(ExpenseFormData()),
        attendees: [
            PartyAttendee(fullName: "John Doe"),
            PartyAttendee(fullName: "Jane Smith"),
            PartyAttendee(fullName: "Bob Johnson")
        ]
    )
    .padding()
}
