import Foundation
import Observation
import MMAudio
import MMMidi
import MMModels

/// Single root state object. All app-level mutable state lives here so
/// SwiftUI views can observe it via `@Environment(AppState.self)`.
@MainActor
@Observable
final class AppState {

    var project = Project()
    let audio = AudioEngine()

    /// MF64 device wrapper (nil until `start()` is called).
    var mf64: MidiFighter64?
    /// Korg nanoKONTROL device wrapper.
    var nano: KorgNanoKontrol?

    var mf64Status: ConnectionStatus = .disconnected
    var nanoStatus: ConnectionStatus = .disconnected

    /// Pads currently held down on the MF64 — used to flash the on-screen grid.
    var pressedCoords: Set<PadCoord> = []

    /// The pad that's currently the editing focus. Updated whenever a pad is
    /// triggered (on screen or via MF64). The sample browser, sample editor,
    /// and SHIFT-pad commands all target this address.
    var selectedPad: PadAddress = PadAddress(bank: .A, pad: PadIndex(0))

    /// Sample browser state (Observable). Owned by AppState; the sheet observes it.
    var browser: SampleBrowser

    /// Sample-browser sheet visibility.
    var isBrowserOpen: Bool = false

    /// Last MIDI event description for the diagnostics line.
    var lastEvent: String = "—"

    enum ConnectionStatus: Equatable {
        case disconnected
        case connected(name: String)
    }

    init() {
        audio.start()
        browser = SampleBrowser(audio: audio)
    }

    func start() {
        startMF64()
        startNano()
    }

    // MARK: - Pad operations

    /// On-screen click: select + trigger.
    func selectAndTrigger(_ pad: PadAddress, velocity: UInt8 = 127) {
        selectedPad = pad
        audio.triggerPad(pad, velocity: velocity)
    }

    /// Open the sample browser targeting `selectedPad`.
    func openBrowser() {
        browser.refresh()
        isBrowserOpen = true
    }

    /// Load whatever the browser is highlighting into `selectedPad`.
    func loadHighlightedToSelectedPad() {
        guard let entry = browser.highlightedEntry, entry.kind == .file else { return }
        do {
            try audio.loadSample(url: entry.url, into: selectedPad)
            project.pads[selectedPad]?.sampleURL = entry.url
            audio.stopPreview()
            lastEvent = "Loaded \(entry.displayName) → \(selectedPad)"
        } catch {
            NSLog("loadSample failed: \(error)")
            lastEvent = "Load failed: \(error.localizedDescription)"
        }
    }

    // MARK: - MIDI wiring

    private func startMF64() {
        let mf64 = MidiFighter64(
            onEvent: { [weak self] event in
                guard let self else { return }
                Task { @MainActor in self.handleMF(event) }
            },
            onFastTrigger: { [weak self] coord, velocity in
                // Runs on the CoreMIDI thread — straight to audio for low latency.
                guard let self else { return }
                let addr = PadMapping.address(for: coord)
                self.audio.triggerPad(addr, velocity: velocity)
            }
        )
        do {
            try mf64.start()
            self.mf64 = mf64
        } catch {
            NSLog("MF64 start failed: \(error)")
        }
    }

    private func startNano() {
        let nano = KorgNanoKontrol { [weak self] event in
            guard let self else { return }
            Task { @MainActor in self.handleNano(event) }
        }
        do {
            try nano.start()
            self.nano = nano
        } catch {
            NSLog("nanoKONTROL start failed: \(error)")
        }
    }

    private func handleMF(_ event: MidiFighter64.Event) {
        switch event {
        case .connected(let name):
            mf64Status = .connected(name: name)
        case .disconnected:
            mf64Status = .disconnected
        case .padPressed(let coord, _, let vel):
            pressedCoords.insert(coord)
            selectedPad = PadMapping.address(for: coord)
            lastEvent = "MF64 press \(coord) vel \(vel)"
        case .padReleased(let coord, _):
            pressedCoords.remove(coord)
            lastEvent = "MF64 release \(coord)"
        case .unknownNote(let note, let vel):
            lastEvent = "MF64 unknown note \(note) vel \(vel)"
        }
    }

    private func handleNano(_ event: KorgNanoKontrol.Event) {
        switch event {
        case .connected(let name):
            nanoStatus = .connected(name: name)
        case .disconnected:
            nanoStatus = .disconnected
        case .controlChange(let ch, let cc, let val):
            lastEvent = "nano CC ch=\(ch) cc=\(cc) val=\(val)"
        case .note(let ch, let note, let vel, let on):
            lastEvent = "nano \(on ? "on" : "off") ch=\(ch) note=\(note) vel=\(vel)"
        case .sysEx(let bytes):
            lastEvent = "nano SysEx \(bytes.count) bytes"
        }
    }
}
