import Foundation

// MARK: - Game Types
enum GameType: String, Codable, CaseIterable {
    case newlywed = "newlywed"
    
    var displayName: String {
        switch self {
        case .newlywed:
            return "Nearlywed Game"
        }
    }
    
    var description: String {
        switch self {
        case .newlywed:
            return "How well do the soon-to-be newlyweds really know each other? In this hilarious twist on the classic Newlywed Game, one partner secretly records video answers to a mix of questions. At the party, the guest of honor sits in the hot seat and answers those same questions live before revealing what their partner said. Did they match or totally miss? Keep score, spark big laughs, and find out just how in sync they really are."
        }
    }
    
    var icon: String {
        switch self {
        case .newlywed:
            return "💕"
        }
    }
}

// MARK: - Game Status
enum GameStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case ready = "ready"
    case complete = "complete"
    
    var displayName: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .ready:
            return "Ready"
        case .complete:
            return "Complete"
        }
    }
    
    var color: String {
        switch self {
        case .notStarted:
            return "gray"
        case .inProgress:
            return "blue"
        case .ready:
            return "green"
        case .complete:
            return "purple"
        }
    }
}

// MARK: - Question Lock Status
enum QuestionLockStatus: String, Codable, CaseIterable {
    case unlocked = "unlocked"
    case locked = "locked"
    case adminOverride = "admin_override"
    
    var displayName: String {
        switch self {
        case .unlocked:
            return "Unlocked"
        case .locked:
            return "Locked"
        case .adminOverride:
            return "Admin Override"
        }
    }
}

// MARK: - Recording Settings
struct GameRecordingSettings: Codable, Equatable {
    let maxRecordingDuration: Int
    let allowQuestionSkipping: Bool
    let forceRecordingBeforeNext: Bool
    
    init(
        maxRecordingDuration: Int = 300,
        allowQuestionSkipping: Bool = true,
        forceRecordingBeforeNext: Bool = false
    ) {
        self.maxRecordingDuration = maxRecordingDuration
        self.allowQuestionSkipping = allowQuestionSkipping
        self.forceRecordingBeforeNext = forceRecordingBeforeNext
    }
    
    enum CodingKeys: String, CodingKey {
        case maxRecordingDuration = "max_recording_duration"
        case allowQuestionSkipping = "allow_question_skipping"
        case forceRecordingBeforeNext = "force_recording_before_next"
    }
}

// MARK: - Respondent Progress
struct RespondentProgress: Codable, Equatable {
    let completedQuestions: [String]
    let lastActive: String
    let totalDuration: Int
    
    enum CodingKeys: String, CodingKey {
        case completedQuestions = "completed_questions"
        case lastActive = "last_active"
        case totalDuration = "total_duration"
    }
}

