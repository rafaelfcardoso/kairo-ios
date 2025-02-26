import SwiftUI

struct FocusSessionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskViewModel: TaskViewModel
    @StateObject private var viewModel = FocusSessionViewModel()
    @State private var showingTaskPicker = false
    
    var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : Color(hex: "7E7E7E")
    }
    
    var buttonBackgroundColor: Color {
        viewModel.isActive ? .red : .blue
    }
    
    var body: some View {
        fullScreenView
            .transition(.move(edge: .bottom))
    }
    
    private var fullScreenView: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Chevron down button
                    Button {
                        if viewModel.isActive {
                            viewModel.minimizeSession()
                            dismiss()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .foregroundColor(secondaryTextColor)
                            .frame(width: 44, height: 44)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    
                    // Motivational Phrase
                    Text("Vamos focar!")
                        .font(.title2.weight(.medium))
                        .foregroundColor(secondaryTextColor)
                    
                    // Timer Display
                    VStack(spacing: 16) {
                        Text(formattedTime)
                            .font(.system(size: 72, weight: .medium, design: .default))
                            .foregroundColor(textColor)
                            .monospacedDigit()
                        
                        // Timer Controls
                        if !viewModel.isActive {
                            HStack(spacing: 24) {
                                Button {
                                    if viewModel.timerDuration > 5 * 60 {
                                        viewModel.timerDuration -= 5 * 60
                                        viewModel.remainingTime = viewModel.timerDuration
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(secondaryTextColor)
                                }
                                
                                Text("Duração")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                                
                                Button {
                                    if viewModel.timerDuration < 60 * 60 {
                                        viewModel.timerDuration += 5 * 60
                                        viewModel.remainingTime = viewModel.timerDuration
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(secondaryTextColor)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 24)
                    
                    // Task Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tarefa")
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        Button {
                            showingTaskPicker = true
                        } label: {
                            HStack {
                                if let task = viewModel.selectedTask {
                                    Text(task.title)
                                        .foregroundColor(textColor)
                                } else {
                                    Text("Selecione uma tarefa")
                                        .foregroundColor(secondaryTextColor)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(secondaryTextColor)
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isActive)
                    }
                    
                    // Distraction Blocking
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Configurações")
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: "moon.fill")
                                        .foregroundColor(.blue)
                                    Text("Modo Foco")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(textColor)
                                }
                                
                                Text("Bloqueia notificações durante a sessão")
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.blockDistractions)
                                .labelsHidden()
                                .tint(.blue)
                                .disabled(viewModel.isActive)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Time Worked Today Insight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Insights")
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tempo focado hoje")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundColor(.green)
                                    Text(formattedTimeWorkedToday)
                                        .font(.title3.weight(.medium))
                                        .foregroundColor(textColor)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Spacer(minLength: 32)
                    
                    // Start/Stop Button
                    if !viewModel.isActive {
                        Button {
                            viewModel.startSession()
                        } label: {
                            Text("Começar")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(buttonBackgroundColor)
                                .cornerRadius(12)
                        }
                        .disabled(viewModel.selectedTask == nil)
                        .opacity(viewModel.selectedTask == nil ? 0.6 : 1)
                        .padding(.bottom, 16)
                    } else {
                        Button {
                            viewModel.showingForfeitAlert = true
                        } label: {
                            Text("Desistir da sessão")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .padding(.bottom, 16)
                    }
                }
                .padding(.horizontal)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 0)
            }
        }
        .sheet(isPresented: $showingTaskPicker) {
            TaskPickerView(selectedTask: $viewModel.selectedTask, tasks: taskViewModel.tasks)
        }
        .alert("Deseja desistir da sessão?", isPresented: $viewModel.showingForfeitAlert) {
            Button("Continuar sessão", role: .cancel) { }
            Button("Desistir", role: .destructive) {
                viewModel.forfeitSession()
            }
        } message: {
            Text("Se você parar agora, perderá o progresso desta sessão de foco.")
        }
    }
    
    private var formattedTime: String {
        let minutes = Int(viewModel.remainingTime) / 60
        let seconds = Int(viewModel.remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var formattedTimeWorkedToday: String {
        let hours = Int(viewModel.timeWorkedToday / 3600)
        return "\(hours) hora\(hours == 1 ? "" : "s")"
    }
}

// Task Picker View
struct TaskPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedTask: TodoTask?
    let tasks: [TodoTask]
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : Color(hex: "7E7E7E")
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tasks) { task in
                    Button {
                        selectedTask = task
                        dismiss()
                    } label: {
                        HStack {
                            Text(task.title)
                                .foregroundColor(textColor)
                            Spacer()
                            if selectedTask?.id == task.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Escolher Tarefa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FocusSessionView_Previews: PreviewProvider {
    static var previews: some View {
        FocusSessionView()
            .environmentObject(TaskViewModel())
    }
}
