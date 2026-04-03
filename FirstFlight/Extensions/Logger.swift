import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "io.github.yurii-voievodin.FirstFlight"

    static let game = Logger(subsystem: subsystem, category: "Game")
    static let physics = Logger(subsystem: subsystem, category: "Physics")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let debug = Logger(subsystem: subsystem, category: "Debug")
}
