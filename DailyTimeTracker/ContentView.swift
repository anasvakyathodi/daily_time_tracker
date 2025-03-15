//
//  ContentView.swift
//  DailyTimeTracker
//
//  Created by Anas Vakyathodi on 15/03/25.
//

import Foundation
import SwiftUI
import CoreData

struct ContentView: View {
    @State private var taskName = ""
    @State private var hours = 0
    @State private var minutes = 0
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var tasks: [TaskItem] = []
    @State private var editingTaskIndex: Int? = nil
    
    // Timer tracking states
    @State private var isRecording = false
    @State private var timerStartTime: Date?
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    @State private var showingNamePrompt = false
    @State private var recordedHours = 0
    @State private var recordedMinutes = 0
    
    // Add this to ContentView
    @State private var recentTaskNames: [String] = []
    @State private var showingTimePresets = false
    @State private var searchText = ""
    
    // Add this state variable to your ContentView
    @State private var taskNotes = ""
    
    // Add this property to ContentView
    @Environment(\.scenePhase) private var scenePhase
    
    // Add this state variable to track when we should force a prompt
    @State private var shouldShowPrompt = false
    
    // Add this state variable if not already present
    @State private var showingNotesField = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with day navigation
            HStack {
                Button(action: previousDay) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 4)
                
                Text(formattedDate)
                    .font(.headline)
                    .padding(.vertical)
                
                Spacer()
                
