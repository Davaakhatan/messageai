import SwiftUI

struct SmartSearchView: View {
    @StateObject private var searchService = SmartSearchService()
    @EnvironmentObject var messageService: MessageService
    @EnvironmentObject var authService: AuthService
    @State private var showingFilters = false
    @State private var selectedResult: SearchResult?
    
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
                
                VStack(spacing: 0) {
                    // Modern Search Bar
                    ModernSearchBarView(
                        searchText: $searchService.searchQuery,
                        isSearching: $searchService.isSearching
                    )
                    
                    // Filter and Results Count
                    ModernSearchControls(
                        showingFilters: $showingFilters,
                        resultCount: searchService.searchResults.count,
                        isSearching: searchService.isSearching
                    )
                    
                    // Search Content
                    if searchService.isSearching {
                        ModernSearchLoadingView()
                    } else if searchService.searchResults.isEmpty && !searchService.searchQuery.isEmpty {
                        ModernNoResultsView()
                    } else if searchService.searchResults.isEmpty {
                        ModernSearchWelcomeView(
                            onSuggestionTap: { suggestion in
                                searchService.searchQuery = suggestion
                            }
                        )
                    } else {
                        ModernSearchResultsList(
                            results: searchService.searchResults,
                            onResultTap: { result in
                                selectedResult = result
                            }
                        )
                    }
                }
            }
            .navigationTitle("Smart Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss action handled by parent
                    }
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showingFilters) {
                ModernSearchFiltersView(filters: $searchService.searchFilters)
            }
            .sheet(item: $selectedResult) { result in
                ModernSearchResultDetailView(result: result)
            }
        }
    }
}

// MARK: - Modern Component Views

struct ModernSearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
                TextField("Search messages, users, chats...", text: $searchText)
                    .font(.body)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
        }
        .padding(.top, 10)
    }
}

struct ModernSearchControls: View {
    @Binding var showingFilters: Bool
    let resultCount: Int
    let isSearching: Bool
    