// MARK: - Main Party Game Model
struct PartyGame: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let partyId: UUID
    let createdBy: UUID
    let gameType: GameType
    let title: String
    let recorderName: String?
    let recorderPhone: String?
    let livePlayerName: String?
    let questions: [GameQuestion]
    let answers: [String: GameAnswer]
    let videos: [String: GameVideo]
    let status: GameStatus
    let createdAt: Date
    let updatedAt: Date
    let questionLockStatus: QuestionLockStatus?
    let questionVersion: Int?
    let lockedAt: Date?
    let recordingSettings: GameRecordingSettings?
    let respondentProgress: [String: RespondentProgress]?
    
    // Computed properties
    var questionCount: Int {
        questions.count
    }
    
    var answerCount: Int {
        videos.count
    }
    
    var isLocked: Bool {
        questionLockStatus == .locked
    }
    
    var canPlay: Bool {
        status == .ready && questionCount > 0 && answerCount == questionCount
    }
    
    var progressPercentage: Double {
        guard questionCount > 0 else { return 0 }
        return Double(answerCount) / Double(questionCount)
    }
    
    // Helper function to replace placeholders in question text
    func personalizeQuestion(_ questionText: String) -> String {
        var personalized = questionText
        if let recorder = recorderName {
            personalized = personalized.replacingOccurrences(of: "[X]", with: recorder)
        }
        if let livePlayer = livePlayerName {
            personalized = personalized.replacingOccurrences(of: "[Y]", with: livePlayer)
        }
        return personalized
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case createdBy = "created_by"
        case gameType = "game_type"
        case title
        case recorderName = "recorder_name"
        case recorderPhone = "recorder_phone"
        case livePlayerName = "live_player_name"
        case questions
        case answers
        case videos
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case questionLockStatus = "question_lock_status"
        case questionVersion = "question_version"
        case lockedAt = "locked_at"
        case recordingSettings = "recording_settings"
        case respondentProgress = "respondent_progress"
    }
    
    // Regular initializer for creating new games
    init(
        id: UUID = UUID(),
        partyId: UUID,
        createdBy: UUID,
        gameType: GameType,
        title: String,
        recorderName: String? = nil,
        recorderPhone: String? = nil,
        livePlayerName: String? = nil,
        questions: [GameQuestion],
        answers: [String: GameAnswer],
        videos: [String: GameVideo],
        status: GameStatus,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        questionLockStatus: QuestionLockStatus? = nil,
        questionVersion: Int? = nil,
        lockedAt: Date? = nil,
        recordingSettings: GameRecordingSettings? = nil,
        respondentProgress: [String: RespondentProgress]? = nil
    ) {
        self.id = id
        self.partyId = partyId
        self.createdBy = createdBy
        self.gameType = gameType
        self.title = title
        self.recorderName = recorderName
        self.recorderPhone = recorderPhone
        self.livePlayerName = livePlayerName
        self.questions = questions
        self.answers = answers
        self.videos = videos
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.questionLockStatus = questionLockStatus
        self.questionVersion = questionVersion
        self.lockedAt = lockedAt
        self.recordingSettings = recordingSettings
        self.respondentProgress = respondentProgress
    }
    
    // Custom decoding to handle string fields that should be JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        partyId = try container.decode(UUID.self, forKey: .partyId)
        createdBy = try container.decode(UUID.self, forKey: .createdBy)
        gameType = try container.decode(GameType.self, forKey: .gameType)
        title = try container.decode(String.self, forKey: .title)
        recorderName = try container.decodeIfPresent(String.self, forKey: .recorderName)
        recorderPhone = try container.decodeIfPresent(String.self, forKey: .recorderPhone)
        livePlayerName = try container.decodeIfPresent(String.self, forKey: .livePlayerName)
        status = try container.decode(GameStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        questionLockStatus = try container.decodeIfPresent(QuestionLockStatus.self, forKey: .questionLockStatus)
        questionVersion = try container.decodeIfPresent(Int.self, forKey: .questionVersion)
        lockedAt = try container.decodeIfPresent(Date.self, forKey: .lockedAt)
        
        // Handle questions - decode from string if needed
        if let questionsString = try? container.decode(String.self, forKey: .questions) {
            let questionsData = questionsString.data(using: .utf8) ?? Data()
            questions = (try? JSONDecoder().decode([GameQuestion].self, from: questionsData)) ?? []
        } else {
            questions = try container.decode([GameQuestion].self, forKey: .questions)
        }
        
        // Handle answers - decode from string if needed
        if let answersString = try? container.decode(String.self, forKey: .answers) {
            let answersData = answersString.data(using: .utf8) ?? Data()
            answers = (try? JSONDecoder().decode([String: GameAnswer].self, from: answersData)) ?? [:]
        } else {
            answers = try container.decode([String: GameAnswer].self, forKey: .answers)
        }
        
        // Handle videos - decode from string if needed
        if let videosString = try? container.decode(String.self, forKey: .videos) {
            let videosData = videosString.data(using: .utf8) ?? Data()
            videos = (try? JSONDecoder().decode([String: GameVideo].self, from: videosData)) ?? [:]
        } else {
            videos = try container.decode([String: GameVideo].self, forKey: .videos)
        }
        
        // Handle recording settings - decode from string if needed
        if let settingsString = try? container.decode(String.self, forKey: .recordingSettings) {
            let settingsData = settingsString.data(using: .utf8) ?? Data()
            recordingSettings = try? JSONDecoder().decode(GameRecordingSettings.self, from: settingsData)
        } else {
            recordingSettings = try container.decodeIfPresent(GameRecordingSettings.self, forKey: .recordingSettings)
        }
        
        // Handle respondent progress - decode from string if needed
        if let progressString = try? container.decode(String.self, forKey: .respondentProgress) {
            let progressData = progressString.data(using: .utf8) ?? Data()
            respondentProgress = try? JSONDecoder().decode([String: RespondentProgress].self, from: progressData)
        } else {
            respondentProgress = try container.decodeIfPresent([String: RespondentProgress].self, forKey: .respondentProgress)
        }
    }
    
    // MARK: - Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PartyGame, rhs: PartyGame) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Game Question
