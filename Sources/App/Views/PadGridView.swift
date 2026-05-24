import SwiftUI
import MMMidi
import MMModels

/// 8×8 pad grid mirroring the MF64. Each 4×4 quadrant is tinted to indicate
/// which MPC bank it maps to (A bottom-left, B bottom-right, C top-left,
/// D top-right). Pads flash white when held down on the hardware, and the
/// currently-selected pad shows a yellow outline. Clicking a pad selects
/// + triggers it.
struct PadGridView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<8) { row in
                HStack(spacing: 8) {
                    ForEach(0..<8) { col in
                        let coord = PadCoord(row: row, col: col)
                        let address = PadMapping.address(for: coord)
                        PadCell(
                            coord: coord,
                            address: address,
                            pressed: state.pressedCoords.contains(coord),
                            selected: state.selectedPad == address,
                            loaded: state.project.pads[address]?.sampleURL != nil
                        )
                        .onTapGesture {
                            state.selectAndTrigger(address)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(white: 0.12), in: .rect(cornerRadius: 12))
    }
}

private struct PadCell: View {
    let coord: PadCoord
    let address: PadAddress
    let pressed: Bool
    let selected: Bool
    let loaded: Bool

    var body: some View {
        let bankColor = Self.color(for: address.bank.rawValue)
        let fillColor: Color = {
            if pressed { return .white }
            if loaded { return bankColor.opacity(0.55) }
            return bankColor.opacity(0.22)
        }()

        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selected ? Color.yellow : bankColor.opacity(0.6),
                                lineWidth: selected ? 2.5 : 1)
                )

            VStack(spacing: 2) {
                Text(address.bank.description)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle((pressed ? Color.black : Color.white).opacity(0.7))
                Text("\(address.pad.label)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle((pressed ? Color.black : Color.white).opacity(0.85))
            }
        }
        .frame(width: 64, height: 64)
        .animation(.easeOut(duration: 0.08), value: pressed)
        .animation(.easeOut(duration: 0.12), value: selected)
    }

    static func color(for bankIndex: Int) -> Color {
        switch bankIndex % 8 {
        case 0: return .red       // A
        case 1: return .orange    // B
        case 2: return .yellow    // C
        case 3: return .green     // D
        case 4: return .mint
        case 5: return .cyan
        case 6: return .blue
        case 7: return .purple
        default: return .gray
        }
    }
}
