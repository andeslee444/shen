import os.log

enum TerrainLogger {
    private static let subsystem = "com.terrainhealth.app"

    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let sync        = Logger(subsystem: subsystem, category: "sync")
    static let navigation  = Logger(subsystem: subsystem, category: "navigation")
    static let contentPack = Logger(subsystem: subsystem, category: "contentPack")
    static let weather     = Logger(subsystem: subsystem, category: "weather")
}
