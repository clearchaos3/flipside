import Foundation

/// Master-bus compressor settings — the MPC Sample "Color Compressor".
/// Lives in MMModels so it persists in the Project and is readable by the
/// audio engine.
public struct CompressorSettings: Hashable, Codable, Sendable {
    public var enabled: Bool = false
    public var attackMs: Double = 10      // 0.1 … 150
    public var releaseMs: Double = 100    // 3 … 300
    public var amount: Double = 0.5       // 0 … 1 (→ threshold depth)
    public var inBoostDB: Double = 0      // makeup / drive
    public var color: Bool = false        // parallel bass-boost + warmth (TODO)

    public init() {}
}
