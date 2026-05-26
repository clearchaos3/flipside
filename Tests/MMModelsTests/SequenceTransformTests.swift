import Testing
@testable import MMModels

@Suite("Sequence transforms")
struct SequenceTransformTests {

    private func seq() -> MMSequence {
        var s = MMSequence()
        s.bars = 4
        // Events at 0, 1 bar (3840), 2 bars (7680), 3 bars (11520).
        s.events = [
            SequenceEvent(tick: 0,     bank: .A, pad: PadIndex(0), velocity: 100),
            SequenceEvent(tick: 3840,  bank: .A, pad: PadIndex(0), velocity: 100),
            SequenceEvent(tick: 7680,  bank: .A, pad: PadIndex(0), velocity: 100),
            SequenceEvent(tick: 11520, bank: .A, pad: PadIndex(0), velocity: 100),
        ]
        return s
    }

    @Test func halveLengthDropsEventsPastEnd() {
        var s = seq()
        s.halveLength()
        #expect(s.bars == 2)
        // New length = 2 bars = 7680. Events at 0 and 3840 kept; 7680/11520 dropped.
        #expect(s.events.count == 2)
    }

    @Test func doubleLengthDuplicates() {
        var s = seq()
        s.doubleLength()
        #expect(s.bars == 8)
        #expect(s.events.count == 8)
        // A duplicate of the first event lands at old length (4 bars = 15360).
        #expect(s.events.contains { $0.tick == 15360 })
    }

    @Test func halfSpeedSpreadsOut() {
        var s = seq()
        s.halfSpeed()
        #expect(s.bars == 8)
        #expect(s.events.map(\.tick).max() == 23040)  // 11520 × 2
    }

    @Test func doubleSpeedCompresses() {
        var s = seq()
        s.doubleSpeed()
        #expect(s.bars == 2)
        #expect(s.events.map(\.tick).max() == 5760)   // 11520 / 2
    }
}
