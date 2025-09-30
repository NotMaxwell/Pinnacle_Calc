import SwiftUI

struct CalcButton: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let background: Color
    let foreground: Color
    let widthMultiplier: CGFloat // 1 normal, 2 for "0"
}

struct ContentView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    @State private var showHistory: Bool = false

    // UI layout only (no logic)
    private let rows: [[CalcButton]] = [
        [
            .init(title: "C", background: .gray.opacity(0.3), foreground: .black, widthMultiplier: 1),
            .init(title: "±", background: .gray.opacity(0.3), foreground: .black, widthMultiplier: 1),
            .init(title: "%", background: .gray.opacity(0.3), foreground: .black, widthMultiplier: 1),
            .init(title: "÷", background: .orange, foreground: .white, widthMultiplier: 1),
        ],
        [
            .init(title: "7", background: .secondary.opacity(0.2), foreground: .white, widthMultiplier: 1),
            .init(title: "8", background: .secondary.opacity(0.2), foreground: .white, widthMultiplier: 1),
            .init(title: "9", background: .secondary.opacity(0.2), foreground: .white, widthMultiplier: 1),
            .init(title: "×", background: .orange, foreground: .white, widthMultiplier: 1),
        ],
        [
            .init(title: "4", background: .secondary.opacity(0.2), foreground: .white, widthMultiplier: 1),
            .init(title: "5", background: .secondary.opacity(0.2), foreground: .white, widthMultiplier: 1),
            .init(title: "6", background: .secondary.opacity(0.2), foreground: .white, widthMultiplier: 1),
            .init(title: "−", background: .orange, foreground: .white, widthMultiplier: 1),
        ],
        [
            .init(title: "1", background: .secondary.opacity(0.2), foreground: .white, widthMultiplier: 1),
            .init(title: "2", background: .secondary.opacity(0.2), foreground: .white, widthMultiplier: 1),
            .init(title: "3", background: .secondary.opacity(0.2), foreground: .white, widthMultiplier: 1),
            .init(title: "+", background: .orange, foreground: .white, widthMultiplier: 1),
        ],
        [
            .init(title: "0", background: .secondary.opacity(0.2), foreground: .white, widthMultiplier: 2),
            .init(title: ".", background: .secondary.opacity(0.2), foreground: .white, widthMultiplier: 1),
            .init(title: "=", background: .orange, foreground: .white, widthMultiplier: 1),
        ],
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                // Header row with History button
                HStack {
                    Button {
                        showHistory.toggle()
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .tint(.white)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                // Display (binds to vm state)
                HStack {
                    Spacer()
                    Text(vm.display)
                        .font(.system(size: 72, weight: .light, design: .rounded))
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                }
                .padding(.bottom, 8)

                // Buttons (UI only; delegates to vm.tap)
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { btn in
                            Button {
                                vm.tap(btn.title)
                            } label: {
                                Text(btn.title)
                                    .font(.system(size: 32, weight: .medium, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 72)
                                    .contentShape(Rectangle())
                                    .foregroundStyle(btn.foreground)
                                    .background(btn.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                            .frame(width: buttonWidth(multiplier: btn.widthMultiplier))
                        }
                    }
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $showHistory) {
            HistorySheet()
                .environmentObject(vm)
        }
    }

    // UI math only
    private func buttonWidth(multiplier: CGFloat) -> CGFloat {
        let totalPadding: CGFloat = 16 * 2  // outer padding
        let interItem: CGFloat = 12 * 3     // gaps between 4 items
        let screen = UIScreen.main.bounds.width
        let base = (screen - totalPadding - interItem) / 4
        return base * multiplier + (multiplier > 1 ? 12 : 0)
    }
}

// MARK: - History UI (still UI-only)
private struct HistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vm: CalculatorViewModel

    var body: some View {
        NavigationView {
            List {
                if vmHistoryIsEmpty {
                    Text("No history yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.history) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.expression)
                                .font(.headline)
                            Text("= \(item.result)")
                                .font(.title3)
                            Text(item.timestamp.formatted(date: .abbreviated, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete(perform: vm.deleteHistory)
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !vmHistoryIsEmpty {
                        Button("Clear All") { vm.clearHistory() }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var vmHistoryIsEmpty: Bool { vm.history.isEmpty }
}
