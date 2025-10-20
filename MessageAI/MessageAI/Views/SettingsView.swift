import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
                .padding()
            
            Text("Settings functionality coming soon!")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}