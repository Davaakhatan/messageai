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
    @State private var showingProjectNameInput = false
    @State private var showingProjectSelection = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 24) {
                        // Modern Loading Animation
                        ZStack {
                            Circle()
                                .stroke(Color.blue.opacity(0.2), lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(isLoading ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Analyzing Project Status")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("AI is analyzing your team's conversations and project data...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let status = projectStatus {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Modern Header
                            ModernProjectHeader(
                                projectName: status.projectName,
                                status: status.status,
                                progress: status.progress,
                                lastUpdated: status.lastUpdated,
                                onEditProject: {
                                    showingProjectNameInput = true
                                }
                            )
                            
                            // Team Members Card
                            ModernTeamMembersCard(members: status.teamMembers)
                            
                            // Blockers Card
                            if !status.blockers.isEmpty {
                                ModernBlockersCard(blockers: status.blockers)
                            }
                            
                            // Next Steps Card
                            if !status.nextSteps.isEmpty {
                                ModernNextStepsCard(steps: status.nextSteps)
                            }
                            
                            // Dependencies Card
                            if !status.dependencies.isEmpty {
                                ModernDependenciesCard(dependencies: status.dependencies)
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                } else if let error = errorMessage {
                    ModernErrorView(
                        error: error,
                        onRetry: generateProjectStatus
                    )
                } else {
                    ModernProjectInputView(
                        projectName: $inputProjectName,
                        onAnalyze: generateProjectStatus
                    )
                }
            }
            .navigationTitle("Project Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { 
                        showingProjectSelection = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Projects")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showingProjectNameInput) {
            ProjectNameInputSheet(
                currentName: projectStatus?.projectName ?? inputProjectName,
                onSave: { newName in
                    inputProjectName = newName
                    generateProjectStatus()
                }
            )
        }
        .sheet(isPresented: $showingProjectSelection) {
            ProjectSelectionView(
                currentProjectName: projectStatus?.projectName ?? inputProjectName,
                onProjectSelected: { selectedProject in
                    inputProjectName = selectedProject
                    generateProjectStatus()
                }
            )
        }
        .onAppear {
            inputProjectName = projectName.isEmpty ? "Team Frontend" : projectName
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

// MARK: - Modern Component Views

struct ModernProjectHeader: View {
    let projectName: String
    let status: ProjectStatusType
    let progress: Double
    let lastUpdated: Date
    let onEditProject: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Project Name and Edit Button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(projectName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Last updated: \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onEditProject) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            
            // Status and Progress Card
            VStack(spacing: 16) {
                HStack {
                    Text("Project Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    ModernStatusBadge(status: status)
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    ModernProgressBar(progress: progress, status: status)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            )
        }
    }
}

struct ModernStatusBadge: View {
    let status: ProjectStatusType
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
        .foregroundColor(statusColor)
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

struct ModernProgressBar: View {
    let progress: Double
    let status: ProjectStatusType
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [progressColor, progressColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.easeInOut(duration: 0.8), value: progress)
            }
        }
        .frame(height: 8)
    }
    
    private var progressColor: Color {
        switch status {
        case .onTrack: return .green
        case .atRisk: return .yellow
        case .delayed: return .red
        case .completed: return .blue
        case .onHold: return .gray
        }
    }
}

struct ModernTeamMembersCard: View {
    let members: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text("Team Members")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(members.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(members, id: \.self) { member in
                    ModernTeamMemberRow(member: member)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
}

struct ModernTeamMemberRow: View {
    let member: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Text(member.prefix(1).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(member)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

struct ModernBlockersCard: View {
    let blockers: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                
                Text("Current Blockers")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Spacer()
                
                Text("\(blockers.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.1))
                    )
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 12) {
                ForEach(blockers, id: \.self) { blocker in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .padding(.top, 2)
                        
                        Text(blocker)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
}

struct ModernNextStepsCard: View {
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                Text("Next Steps")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("\(steps.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.1))
                    )
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                ForEach(steps, id: \.self) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                            .padding(.top, 2)
                        
                        Text(step)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
}

struct ModernDependenciesCard: View {
    let dependencies: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                Text("Dependencies")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("\(dependencies.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.1))
                    )
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 12) {
                ForEach(dependencies, id: \.self) { dependency in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "link")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                            .padding(.top, 2)
                        
                        Text(dependency)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
}

struct ModernErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 12) {
                Text("Analysis Failed")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ModernProjectInputView: View {
    @Binding var projectName: String
    let onAnalyze: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 8) {
                    Text("Project Status Analysis")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Enter your project name to get AI-powered insights")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Name")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    TextField("Enter project name", text: $projectName)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(projectName.isEmpty ? Color.clear : Color.blue, lineWidth: 1)
                        )
                }
                
                Button(action: onAnalyze) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                        Text("Analyze Project Status")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(projectName.isEmpty)
                .opacity(projectName.isEmpty ? 0.6 : 1.0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
}

struct ProjectNameInputSheet: View {
    let currentName: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Edit Project Name")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Name")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    TextField("Enter project name", text: $newName)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(newName)
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .disabled(newName.isEmpty)
                }
            }
        }
        .onAppear {
            newName = currentName
        }
    }
}

struct ProjectSelectionView: View {
    let currentProjectName: String
    let onProjectSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var newProjectName = ""
    @State private var showingNewProjectInput = false
    
    // Sample projects - in a real app, this would come from your data source
    private let sampleProjects = [
        "Team Frontend",
        "Mobile App Development", 
        "Backend API",
        "Database Migration",
        "UI/UX Redesign",
        "Testing & QA",
        "DevOps Pipeline",
        "Security Audit"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Select Project")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Choose a project to analyze or create a new one")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Current Project
                        if !currentProjectName.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Current Project")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.green)
                                    
                                    Text(currentProjectName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("Active")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.green.opacity(0.1))
                                        )
                                        .foregroundColor(.green)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        // Available Projects
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Available Projects")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(sampleProjects, id: \.self) { project in
                                    ProjectSelectionCard(
                                        projectName: project,
                                        isCurrent: project == currentProjectName,
                                        onSelect: {
                                            onProjectSelected(project)
                                            dismiss()
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Create New Project Button
                        Button(action: {
                            showingNewProjectInput = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                
                                Text("Create New Project")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showingNewProjectInput) {
            NewProjectInputSheet(
                onProjectCreated: { newProject in
                    onProjectSelected(newProject)
                    dismiss()
                }
            )
        }
    }
}

struct ProjectSelectionCard: View {
    let projectName: String
    let isCurrent: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isCurrent ? [.green, .blue] : [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: isCurrent ? "checkmark" : "folder.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(projectName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(isCurrent ? "Currently analyzing" : "Click to analyze")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NewProjectInputSheet: View {
    let onProjectCreated: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var projectName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Create New Project")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Name")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    TextField("Enter project name", text: $projectName)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        onProjectCreated(projectName)
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .disabled(projectName.isEmpty)
                }
            }
        }
    }
}

struct ProjectStatusView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectStatusView(chatId: "preview", projectName: "Sample Project")
            .environmentObject(AIService())
    }
}

