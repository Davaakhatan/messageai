import SwiftUI

struct HelpSupportView: View {
    var body: some View {
        VStack {
            Text("Help & Support")
                .font(.largeTitle)
                .padding()
            
            Text("Help and support functionality coming soon!")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Help & Support")
    }
}

#Preview {
    HelpSupportView()
}