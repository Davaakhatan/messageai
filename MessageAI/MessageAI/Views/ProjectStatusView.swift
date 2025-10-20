import SwiftUI

struct ProjectStatusView: View {
    let chatId: String
    let projectName: String
    @EnvironmentObject var aiService: AIService
    @Environment(\.dismiss) private var dismiss
    @State private var projectStatus: ProjectStatus?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var inputProjectName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing project status...")
                            .font(.headline)
                        Text("This may take a few moments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let status = projectStatus {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Project Status")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Last updated: \(status.lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Project Overview
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(status.projectName)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    StatusBadge(status: status.status)
                                }
                                
                                // Progress Bar
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Progress")
                                            .font(.headline)
                                        Spacer()
                                        Text("\(Int(status.progress * 100))%")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    ProgressView(value: status.progress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                                        .scaleEffect(x: 1, y: 2, anchor: .center)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Team Members
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Team Members")
                                    .font(.headline)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(status.teamMembers, id: \.self) { member in
                                        HStack {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 8, height: 8)
                                            Text(member)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Blockers
                            if !status.blockers.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Blockers")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    
                                    ForEach(status.blockers, id: \.self) { blocker in
                                        HStack(alignment: .top) {
                                            Text("⚠️")
                                            Text(blocker)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Next Steps
                            if !status.nextSteps.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Next Steps")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    
                                    ForEach(status.nextSteps, id: \.self) { step in
                                        HStack(alignment: .top) {
                                            Text("✅")
                                            Text(step)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Dependencies
                            if !status.dependencies.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Dependencies")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                    
                                    ForEach(status.dependencies, id: \.self) { dependency in
                                        HStack(alignment: .top) {
                                            Text("🔗")
                                            Text(dependency)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text("Error")
                            .font(.headline)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            generateProjectStatus()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Project Status Analysis")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            TextField("Enter project name", text: $inputProjectName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.default)
                                .autocapitalization(.words)
                            
                            Text("Enter the name of the project to analyze")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Analyze Project Status") {
                            generateProjectStatus()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(inputProjectName.isEmpty)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .navigationTitle("Project Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            inputProjectName = projectName
            if let existingStatus = aiService.projectStatuses[chatId] {
                projectStatus = existingStatus
            }
        }
    }
    
    private func generateProjectStatus() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let status = try await aiService.generateProjectStatus(for: chatId, projectName: inputProjectName)
                await MainActor.run {
                    self.projectStatus = status
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private var progressColor: Color {
        guard let status = projectStatus else { return .blue }
        
        switch status.status {
        case .onTrack: return .green
        case .atRisk: return .yellow
        case .delayed: return .red
        case .completed: return .blue
        case .onHold: return .gray
        }
    }
}

struct StatusBadge: View {
    let status: ProjectStatusType
    
    var body: some View {
        Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch status {
        case .onTrack: return .green
        case .atRisk: return .yellow
        case .delayed: return .red
        case .completed: return .blue
        case .onHold: return .gray
        }
    }
}

struct ProjectStatusView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectStatusView(chatId: "preview", projectName: "Sample Project")
            .environmentObject(AIService())
    }
}
