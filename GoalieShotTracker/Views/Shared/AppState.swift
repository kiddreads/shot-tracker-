import Foundation
import Observation

/// Cross-tab UI state: which goalie is currently selected (for a
/// single-goalie household this is just "the" goalie; a coach tracking a
/// whole roster switches it from the Roster tab) and which game, if any,
/// is currently being logged live.
@Observable
final class AppState {
    var selectedGoalieID: UUID?
    var activeGameID: UUID?
}
