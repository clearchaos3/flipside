import SwiftUI
import MMModels

struct CompressorView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var state = state
        VStack(spacing: 18) {
            HStack {
                Text("Color Compressor")
                    .font(.system(.headline, design: .monospaced, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
                Toggle("Bypass", isOn: Binding(
                    get: { !state.compressorBinding.enabled },
                    set: { state.compressorBinding.enabled = !$0 }))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .foregroundStyle(.white.opacity(0.8))
            }

            HStack(spacing: 30) {
                KnobView(label: "Attack",
                         value: Binding(
                            get: { (state.compressorBinding.attackMs - 0.1) / 149.9 },
                            set: { state.compressorBinding.attackMs = 0.1 + $0 * 149.9 }),
                         displayValue: String(format: "%.1f ms", state.compressorBinding.attackMs))

                KnobView(label: "Release",
                         value: Binding(
                            get: { (state.compressorBinding.releaseMs - 3) / 297 },
                            set: { state.compressorBinding.releaseMs = 3 + $0 * 297 }),
                         displayValue: String(format: "%.0f ms", state.compressorBinding.releaseMs))

                KnobView(label: "Amount",
                         value: Binding(
                            get: { state.compressorBinding.amount },
                            set: { state.compressorBinding.amount = $0 }),
                         displayValue: String(format: "%.0f%%", state.compressorBinding.amount * 100))

                KnobView(label: "In Boost",
                         value: Binding(
                            get: { state.compressorBinding.inBoostDB / 24 },
                            set: { state.compressorBinding.inBoostDB = $0 * 24 }),
                         displayValue: String(format: "+%.1f dB", state.compressorBinding.inBoostDB))
            }

            HStack {
                Toggle("Color (warmth)", isOn: Binding(
                    get: { state.compressorBinding.color },
                    set: { state.compressorBinding.color = $0 }))
                    .toggleStyle(.checkbox)
                    .foregroundStyle(.white.opacity(0.7))
                    .help("Parallel bass boost + saturation (not yet implemented)")
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 520)
        .background(Color(white: 0.10))
    }
}