    var body: some View {
        HStack {
            Button(action: { showingFilters = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 16))
                    Text("Filters")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            
            Spacer()
            
            if !isSearching && resultCount > 0 {
                Text("\(resultCount) result\(resultCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

struct ModernSearchLoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
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
                    .rotationEffect(.degrees(360))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: true)
            }
            
            VStack(spacing: 8) {
                Text("Searching...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("AI is analyzing your content to find the most relevant results")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ModernNoResultsView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 12) {
                Text("No Results Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Try different keywords or adjust your search filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ModernSearchWelcomeView: View {
    let onSuggestionTap: (String) -> Void
    
    private let suggestions = [
        ("message.fill", "Search messages", "Find specific conversations"),
        ("person.fill", "Find users", "Search team members"),
        ("bubble.left.and.bubble.right.fill", "Browse chats", "Explore conversations"),
        ("checkmark.circle.fill", "Action items", "Track tasks and assignments"),
        ("doc.text.fill", "Decisions & meetings", "Review important decisions"),
        ("calendar.fill", "Schedule items", "Find calendar events")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
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
                        
                        Image(systemName: "magnifyingglass.circle.fill")
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
                        Text("Smart Search")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Search through messages, users, chats, and more with AI-powered intelligence")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Search Suggestions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Searches")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 4)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                            ModernSearchSuggestionCard(
                                icon: suggestion.0,
                                title: suggestion.1,
                                subtitle: suggestion.2,
                                onTap: {
                                    onSuggestionTap(suggestion.1)
                                }
                            )
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

struct ModernSearchSuggestionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
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

struct ModernSearchResultsList: View {
    let results: [SearchResult]
    let onResultTap: (SearchResult) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedResults, id: \.key) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        // Section Header
                        HStack {
                            Text(section.key)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(section.value.count)")
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
                        .padding(.horizontal, 4)
                        
                        // Section Results
                        LazyVStack(spacing: 8) {
                            ForEach(section.value) { result in
                                ModernSearchResultCard(result: result) {
                                    onResultTap(result)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    private var groupedResults: [(key: String, value: [SearchResult])] {
        let grouped = Dictionary(grouping: results) { result in
            switch result.type {
            case .message: return "Messages"
            case .user: return "Users"
            case .chat: return "Chats"
            case .actionItem: return "Action Items"
            case .decision: return "Decisions"
            case .meeting: return "Meetings"
            }
        }
        return grouped.sorted { $0.key < $1.key }
    }
}

struct ModernSearchResultCard: View {
    let result: SearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(colorForType(result.type).opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: iconForType(result.type))
                            .font(.system(size: 18))
                            .foregroundColor(colorForType(result.type))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(result.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text(timeAgoString(from: result.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(result.content)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
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
    
    private func iconForType(_ type: SearchResult.SearchResultType) -> String {
        switch type {
        case .message: return "message.fill"
        case .user: return "person.circle.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .actionItem: return "checkmark.circle.fill"
        case .decision: return "doc.text.fill"
        case .meeting: return "calendar"
        }
    }
    
    private func colorForType(_ type: SearchResult.SearchResultType) -> Color {
        switch type {
        case .message: return .blue
        case .user: return .green
        case .chat: return .purple
        case .actionItem: return .orange
        case .decision: return .red
        case .meeting: return .indigo
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ModernSearchFiltersView: View {
    @Binding var filters: SearchFilters
    @Environment(\.dismiss) private var dismiss
    
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
                        // Search In Section
                        ModernFilterSection(
                            title: "Search In",
                            icon: "magnifyingglass"
                        ) {
                            VStack(spacing: 16) {
                                ModernFilterToggle(
                                    title: "Messages",
                                    subtitle: "Search through conversation content",
                                    isOn: $filters.searchInMessages,
                                    color: .blue
                                )
                                
                                ModernFilterToggle(
                                    title: "Users",
                                    subtitle: "Find team members and contacts",
                                    isOn: $filters.searchInUsers,
                                    color: .green
                                )
                                
                                ModernFilterToggle(
                                    title: "Chats",
                                    subtitle: "Browse conversation groups",
                                    isOn: $filters.searchInChats,
                                    color: .purple
                                )
                                
                                ModernFilterToggle(
                                    title: "Action Items",
                                    subtitle: "Track tasks and assignments",
                                    isOn: $filters.searchInActionItems,
                                    color: .orange
                                )
                                
                                ModernFilterToggle(
                                    title: "Decisions",
                                    subtitle: "Review important decisions",
                                    isOn: $filters.searchInDecisions,
                                    color: .red
                                )
                                
                                ModernFilterToggle(
                                    title: "Meetings",
                                    subtitle: "Find meeting summaries",
                                    isOn: $filters.searchInMeetings,
                                    color: .indigo
                                )
                            }
                        }
                        
                        // Date Range Section
                        ModernFilterSection(
                            title: "Date Range",
                            icon: "calendar"
                        ) {
                            VStack(spacing: 12) {
                                ForEach([
                                    ("All Time", SearchFilters.DateRange?.none),
                                    ("Today", SearchFilters.DateRange?.some(.today)),
                                    ("Yesterday", SearchFilters.DateRange?.some(.yesterday)),
                                    ("This Week", SearchFilters.DateRange?.some(.thisWeek)),
                                    ("This Month", SearchFilters.DateRange?.some(.thisMonth))
                                ], id: \.0) { option in
                                    ModernFilterOption(
                                        title: option.0,
                                        isSelected: filters.dateRange == option.1,
                                        onTap: {
                                            filters.dateRange = option.1
                                        }
                                    )
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        filters = SearchFilters()
                    }
                    .fontWeight(.medium)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct ModernFilterSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
}

struct ModernFilterToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
    }
}

struct ModernFilterOption: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernSearchResultDetailView: View {
    let result: SearchResult
    @Environment(\.dismiss) private var dismiss
    
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
                        // Header Card
                        ModernResultHeaderCard(result: result)
                        
                        // Content Card
                        ModernResultContentCard(result: result)
                        
                        // Metadata Card
                        if !result.metadata.isEmpty {
                            ModernResultMetadataCard(result: result)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Search Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct ModernResultHeaderCard: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(colorForType(result.type).opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: iconForType(result.type))
                        .font(.system(size: 24))
                        .foregroundColor(colorForType(result.type))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(result.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(timeAgoString(from: result.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    private func iconForType(_ type: SearchResult.SearchResultType) -> String {
        switch type {
        case .message: return "message.fill"
        case .user: return "person.circle.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .actionItem: return "checkmark.circle.fill"
        case .decision: return "doc.text.fill"
        case .meeting: return "calendar"
        }
    }
    
    private func colorForType(_ type: SearchResult.SearchResultType) -> Color {
        switch type {
        case .message: return .blue
        case .user: return .green
        case .chat: return .purple
        case .actionItem: return .orange
        case .decision: return .red
        case .meeting: return .indigo
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ModernResultContentCard: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
                Text("Content")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Text(result.content)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
}

struct ModernResultMetadataCard: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
                
                Text("Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(result.metadata.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key.capitalized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(result.metadata[key] ?? "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.05))
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

#Preview {
    SmartSearchView()
        .environmentObject(MessageService())
        .environmentObject(AuthService())
}