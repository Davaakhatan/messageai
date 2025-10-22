import SwiftUI

struct SmartSearchView: View {
    @StateObject private var searchService = SmartSearchService()
    @EnvironmentObject var messageService: MessageService
    @EnvironmentObject var authService: AuthService
    @State private var showingFilters = false
    @State private var selectedResult: SearchResult?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBarView(
                    searchText: $searchService.searchQuery,
                    isSearching: $searchService.isSearching
                )
                
                // Filter Button
                HStack {
                    Button(action: { showingFilters = true }) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Filters")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    if !searchService.searchResults.isEmpty {
                        Text("\(searchService.searchResults.count) results")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Search Results
                if searchService.isSearching {
                    VStack {
                        Spacer()
                        ProgressView("Searching...")
                            .scaleEffect(1.2)
                        Spacer()
                    }
                } else if searchService.searchResults.isEmpty && !searchService.searchQuery.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No results found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try different keywords or adjust your filters")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else if searchService.searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text("Smart Search")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Search through messages, users, chats, and more")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            SearchSuggestionRow(icon: "message", text: "Search messages")
                            SearchSuggestionRow(icon: "person", text: "Find users")
                            SearchSuggestionRow(icon: "bubble.left.and.bubble.right", text: "Browse chats")
                            SearchSuggestionRow(icon: "checkmark.circle", text: "Action items")
                            SearchSuggestionRow(icon: "doc.text", text: "Decisions & meetings")
                        }
                        .padding(.top)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    SearchResultsList(
                        results: searchService.searchResults,
                        onResultTap: { result in
                            selectedResult = result
                        }
                    )
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingFilters) {
                SearchFiltersView(filters: $searchService.searchFilters)
            }
            .sheet(item: $selectedResult) { result in
                SearchResultDetailView(result: result)
            }
        }
    }
}

// MARK: - Search Bar View
struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search messages, users, chats...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Search Suggestion Row
struct SearchSuggestionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - Search Results List
struct SearchResultsList: View {
    let results: [SearchResult]
    let onResultTap: (SearchResult) -> Void
    
    var body: some View {
        List {
            ForEach(groupedResults, id: \.key) { section in
                Section(header: Text(section.key)) {
                    ForEach(section.value) { result in
                        SearchResultRow(result: result)
                            .onTapGesture {
                                onResultTap(result)
                            }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
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

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: iconForType(result.type))
                    .foregroundColor(colorForType(result.type))
                    .frame(width: 20)
                
                Text(result.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(timeAgoString(from: result.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(result.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForType(_ type: SearchResult.SearchResultType) -> String {
        switch type {
        case .message: return "message"
        case .user: return "person.circle"
        case .chat: return "bubble.left.and.bubble.right"
        case .actionItem: return "checkmark.circle"
        case .decision: return "doc.text"
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

// MARK: - Search Filters View
struct SearchFiltersView: View {
    @Binding var filters: SearchFilters
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Search In") {
                    Toggle("Messages", isOn: $filters.searchInMessages)
                    Toggle("Users", isOn: $filters.searchInUsers)
                    Toggle("Chats", isOn: $filters.searchInChats)
                    Toggle("Action Items", isOn: $filters.searchInActionItems)
                    Toggle("Decisions", isOn: $filters.searchInDecisions)
                    Toggle("Meetings", isOn: $filters.searchInMeetings)
                }
                
                Section("Date Range") {
                    Picker("Date Range", selection: $filters.dateRange) {
                        Text("All Time").tag(SearchFilters.DateRange?.none)
                        Text("Today").tag(SearchFilters.DateRange?.some(.today))
                        Text("Yesterday").tag(SearchFilters.DateRange?.some(.yesterday))
                        Text("This Week").tag(SearchFilters.DateRange?.some(.thisWeek))
                        Text("This Month").tag(SearchFilters.DateRange?.some(.thisMonth))
                    }
                }
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        filters = SearchFilters()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Search Result Detail View
struct SearchResultDetailView: View {
    let result: SearchResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: iconForType(result.type))
                                .foregroundColor(colorForType(result.type))
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(result.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(result.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Text(timeAgoString(from: result.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Content")
                            .font(.headline)
                        
                        Text(result.content)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Metadata
                    if !result.metadata.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details")
                                .font(.headline)
                            
                            ForEach(Array(result.metadata.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text(key.capitalized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(result.metadata[key] ?? "")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Search Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func iconForType(_ type: SearchResult.SearchResultType) -> String {
        switch type {
        case .message: return "message"
        case .user: return "person.circle"
        case .chat: return "bubble.left.and.bubble.right"
        case .actionItem: return "checkmark.circle"
        case .decision: return "doc.text"
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

#Preview {
    SmartSearchView()
        .environmentObject(MessageService())
        .environmentObject(AuthService())
}