                Button(action: nextDay) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 4)
                
                Button(action: {
                    showingDatePicker.toggle()
                }) {
                    Image(systemName: "calendar")
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            if showingDatePicker {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .onChange(of: selectedDate) { _, _ in
                        loadTasks()
                        showingDatePicker = false
                    }
            }
            
            Divider()
            
            // Reorganized task input area with proper notes toggle button
            VStack(spacing: 8) {
                // First row: Task name and notes button
                HStack {
                    TextField(editingTaskIndex != nil ? "Edit task name..." : "What are you working on?", text: $taskName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // Notes toggle button - always visible
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingNotesField.toggle()
                        }
                    }) {
                        Image(systemName: showingNotesField ? "note.text.fill" : "note.text")
                            .foregroundColor(showingNotesField ? .blue : .secondary)
                            .font(.system(size: 15))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(showingNotesField ? "Hide notes field" : "Show notes field")
                }
                .padding(.horizontal, 10)
                
                // Optional notes field
                if showingNotesField {
                    TextField("Notes (optional)", text: $taskNotes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.horizontal, 10)
                }
                
                // Second row: Time controls and action buttons
                HStack(spacing: 8) {
                    // Time input with steppers
                    HStack(spacing: 6) {
                        // Hours stepper
                        TimeStepperView(
                            value: isRecording ? .constant(elapsedSeconds / 3600) : $hours,
                            label: "h",
                            range: 0...23,
                            isEnabled: !isRecording
                        )
                        
                        Text(":")
                            .font(.system(.body, design: .monospaced))
                        
                        // Minutes stepper
                        TimeStepperView(
                            value: isRecording ? .constant((elapsedSeconds % 3600) / 60) : $minutes,
                            label: "m",
                            range: 0...59,
                            isEnabled: !isRecording
                        )
                        
                        // Show seconds when recording
                        if isRecording {
                            Text(":")
                                .font(.system(.body, design: .monospaced))
                            
                            Text("\(elapsedSeconds % 60)s")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.blue)
                                .frame(width: 30)
                        }
                        
                        // Time preset button
                        Button(action: { showingTimePresets.toggle() }) {
                            Image(systemName: "timer")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .popover(isPresented: $showingTimePresets) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Time Presets").font(.headline).padding(.bottom, 5)
                                
                                ForEach([15, 30, 45, 60, 90, 120], id: \.self) { totalMinutes in
                                    Button(action: {
                                        hours = totalMinutes / 60
                                        minutes = totalMinutes % 60
                                        showingTimePresets = false
                                    }) {
                                        Text("\(totalMinutes / 60 > 0 ? "\(totalMinutes / 60)h " : "")\(totalMinutes % 60 > 0 ? "\(totalMinutes % 60)m" : "")")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.vertical, 5)
                                }
                            }
                            .padding()
                            .frame(width: 150)
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 4) {
                        // Add/Update button (only shown when not recording)
                        if !isRecording {
                            Button(action: editingTaskIndex != nil ? updateTask : addTask) {
                                Image(systemName: editingTaskIndex != nil ? "arrow.counterclockwise" : "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 18))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(taskName.isEmpty || (hours == 0 && minutes == 0))
                        }
                        
                        // Cancel edit button (only shown when editing and not recording)
                        if editingTaskIndex != nil && !isRecording {
                            Button(action: cancelEdit) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 18))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Recording button
                        Button(action: toggleRecording) {
                            ZStack {
                                Circle()
                                    .fill(isRecording ? Color.red : Color.red.opacity(0.7))
                                    .frame(width: 18, height: 18)
                                
                                if isRecording {
                                    // Show stop square when recording
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.white)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .opacity(isRecording ? 0.5 + 0.5 * sin(Date().timeIntervalSince1970 * 2) : 1)
                            .animation(.default, value: isRecording)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal, 10)
            }
            .padding(.top, 10)
            .animation(.easeInOut(duration: 0.2), value: showingNotesField)
            
            Divider()
                .padding(.top, 10)
            
            // Tasks section
            VStack(alignment: .leading) {
                Text("Tasks")
                    .font(.headline)
                    .foregroundColor(Color.primary)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                TextField("Search tasks...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if searchText.isEmpty {
                    List {
                        ForEach(groupedTasks.keys.sorted(), id: \.self) { timeOfDay in
                            Section(header: Text(timeOfDay).foregroundColor(Color.primary)) {
                                ForEach(groupedTasks[timeOfDay]!, id: \.id) { task in
                                    TaskRow(task: task)
                                        .contextMenu {
                                            Button(action: { startEditing(task) }) {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            
                                            Button(action: { deleteTask(task) }) {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                } else {
                    List {
                        ForEach(tasks.filter { $0.name.lowercased().contains(searchText.lowercased()) }, id: \.id) { task in
                            TaskRow(task: task)
                                .contextMenu {
                                    Button(action: { startEditing(task) }) {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(action: { deleteTask(task) }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(maxHeight: .infinity)
            
            // Summary section
            VStack(spacing: 4) {
                Divider()
                
                HStack {
                    Text("Summary")
                        .font(.headline)
                        .foregroundColor(Color.primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                HStack {
                    Text("Total Time:")
                        .foregroundColor(Color.primary)
                    Spacer()
                    Text("\(totalHours)h \(totalMinutes)m")
                        .foregroundColor(.blue)
                        .font(.system(.body, design: .monospaced))
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 300, height: 400)
        .onAppear {
            loadTasks()
            loadRecentTaskNames()
            
            // Listen for status bar menu actions
            NotificationCenter.default.addObserver(
                forName: .startRecording,
                object: nil,
                queue: .main
            ) { _ in
                if !isRecording {
                    startTimer()
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: .stopRecording,
                object: nil,
                queue: .main
            ) { _ in
                if isRecording {
                    // Stop the timer
                    stopTimer()
                    
                    // Calculate hours and minutes from seconds
                    recordedHours = elapsedSeconds / 3600
                    recordedMinutes = (elapsedSeconds % 3600) / 60
                    
                    // Always show the prompt if we recorded time
                    if elapsedSeconds > 1 {
                        // Small delay to ensure UI is ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingNamePrompt = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingNamePrompt) {
            TaskNamePromptView(
                taskName: $taskName,
                notes: $taskNotes,
                hours: recordedHours,
                minutes: recordedMinutes,
                onSave: {
                    addRecordedTask()
                    showingNamePrompt = false
                },
                onCancel: {
                    showingNamePrompt = false
                }
            )
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && shouldShowPrompt {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingNamePrompt = true
                    shouldShowPrompt = false
                }
            }
        }
    }
    
    // Animation effect for recording button
    private var pulsingOpacity: Double {
        return isRecording ? 0.3 + 0.7 * sin(Date().timeIntervalSince1970 * 2) : 0
    }
    
    private func toggleRecording() {
        if isRecording {
            // Stop recording
            stopTimer()
            
            // Calculate hours and minutes from seconds
            recordedHours = elapsedSeconds / 3600
            recordedMinutes = (elapsedSeconds % 3600) / 60
            
            // Show task name prompt
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showingNamePrompt = true
            }
        } else {
            // Start recording
            startTimer()
        }
    }
    
    private func startTimer() {
        timerStartTime = Date()
        elapsedSeconds = 0
        isRecording = true
        
        // Create and start the timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = timerStartTime {
                elapsedSeconds = Int(Date().timeIntervalSince(startTime))
            }
        }
        
        // Notify that recording started (to update status bar icon)
        NotificationCenter.default.post(name: .recordingStarted, object: nil)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRecording = false
        
        // Notify that recording stopped (to update status bar icon)
        NotificationCenter.default.post(name: .recordingStopped, object: nil)
    }
    
    private func addRecordedTask() {
        if !taskName.isEmpty {
            let newTask = TaskItem(
                id: UUID().uuidString,
                name: taskName,
                hours: recordedHours,
                minutes: recordedMinutes,
                createdAt: Date(),
                notes: taskNotes
            )
            tasks.append(newTask)
            saveTasks()
            
            // Reset input fields
            taskName = ""
            taskNotes = ""
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var totalHours: Int {
        let totalMinutes = tasks.reduce(0) { $0 + ($1.hours * 60) + $1.minutes }
        return totalMinutes / 60
    }
    
    private var totalMinutes: Int {
        let totalMinutes = tasks.reduce(0) { $0 + ($1.hours * 60) + $1.minutes }
        return totalMinutes % 60
    }
    
    // Day navigation functions
    private func nextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        loadTasks()
    }
    
    private func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        loadTasks()
    }
    
    // Task storage and retrieval using UserDefaults
    private func loadTasks() {
        let dateString = dateFormatter.string(from: selectedDate)
        
        if let savedData = UserDefaults.standard.data(forKey: "tasks_\(dateString)"),
           let decodedTasks = try? JSONDecoder().decode([TaskItem].self, from: savedData) {
            tasks = decodedTasks
        } else {
            tasks = []
        }
    }
    
    private func saveTasks() {
        let dateString = dateFormatter.string(from: selectedDate)
        if let encodedData = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encodedData, forKey: "tasks_\(dateString)")
        }
    }
    
    // Task editing functions
    private func startEditing(_ task: TaskItem) {
        taskName = task.name
        hours = task.hours
        minutes = task.minutes
        taskNotes = task.notes
        editingTaskIndex = tasks.firstIndex(where: { $0.id == task.id })
    }
    
    private func updateTask() {
        if let index = editingTaskIndex {
            tasks[index] = TaskItem(
                id: tasks[index].id,
                name: taskName,
                hours: hours,
                minutes: minutes,
                createdAt: Date(),
                notes: taskNotes
            )
            saveTasks()
            cancelEdit()
        }
    }
    
    private func cancelEdit() {
        taskName = ""
        hours = 0
        minutes = 0
        taskNotes = ""
        editingTaskIndex = nil
    }
    
    private func addTask() {
        let newTask = TaskItem(
            id: UUID().uuidString,
            name: taskName,
            hours: hours,
            minutes: minutes,
            createdAt: Date(),
            notes: taskNotes
        )
        tasks.append(newTask)
        saveTasks()
        
        // Reset input fields
        taskName = ""
        hours = 0
        minutes = 0
        taskNotes = ""
        showingNotesField = false
        
        // Update recent task names
        if !taskName.isEmpty && !recentTaskNames.contains(taskName) {
            recentTaskNames.insert(taskName, at: 0)
            if recentTaskNames.count > 10 { recentTaskNames.removeLast() }
            UserDefaults.standard.set(recentTaskNames, forKey: "recentTaskNames")
        }
    }
    
    private func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    // Load recent task names from UserDefaults in onAppear
    private func loadRecentTaskNames() {
        recentTaskNames = UserDefaults.standard.stringArray(forKey: "recentTaskNames") ?? []
    }
    
    // Add this computed property
    private var groupedTasks: [String: [TaskItem]] {
        Dictionary(grouping: tasks) { task in
            let hour = Calendar.current.component(.hour, from: task.createdAt)
            if hour < 12 {
                return "Morning"
            } else if hour < 17 {
                return "Afternoon"
            } else {
                return "Evening"
            }
        }
    }
}

// Task name prompt view
struct TaskNamePromptView: View {
    @Binding var taskName: String
    @Binding var notes: String
    let hours: Int
    let minutes: Int
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What were you working on?")
                .font(.headline)
            
            Text("Time tracked: \(hours)h \(minutes)m")
                .foregroundColor(.blue)
            
            TextField("Task name", text: $taskName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
            
            TextField("Notes (optional)", text: $notes)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
                .frame(height: 60)
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    onCancel()
                }
                
                Button("Save") {
                    onSave()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(taskName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

// Simple model for task data
struct TaskItem: Codable, Identifiable {
    var id: String
    var name: String
    var hours: Int
    var minutes: Int
    var createdAt: Date
    var notes: String = ""
}

// Custom time input with stepper
struct TimeStepperView: View {
    @Binding var value: Int
    var label: String
    var range: ClosedRange<Int>
    var isEnabled: Bool = true
    
    var body: some View {
        HStack(spacing: 0) {
            // Input field
            if isEnabled {
                TextField("", value: $value, formatter: NumberFormatter())
                    .textFieldStyle(PlainTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .frame(width: 25)
                    .onSubmit {
                        validateRange()
                    }
                    .onChange(of: value) { _, _ in
                        validateRange()
                    }
            } else {
                // Just show the number when disabled
                Text("\(value)")
                    .multilineTextAlignment(.center)
                    .frame(width: 25)
                    .foregroundColor(.blue)
            }
            
            // Label (h or m)
            Text(label)
                .font(.system(.body, design: .monospaced))
            
            // Up/down buttons (only when enabled)
            if isEnabled {
                VStack(spacing: 0) {
                    Button(action: increment) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 8))
                            .padding(2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: decrement) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                            .padding(2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(width: 16)
            }
        }
        .padding(4)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(4)
    }
    
    private func validateRange() {
        if value < range.lowerBound {
            value = range.lowerBound
        } else if value > range.upperBound {
            value = range.upperBound
        }
    }
    
    private func increment() {
        if value < range.upperBound {
            value += 1
        } else {
            value = range.lowerBound // Loop back to 0 if at max
        }
    }
    
    private func decrement() {
        if value > range.lowerBound {
            value -= 1
        } else {
            value = range.upperBound // Loop to max if at 0
        }
    }
}

struct TaskRow: View {
    var task: TaskItem
    @State private var showingNotes = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text(timeFormatter.string(from: task.createdAt))
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                }
                
                Spacer()
                
                Text("\(task.hours)h \(task.minutes)m")
                    .foregroundColor(.blue)
                    .font(.system(.body, design: .monospaced))
                
                // Add indicator if there are notes
                if !task.notes.isEmpty {
                    Button(action: { showingNotes.toggle() }) {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Show notes when expanded
            if showingNotes && !task.notes.isEmpty {
                Text(task.notes)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}
