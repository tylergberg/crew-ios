import Foundation

/// Utility for replacing placeholder names in game questions
struct PlaceholderReplacer {
    
    /// Replace [X] and [Y] placeholders with actual player names
    /// - Parameters:
    ///   - text: The text containing placeholders
    ///   - recorderName: Name of the recorder (replaces [X])
    ///   - livePlayerName: Name of the live player (replaces [Y])
    /// - Returns: Text with placeholders replaced
    static func replacePlaceholders(
        in text: String,
        recorderName: String?,
        livePlayerName: String?
    ) -> String {
        var replacedText = text
        
        // Replace [X] with recorder name, fallback to "Partner A"
        let recorderDisplayName = recorderName?.isEmpty == false ? recorderName! : "Partner A"
        replacedText = replacedText.replacingOccurrences(of: "[X]", with: recorderDisplayName)
        
        // Replace [Y] with live player name, fallback to "Partner B"
        let livePlayerDisplayName = livePlayerName?.isEmpty == false ? livePlayerName! : "Partner B"
        replacedText = replacedText.replacingOccurrences(of: "[Y]", with: livePlayerDisplayName)
        
        return replacedText
    }
}

/// Extension to make it easier to use with PartyGame objects
extension PlaceholderReplacer {
    
    /// Replace placeholders using names from a PartyGame
    /// - Parameters:
    ///   - text: The text containing placeholders
    ///   - game: The PartyGame containing recorder and live player names
    /// - Returns: Text with placeholders replaced
    static func replacePlaceholders(in text: String, using game: PartyGame) -> String {
        return replacePlaceholders(
            in: text,
            recorderName: game.recorderName,
            livePlayerName: game.livePlayerName
        )
    }
}

/// Extension to make it work with GameQuestion objects
extension GameQuestion {
    
    /// Get the question text with placeholders replaced
    /// - Parameter game: The PartyGame containing recorder and live player names
    /// - Returns: Question text with placeholders replaced
    func textWithReplacedPlaceholders(using game: PartyGame) -> String {
        return PlaceholderReplacer.replacePlaceholders(in: self.text, using: game)
    }
    
    /// Get the recorder question with placeholders replaced
    /// - Parameter game: The PartyGame containing recorder and live player names
    /// - Returns: Recorder question with placeholders replaced
    func questionForRecorderWithReplacedPlaceholders(using game: PartyGame) -> String {
        return PlaceholderReplacer.replacePlaceholders(in: self.questionForRecorder, using: game)
    }
    
    /// Get the live guest question with placeholders replaced
    /// - Parameter game: The PartyGame containing recorder and live player names
    /// - Returns: Live guest question with placeholders replaced
    func questionForLiveGuestWithReplacedPlaceholders(using game: PartyGame) -> String {
        return PlaceholderReplacer.replacePlaceholders(in: self.questionForLiveGuest, using: game)
    }
}

