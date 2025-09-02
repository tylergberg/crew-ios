import SwiftUI

struct QuestionTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSelect: (GameQuestion) -> Void
    
    @State private var selectedCategory: String = "all"
    @State private var searchText = ""
    
    private let categories = [
        "all": "All Categories",
        "relationship_romance": "Relationship & Romance",
        "habits_personality": "Habits & Personality",
        "wildcard_fun": "Wildcard & Fun",
        "family_friends": "Family & Friends",
        "work_career": "Work & Career",
        "travel_adventure": "Travel & Adventure",
        "food_dining": "Food & Dining",
        "entertainment_culture": "Entertainment & Culture"
    ]
    
    private let allTemplates: [GameQuestion] = [
        // Relationship & Romance
        GameQuestion(
            id: "template_romance_1",
            text: "When did you first realize you were in love?",
            category: "relationship_romance",
            isCustom: false,
            plannerNote: "A sweet moment to capture",
            questionForRecorder: "When did you first realize you were in love?",
            questionForLiveGuest: "When did your partner first realize they were in love?"
        ),
        GameQuestion(
            id: "template_romance_2",
            text: "What's your favorite thing about your partner?",
            category: "relationship_romance",
            isCustom: false,
            plannerNote: "Celebrate what makes them special",
            questionForRecorder: "What's your favorite thing about your partner?",
            questionForLiveGuest: "What does your partner say is their favorite thing about you?"
        ),
        GameQuestion(
            id: "template_romance_3",
            text: "Where was your first kiss?",
            category: "relationship_romance",
            isCustom: false,
            plannerNote: "Romantic memory lane",
            questionForRecorder: "Where was your first kiss?",
            questionForLiveGuest: "Where does your partner say your first kiss was?"
        ),
        
        // Habits & Personality
        GameQuestion(
            id: "template_personality_1",
            text: "What's their biggest fear?",
            category: "habits_personality",
            isCustom: false,
            plannerNote: "Get to know their vulnerabilities",
            questionForRecorder: "What's their biggest fear?",
            questionForLiveGuest: "What does your partner say is your biggest fear?"
        ),
        GameQuestion(
            id: "template_personality_2",
            text: "What's their most annoying habit?",
            category: "habits_personality",
            isCustom: false,
            plannerNote: "Keep it light and funny",
            questionForRecorder: "What's their most annoying habit?",
            questionForLiveGuest: "What does your partner say is your most annoying habit?"
        ),
        GameQuestion(
            id: "template_personality_3",
            text: "What's their morning routine?",
            category: "habits_personality",
            isCustom: false,
            plannerNote: "Daily life insights",
            questionForRecorder: "What's their morning routine?",
            questionForLiveGuest: "What does your partner say is your morning routine?"
        ),
        
        // Wildcard & Fun
        GameQuestion(
            id: "template_fun_1",
            text: "What's their favorite movie?",
            category: "wildcard_fun",
            isCustom: false,
            plannerNote: "A fun pop culture question",
            questionForRecorder: "What's their favorite movie?",
            questionForLiveGuest: "What movie does your partner say is your favorite?"
        ),
        GameQuestion(
            id: "template_fun_2",
            text: "If they could have any superpower, what would it be?",
            category: "wildcard_fun",
            isCustom: false,
            plannerNote: "Imaginative and fun",
            questionForRecorder: "If you could have any superpower, what would it be?",
            questionForLiveGuest: "What superpower does your partner say you'd want?"
        ),
        GameQuestion(
            id: "template_fun_3",
            text: "What's their most embarrassing moment?",
            category: "wildcard_fun",
            isCustom: false,
            plannerNote: "Funny stories ahead",
            questionForRecorder: "What's your most embarrassing moment?",
            questionForLiveGuest: "What does your partner say is your most embarrassing moment?"
        ),
        
        // Family & Friends
        GameQuestion(
            id: "template_family_1",
            text: "Who's their best friend?",
            category: "family_friends",
            isCustom: false,
            plannerNote: "Friendship insights",
            questionForRecorder: "Who's your best friend?",
            questionForLiveGuest: "Who does your partner say is your best friend?"
        ),
        GameQuestion(
            id: "template_family_2",
            text: "What's their favorite family tradition?",
            category: "family_friends",
            isCustom: false,
            plannerNote: "Family values and memories",
            questionForRecorder: "What's your favorite family tradition?",
            questionForLiveGuest: "What does your partner say is your favorite family tradition?"
        ),
        
        // Work & Career
        GameQuestion(
            id: "template_work_1",
            text: "What's their dream job?",
            category: "work_career",
            isCustom: false,
            plannerNote: "Career aspirations",
            questionForRecorder: "What's your dream job?",
            questionForLiveGuest: "What does your partner say is your dream job?"
        ),
        GameQuestion(
            id: "template_work_2",
            text: "What's their biggest work achievement?",
            category: "work_career",
            isCustom: false,
            plannerNote: "Celebrate their success",
            questionForRecorder: "What's your biggest work achievement?",
            questionForLiveGuest: "What does your partner say is your biggest work achievement?"
        ),
        
        // Travel & Adventure
        GameQuestion(
            id: "template_travel_1",
            text: "Where would they want to go on their dream vacation?",
            category: "travel_adventure",
            isCustom: false,
            plannerNote: "Dream big with this one",
            questionForRecorder: "Where would you want to go on your dream vacation?",
            questionForLiveGuest: "Where does your partner say you'd want to go on your dream vacation?"
        ),
        GameQuestion(
            id: "template_travel_2",
            text: "What's their favorite travel memory?",
            category: "travel_adventure",
            isCustom: false,
            plannerNote: "Adventure stories",
            questionForRecorder: "What's your favorite travel memory?",
            questionForLiveGuest: "What does your partner say is your favorite travel memory?"
        ),
        
        // Food & Dining
        GameQuestion(
            id: "template_food_1",
            text: "What's their favorite food?",
            category: "food_dining",
            isCustom: false,
            plannerNote: "Culinary preferences",
            questionForRecorder: "What's your favorite food?",
            questionForLiveGuest: "What food does your partner say is your favorite?"
        ),
        GameQuestion(
            id: "template_food_2",
            text: "What's their go-to comfort meal?",
            category: "food_dining",
            isCustom: false,
            plannerNote: "Cozy food choices",
            questionForRecorder: "What's your go-to comfort meal?",
            questionForLiveGuest: "What does your partner say is your go-to comfort meal?"
        ),
        
        // Entertainment & Culture
        GameQuestion(
            id: "template_entertainment_1",
            text: "What's their favorite book?",
            category: "entertainment_culture",
            isCustom: false,
            plannerNote: "Literary tastes",
            questionForRecorder: "What's your favorite book?",
            questionForLiveGuest: "What book does your partner say is your favorite?"
        ),
        GameQuestion(
            id: "template_entertainment_2",
            text: "What's their favorite music genre?",
            category: "entertainment_culture",
            isCustom: false,
            plannerNote: "Musical preferences",
            questionForRecorder: "What's your favorite music genre?",
            questionForLiveGuest: "What music genre does your partner say is your favorite?"
        )
    ]
    
    private var filteredTemplates: [GameQuestion] {
        var filtered = allTemplates
        
        // Filter by category
        if selectedCategory != "all" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { question in
                question.text.localizedCaseInsensitiveContains(searchText) ||
                question.category.replacingOccurrences(of: "_", with: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search questions...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(categories.keys.sorted()), id: \.self) { key in
                            Button(action: { selectedCategory = key }) {
                                Text(categories[key] ?? "")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedCategory == key ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == key ? Color.blue : Color(.systemGray5))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                
                // Templates list
                List(filteredTemplates) { template in
                    TemplateQuestionRow(template: template) {
                        onSelect(template)
                        dismiss()
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Question Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Template Question Row
struct TemplateQuestionRow: View {
    let template: GameQuestion
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.text)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(template.category.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onSelect) {
                    Text("Add")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            
            if let note = template.plannerNote, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    QuestionTemplatesView { question in
        print("Selected template: \(question.text)")
    }
}
