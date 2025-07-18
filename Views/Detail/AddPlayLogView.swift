//
//  AddPlayLogView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import SwiftUI
import Markdown
// If you have a markdown-capable editor, import it here, e.g.:
// import MarkdownText

struct AddPlayLogView: View {
    @Environment(\.dismiss) var dismiss
    // New/Editing support
    var date: Date = Date()
    var hours: Int = 0
    var minutes: Int = 0
    var notes: String = ""
    var isCheckpoint: Bool = false
    var title: String = ""
    var onAdd: ((PlayLogEntry) -> Void)? = nil
    var onSave: ((PlayLogEntry) -> Void)? = nil
    var onCancel: (() -> Void)? = nil

    @State private var dateState: Date
    @State private var hoursString: String
    @State private var minutesString: String
    @State private var notesState: String
    @State private var isCheckpointState: Bool
    @State private var timerRunning: Bool = false
    @State private var timerStartDate: Date? = nil
    @State private var elapsedSeconds: Int = 0
    @State private var titleState: String

    init(date: Date = Date(), hours: Int = 0, minutes: Int = 0, notes: String = "", isCheckpoint: Bool = false, title: String = "", onAdd: ((PlayLogEntry) -> Void)? = nil, onSave: ((PlayLogEntry) -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.date = date
        self.hours = hours
        self.minutes = minutes
        self.notes = notes
        self.isCheckpoint = isCheckpoint
        self.title = title
        self.onAdd = onAdd
        self.onSave = onSave
        self.onCancel = onCancel
        _dateState = State(initialValue: date)
        _hoursString = State(initialValue: String(hours))
        _minutesString = State(initialValue: String(minutes))
        _notesState = State(initialValue: notes)
        _isCheckpointState = State(initialValue: isCheckpoint)
        _titleState = State(initialValue: title)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker("", selection: $dateState, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                Section("Title (Optional)") {
                    TextField("Title", text: $titleState)
                        .autocapitalization(.sentences)
                        .disableAutocorrection(false)
                }
                Section("Time Spent") {
                    HStack {
                        TextField("Hours", text: $hoursString).keyboardType(.numberPad).multilineTextAlignment(.center)
                        Text("hours")
                        TextField("Minutes", text: $minutesString).keyboardType(.numberPad).multilineTextAlignment(.center)
                        Text("min")
                        Spacer()
                        Button(action: { timerButtonTapped() }) {
                            Image(systemName: timerRunning ? "stop.circle.fill" : "timer")
                                .font(.title2)
                                .foregroundColor(timerRunning ? .red : .accentColor)
                        }
                        .accessibilityLabel(timerRunning ? "Stop Timer" : "Start Timer")
                    }
                    if timerRunning {
                        Text("Timer running: \(formattedElapsedTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Section {
                    Toggle("Checkpoint", isOn: $isCheckpointState)
                }
                Section("Session Notes") {
                    TextEditor(text: $notesState)
                        .frame(height: 150)
                        .autocapitalization(.sentences)
                        .disableAutocorrection(false)
                        .font(.body)
                        .lineSpacing(4)
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .accessibilityLabel("Session Notes. Supports markdown formatting.")
                    ScrollView(.vertical, showsIndicators: true) {
                        Markdown(content: $notesState)
                            .padding(.top, 8)
                            .frame(minHeight: 80, maxHeight: 200, alignment: .topLeading)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("Live markdown preview of session notes.")
                    }
                }
            }
            .navigationTitle(onSave != nil ? "Edit Play Log" : "Add Play Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if let onCancel = onCancel { onCancel() } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEntry() }
                }
            }
        }
        .onChange(of: timerRunning) { _, running in
            if running {
                timerStartDate = Date()
                elapsedSeconds = 0
                startTimer()
            }
        }
    }

    private func timerButtonTapped() {
        if timerRunning {
            // Stop timer and fill hours/minutes
            timerRunning = false
            if let start = timerStartDate {
                let total = Int(Date().timeIntervalSince(start))
                let totalMinutes = total / 60
                hoursString = String(totalMinutes / 60)
                minutesString = String(totalMinutes % 60)
            }
        } else {
            timerRunning = true
        }
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if !timerRunning {
                timer.invalidate()
            } else {
                elapsedSeconds += 1
            }
        }
    }

    private var formattedElapsedTime: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func saveEntry() {
        let hours = Int(hoursString) ?? 0
        let minutes = Int(minutesString) ?? 0
        let timeInSeconds = TimeInterval((hours * 3600) + (minutes * 60))
        let newEntry = PlayLogEntry(timestamp: dateState, timeSpent: timeInSeconds, notes: notesState, checkpoint: isCheckpointState, title: titleState.isEmpty ? nil : titleState)
        if let onSave = onSave {
            onSave(newEntry)
        } else if let onAdd = onAdd {
            onAdd(newEntry)
        }
        dismiss()
    }
}
