import Foundation

enum CSVExporter {
    /// Builds a CSV of every shot in `shots`, one row per shot, suitable for
    /// a coach to drop straight into a spreadsheet.
    static func export(shots: [ShotEvent], games: [GameSession]) -> String {
        let gamesByID = Dictionary(uniqueKeysWithValues: games.map { ($0.id, $0) })
        var lines = ["Date,Opponent,Period,Zone,ShotType,Outcome,Strength,Danger,Rush,Shooter,Notes"]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        for shot in shots.sorted(by: { $0.timestamp < $1.timestamp }) {
            let game = gamesByID[shot.gameID]
            let fields: [String] = [
                game.map { dateFormatter.string(from: $0.date) } ?? "",
                game?.opponentName ?? "",
                String(shot.period),
                shot.zone.displayName,
                shot.shotType.displayName,
                shot.outcome.displayName,
                shot.strengthState.shortLabel,
                shot.dangerLevel.displayName,
                shot.isRushOrOddMan ? "Yes" : "No",
                shot.shooterName ?? "",
                shot.notes ?? ""
            ]
            lines.append(fields.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else { return field }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    /// Writes the CSV to a temp file and returns its URL, ready for a
    /// `ShareLink` or `UIActivityViewController`.
    static func writeTempFile(csv: String, filename: String = "GoalieShotLog.csv") -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
