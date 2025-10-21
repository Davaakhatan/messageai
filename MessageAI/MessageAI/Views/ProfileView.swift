import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingEditProfile = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 16) {
                    // Profile Image
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay {
                            if let profileImageURL = authService.currentUser?.profileImageURL {
                                AsyncImage(url: URL(string: profileImageURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                }
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            }
                        }
                    
                    // User Info
                    VStack(spacing: 4) {
                        Text(authService.currentUser?.displayName ?? "Unknown User")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .onAppear {
                                print("🔍 ProfileView - currentUser: \(authService.currentUser?.displayName ?? "nil")")
                                print("🔍 ProfileView - isAuthenticated: \(authService.isAuthenticated)")
                            }
                        
                        Text(authService.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // Profile Options
                VStack(spacing: 0) {
                    ProfileOptionRow(
                        icon: "person.circle",
                        title: "Edit Profile",
                        action: { showingEditProfile = true }
                    )
                    
                    Divider()
                    
                    ProfileOptionRow(
                        icon: "bell",
                        title: "Notifications",
                        action: { }
                    )
                    
                    Divider()
                    
                    NavigationLink(destination: SettingsView()) {
                        HStack(spacing: 16) {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Settings")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                    
                    NavigationLink(destination: HelpSupportView()) {
                        HStack(spacing: 16) {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Help & Support")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                
                       Spacer()
                
                // Sign Out Button
                Button(action: { showingSignOutAlert = true }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var displayName = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Image
                Button(action: { showingImagePicker = true }) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(Circle())
                            } else if let profileImageURL = authService.currentUser?.profileImageURL {
                                AsyncImage(url: URL(string: profileImageURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                }
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                )
                        )
                }
                
                // Display Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.headline)
                    
                    TextField("Enter display name", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .autocapitalization(.words)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(displayName.isEmpty || authService.isLoading)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                CustomImagePicker(selectedImage: $selectedImage)
            }
            .onAppear {
                displayName = authService.currentUser?.displayName ?? ""
            }
        }
    }
    
    private func saveProfile() {
        authService.updateUserProfile(
            displayName: displayName,
            profileImageURL: selectedImage != nil ? "placeholder_url" : nil
        )
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService())
}