struct GameQuestion: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let text: String
    let category: String
    let isCustom: Bool
    let plannerNote: String?
    let questionForRecorder: String
    let questionForLiveGuest: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case category
        case isCustom = "is_custom"
        case plannerNote = "planner_note"
        case questionForRecorder = "question_for_recorder"
        case questionForLiveGuest = "question_for_live_guest"
    }
}

// MARK: - Game Answer
struct GameAnswer: Codable, Equatable {
    let questionId: String
    let guess: String?
    let isMatch: Bool?
    let points: Int?
    
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case guess
        case isMatch = "is_match"
        case points
    }
}

// MARK: - Game Video
struct GameVideo: Codable, Equatable {
    let questionId: String
    let videoUrl: String
    let thumbnailUrl: String?
    let uploadedAt: Date
    let duration: Int?
    let respondentName: String?
    
    enum CodingKeys: String, CodingKey {
        case questionId = "questionId"
        case videoUrl = "videoUrl"
        case thumbnailUrl = "thumbnailUrl"
        case uploadedAt = "uploadedAt"
        case duration
        case respondentName = "respondentName"
    }
}

// MARK: - Default Questions
extension GameQuestion {
    static let defaultNewlywedQuestions: [GameQuestion] = [
        GameQuestion(
            id: "template_1_1756814502894",
            text: "When did you first realize you were in love?",
            category: "relationship_romance",
            isCustom: false,
            plannerNote: "A sweet moment to capture",
            questionForRecorder: "When did you first realize you were in love?",
            questionForLiveGuest: "When did [Y] first realize they were in love?"
        ),
        GameQuestion(
            id: "template_2_1756814502895",
            text: "What's [Y]'s biggest fear?",
            category: "habits_personality",
            isCustom: false,
            plannerNote: "Get to know their vulnerabilities",
            questionForRecorder: "What's [Y]'s biggest fear?",
            questionForLiveGuest: "What does [Y] say is [X]'s biggest fear?"
        ),
        GameQuestion(
            id: "template_3_1756814502896",
            text: "What's [Y]'s favorite movie?",
            category: "wildcard_fun",
            isCustom: false,
            plannerNote: "A fun pop culture question",
            questionForRecorder: "What's [Y]'s favorite movie?",
            questionForLiveGuest: "What movie does [Y] say is [X]'s favorite?"
        ),
        GameQuestion(
            id: "template_4_1756814502897",
            text: "What's [Y]'s most annoying habit?",
            category: "habits_personality",
            isCustom: false,
            plannerNote: "Keep it light and funny",
            questionForRecorder: "What's [Y]'s most annoying habit?",
            questionForLiveGuest: "What does [Y] say is [X]'s most annoying habit?"
        ),
        GameQuestion(
            id: "template_5_1756814502898",
            text: "Where would [Y] want to go on their dream vacation?",
            category: "wildcard_fun",
            isCustom: false,
            plannerNote: "Dream big with this one",
            questionForRecorder: "Where would [Y] want to go on their dream vacation?",
            questionForLiveGuest: "Where does [Y] say [X] would want to go on their dream vacation?"
        ),
        GameQuestion(
            id: "template_6_1756814502899",
            text: "What's one chore that [Y] absolutely hates?",
            category: "habits_personality",
            isCustom: false,
            plannerNote: "Keep it light and relatable",
            questionForRecorder: "What's one chore that [Y] absolutely hates?",
            questionForLiveGuest: "What chore does [Y] say [X] absolutely hates?"
        ),
        GameQuestion(
            id: "template_7_1756814502900",
            text: "What's [Y]'s go-to comfort food?",
            category: "habits_personality",
            isCustom: false,
            plannerNote: "Food questions are always fun",
            questionForRecorder: "What's [Y]'s go-to comfort food?",
            questionForLiveGuest: "What does [Y] say is [X]'s go-to comfort food?"
        ),
        GameQuestion(
            id: "template_8_1756814502901",
            text: "What's [Y]'s biggest pet peeve?",
            category: "habits_personality",
            isCustom: false,
            plannerNote: "This could be funny",
            questionForRecorder: "What's [Y]'s biggest pet peeve?",
            questionForLiveGuest: "What does [Y] say is [X]'s biggest pet peeve?"
        )
    ]
}
