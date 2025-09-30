import SwiftUI

@main
struct Pinnacle_CalcApp: App {
    @StateObject private var vm = CalculatorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
        }
    }
}

@MainActor
final class CalculatorViewModel: ObservableObject {
    // UI-facing state
    @Published var display: String = "0"
    @Published private(set) var history: [HistoryItem] = []

    // Internal calculator state
    private var storedValue: Double? = nil
    private var pendingOp: String? = nil
    private var inTyping: Bool = false

    // Persistence
    private let historyKey = "calc.history.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        loadHistory()
    }

    // MARK: - Public API for the UI
    func tap(_ symbol: String) {
        switch symbol {
        case "0"..."9":
            enterDigit(symbol)
        case ".":
            enterDecimal()
        case "C":
            clear()
        case "±":
            toggleSign()
        case "%":
            percent()
        case "+", "−", "×", "÷":
            setOperation(symbol)
        case "=":
            equals()
        default:
            break
        }
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }

    // MARK: - Core logic
    private func enterDigit(_ d: String) {
        if inTyping {
            if display == "0" { display = d } else { display += d }
        } else {
            display = d
            inTyping = true
        }
    }

    private func enterDecimal() {
        if !display.contains(".") {
            display += inTyping ? "." : "0."
            inTyping = true
        }
    }

    private func clear() {
        display = "0"
        storedValue = nil
        pendingOp = nil
        inTyping = false
    }

    private func toggleSign() {
        if let v = Double(display) {
            display = clean(v * -1)
        }
    }

    private func percent() {
        if let v = Double(display) {
            display = clean(v / 100.0)
        }
    }

    private func setOperation(_ op: String) {
        if let current = Double(display) {
            if let pending = pendingOp, let stored = storedValue, inTyping {
                let result = apply(op: pending, a: stored, b: current)
                storedValue = result
                display = clean(result)
            } else {
                storedValue = current
            }
        }
        pendingOp = op
        inTyping = false
    }

    private func equals() {
        guard let op = pendingOp,
              let a = storedValue,
              let b = Double(display) else { return }

        let result = apply(op: op, a: a, b: b)
        let resultStr = clean(result)
        // Build the human-readable expression for history
        let expr = "\(clean(a)) \(op) \(clean(b))"
        display = resultStr
        pendingOp = nil
        storedValue = nil
        inTyping = false

        appendHistory(expression: expr, result: resultStr)
    }

    private func apply(op: String, a: Double, b: Double) -> Double {
        switch op {
        case "+": return a + b
        case "−": return a - b
        case "×": return a * b
        case "÷": return b == 0 ? a : a / b
        default:  return b
        }
    }

    private func clean(_ v: Double) -> String {
        String(format: "%g", v)
    }

    // MARK: - History bookkeeping
    private func appendHistory(expression: String, result: String) {
        let item = HistoryItem(expression: expression, result: result, timestamp: Date())
        history.insert(item, at: 0) // newest first
        saveHistory()
    }

    private func saveHistory() {
        do {
            let data = try encoder.encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            // Not the end of the world; history just won't persist this run.
            // In debug you could print(error.localizedDescription)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return }
        do {
            history = try decoder.decode([HistoryItem].self, from: data)
        } catch {
            history = [] // corrupt or version-changed; start fresh
        }
    }
}

// MARK: - Model
struct HistoryItem: Identifiable, Codable, Hashable {
    let id = UUID()
    let expression: String
    let result: String
    let timestamp: Date
}
