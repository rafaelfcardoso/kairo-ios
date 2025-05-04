import SwiftUI

struct FocusSessionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var viewModel: FocusSessionViewModel
    @State private var showingTaskPicker = false
    @Environment(\.dismiss) private var dismiss
    
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
        if viewModel.isBreakActive {
            return .green
        } else {
            return viewModel.isActive ? .red : .blue
        }
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with Chevron and Title - Moved outside ScrollView
                ZStack {
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if viewModel.isActive || viewModel.isBreakActive {
                                    viewModel.minimizeSession()
                                } else {
                                    viewModel.dismissSession()
                                }
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.title3)
                                .foregroundColor(secondaryTextColor)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                    }
                    
                    Text(viewModel.isBreakActive ? "Pausa" : "Foco")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)
                .padding(.horizontal)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Motivational Phrase - Changes based on session type
                        Text(viewModel.isBreakActive 
                             ? "Aproveite para se alongar, beber água ou simplesmente relaxar."
                             : "Vamos focar!")
                            .font(.title2.weight(.medium))
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 16)
                        
                        // Timer Display and Controls
                        VStack(spacing: 16) {
                            Text(viewModel.isBreakActive ? formattedBreakTime : formattedTime)
                                .font(.system(size: 72, weight: .medium, design: .default))
                                .foregroundColor(textColor)
                                .monospacedDigit()
                            
                            // Timer Controls (visible during setup and active sessions, but not during breaks)
                            if !viewModel.isBreakActive {
                                HStack(spacing: 24) {
                                    Button {
                                        if viewModel.timerDuration > 5 * 60 && !viewModel.isActive {
                                            viewModel.timerDuration -= 5 * 60
                                            viewModel.remainingTime = viewModel.timerDuration
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(viewModel.isActive ? Color.gray.opacity(0.5) : secondaryTextColor)
                                    }
                                    .disabled(viewModel.isActive)
                                    
                                    Text("Duração")
                                        .font(.subheadline)
                                        .foregroundColor(secondaryTextColor)
                                    
                                    Button {
                                        if viewModel.timerDuration < 60 * 60 {
                                            viewModel.timerDuration += 5 * 60
                                            if viewModel.isActive {
                                                viewModel.remainingTime += 5 * 60
                                            } else {
                                                viewModel.remainingTime = viewModel.timerDuration
                                            }
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
                        
                        // Task Selection (visible during setup) or Current Task (visible during active session)
                        if !viewModel.isActive && !viewModel.isBreakActive {
                            // Task Selection for setup
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
                                            Text("Nenhuma tarefa especificada")
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
                            }
                        } else if viewModel.isActive && !viewModel.isBreakActive {
                            // Current Task display during active session
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tarefa atual")
                                    .font(.headline)
                                    .foregroundColor(textColor)
                                
                                HStack {
                                    if let task = viewModel.selectedTask {
                                        Text(task.title)
                                            .foregroundColor(textColor)
                                            .font(.subheadline.weight(.medium))
                                    } else {
                                        Text("Nenhuma tarefa especificada")
                                            .foregroundColor(secondaryTextColor)
                                            .font(.subheadline.weight(.medium))
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Conditional content based on session state
                        if !viewModel.isActive && !viewModel.isBreakActive {
                            // Distraction Blocking (only shown before session starts)
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
                                        
                                        Text("Bloqueia aplicativos que causam distração")
                                            .font(.caption)
                                            .foregroundColor(secondaryTextColor)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $viewModel.blockDistractions)
                                        .labelsHidden()
                                        .tint(.blue)
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(12)
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            // Insights during active session or break
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Insights")
                                    .font(.headline)
                                    .foregroundColor(textColor)
                                
                                if viewModel.isLoadingInsights {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .padding()
                                        Spacer()
                                    }
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(12)
                                } else {
                                    // Time Worked Today
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
                                    
                                    // 7-Day Daily Average
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Média diária (7 dias)")
                                                .font(.subheadline)
                                                .foregroundColor(secondaryTextColor)
                                            
                                            HStack(spacing: 8) {
                                                Image(systemName: "calendar.badge.clock")
                                                    .foregroundColor(.blue)
                                                Text(formattedSevenDayAverage)
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
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isActive)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isBreakActive)
                
                Spacer()
                
                // Bottom buttons - different based on state
                VStack {
                    if viewModel.isBreakActive {
                        // Break session button
                        Button {
                            viewModel.skipBreak()
                        } label: {
                            Text("Pular pausa")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                    } else if !viewModel.isActive {
                        // Start focus session button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.startSession()
                            }
                        } label: {
                            Text("Começar")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(buttonBackgroundColor)
                                .cornerRadius(12)
                        }
                    } else {
                        // Forfeit active session button
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
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .background(backgroundColor)
                .transition(.move(edge: .bottom))
            }
        }
        .sheet(isPresented: $showingTaskPicker) {
            TaskPickerView(selectedTask: $viewModel.selectedTask, tasks: taskViewModel.tasks)
        }
        .alert("Deseja desistir da sessão?", isPresented: $viewModel.showingForfeitAlert) {
            Button("Continuar sessão", role: .cancel) { }
            Button("Desistir", role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.forfeitSession()
                }
            }
        } message: {
            Text("Se você parar agora, perderá o progresso desta sessão de foco.")
        }
        .alert("Sessão Concluída!", isPresented: $viewModel.showingSessionCompleteAlert) {
            Button("Fazer uma pausa (\(viewModel.completedSessionsCount % 4 == 0 ? "15" : "5") min)") {
                viewModel.startBreak()
            }
            Button("Pular pausa", role: .cancel) {
                viewModel.skipBreakAndReset()
            }
            Button("Descartar última sessão", role: .destructive) {
                viewModel.forfeitLastSession()
            }
        } message: {
            Text("Parabéns! Você completou uma sessão de foco de \(Int(viewModel.timerDuration / 60)) minutos.")
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
    
    private var formattedSevenDayAverage: String {
        let minutes = Int(viewModel.sevenDayDailyAverage / 60)
        return "\(minutes) min"
    }
    
    private var formattedBreakTime: String {
        let minutes = Int(viewModel.breakRemainingTime) / 60
        let seconds = Int(viewModel.breakRemainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
            .environmentObject(FocusSessionViewModel())
    }
} 