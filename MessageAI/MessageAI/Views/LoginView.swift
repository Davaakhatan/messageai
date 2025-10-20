import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 50)
                    
                    // App Logo/Title with Animation
                    VStack(spacing: 16) {
                        Image(systemName: "message.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .scaleEffect(isAnimating ? 1.0 : 0.8)
                            .opacity(isAnimating ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.8), value: isAnimating)
                        
                        VStack(spacing: 8) {
                            Text("MessageAI")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .opacity(isAnimating ? 1.0 : 0.0)
                                .offset(y: isAnimating ? 0 : 20)
                                .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
                            
                            Text("Intelligent Messaging")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .opacity(isAnimating ? 1.0 : 0.0)
                                .offset(y: isAnimating ? 0 : 20)
                                .animation(.easeOut(duration: 0.8).delay(0.4), value: isAnimating)
                        }
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Form with Animation
                    VStack(spacing: 20) {
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Display Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                                
                                TextField("Enter your name", text: $displayName)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .autocapitalization(.words)
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.default)
                        }
                    }
                    .padding(.horizontal, 30)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: isAnimating)
                    
                    // Action Buttons with Animation
                    VStack(spacing: 16) {
                        Button(action: handleAuth) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isFormValid ? Color.blue : Color.gray)
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(authService.isLoading || !isFormValid)
                        .scaleEffect(isFormValid ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.2), value: isFormValid)
                        
                        Button(action: toggleAuthMode) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 30)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: isAnimating)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(authService.errorMessage ?? "An error occurred")
            }
            .onChange(of: authService.errorMessage) { errorMessage in
                if errorMessage != nil {
                    showingAlert = true
                }
            }
            .onAppear {
                withAnimation {
                    isAnimating = true
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !displayName.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func handleAuth() {
        if isSignUp {
            authService.signUp(email: email, password: password, displayName: displayName)
        } else {
            authService.signIn(email: email, password: password)
        }
    }
    
    private func toggleAuthMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isSignUp.toggle()
        }
        authService.errorMessage = nil
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
}
