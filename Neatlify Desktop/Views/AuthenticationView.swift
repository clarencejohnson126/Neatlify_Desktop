//
//  AuthenticationView.swift
//  Neatlify Desktop
//
//  Login and signup UI with Supabase Auth
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var userSession: UserSession
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        ZStack {
            Color.neatlifyBg.ignoresSafeArea()

            VStack(spacing: 24) {
                // Logo
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.neatlifyGreen)
                            .frame(width: 80, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.neatlifyDark, lineWidth: 3)
                            )
                        Text("N")
                            .font(.system(size: 48, weight: .black))
                            .foregroundColor(.white)
                    }

                    Text("Neatlify")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.neatlifyDark)

                    Text(isSignUp ? "Create your account" : "Sign in to your account")
                        .font(.subheadline)
                        .foregroundColor(.neatlifyDark.opacity(0.6))
                }

                // Form fields
                VStack(spacing: 16) {
                    if isSignUp {
                        TextField("Full Name", text: $fullName)
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.neatlifyDark, lineWidth: 2)
                            )
                    }

                    TextField("Email", text: $email)
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.neatlifyDark, lineWidth: 2)
                            )

                    SecureField("Password", text: $password)
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.neatlifyDark, lineWidth: 2)
                        )
                }

                // Submit button
                Button(action: handleAuth) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: isSignUp ? "person.badge.plus" : "arrow.right")
                        }
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.neatlifyGreen)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.neatlifyDark, lineWidth: 2)
                    )
                    .shadow(color: Color.neatlifyDark.opacity(0.2), radius: 0, x: 3, y: 3)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && fullName.isEmpty))

                // Toggle between sign in and sign up
                HStack(spacing: 4) {
                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                        .font(.subheadline)
                        .foregroundColor(.neatlifyDark.opacity(0.6))

                    Button(action: {
                        isSignUp.toggle()
                        errorMessage = ""
                    }) {
                        Text(isSignUp ? "Sign In" : "Sign Up")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.neatlifyGreen)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Info box
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.neatlifyYellow)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Secure Login")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.neatlifyDark)
                        Text("Your credentials are encrypted and secure")
                            .font(.caption2)
                            .foregroundColor(.neatlifyDark.opacity(0.6))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.neatlifyYellow.opacity(0.15))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.neatlifyDark, lineWidth: 2)
                )
            }
            .padding(32)
            .frame(maxWidth: 420)
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func handleAuth() {
        print("🎯 Button clicked! Starting auth flow...")
        print("📧 Email: \(email)")
        print("🔒 Mode: \(isSignUp ? "SignUp" : "SignIn")")

        isLoading = true
        errorMessage = ""

        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        print("🔐 Auth attempt: \(isSignUp ? "SignUp" : "SignIn") - Email: \(trimmedEmail)")

        Task {
            do {
                if isSignUp {
                    print("📝 Attempting signup...")
                    _ = try await AuthenticationService.shared.signUp(
                        email: trimmedEmail,
                        password: password,
                        fullName: fullName
                    )
                    print("✅ Signup successful")
                } else {
                    print("🔓 Attempting signin...")
                    let response = try await AuthenticationService.shared.signIn(
                        email: trimmedEmail,
                        password: password
                    )
                    print("✅ Signin API response received")

                    // Save session and user info
                    if let session = response.session, let user = response.user {
                        print("💾 Saving session - User: \(user.email)")

                        // CRITICAL: Clear any old session before saving new one
                        // This prevents auto-login with previous user's account
                        let currentEmail = AuthSessionStorage.shared.getUserEmail()
                        if let currentEmail = currentEmail, currentEmail != user.email {
                            print("🔄 Switching users: \(currentEmail) → \(user.email)")
                            print("🗑️  Clearing old Keychain session for: \(currentEmail)")
                            AuthSessionStorage.shared.clearSession()
                        }

                        AuthSessionStorage.shared.saveSession(session, userId: user.id, email: user.email)
                        Logger.shared.info("Auth successful for user: \(user.email)")
                        print("✅ Session saved successfully")
                    } else {
                        print("❌ No session or user in response: session=\(response.session != nil), user=\(response.user != nil)")
                    }
                }

                await MainActor.run {
                    print("🔄 Updating UI and checking auth status...")
                    isLoading = false
                    // UserSession will listen for auth changes
                    userSession.checkAuthStatus()
                    print("✅ Auth check complete")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let errorDesc = error.localizedDescription
                    print("❌ Authentication ERROR: \(errorDesc)")
                    print("❌ Full error: \(error)")

                    // Provide user-friendly error messages
                    let friendlyError: String
                    if errorDesc.contains("Invalid login credentials") {
                        friendlyError = "❌ Incorrect email or password.\n\nPlease check and try again."
                    } else if errorDesc.contains("429") || errorDesc.contains("rate") {
                        friendlyError = "⏱️ Too many login attempts.\n\nPlease wait 10 minutes before trying again."
                    } else if errorDesc.contains("invalid email") || errorDesc.contains("invalid_email") {
                        friendlyError = "❌ Invalid email address.\n\nPlease check the spelling."
                    } else if errorDesc.contains("Network") {
                        friendlyError = "🌐 Network error.\n\nPlease check your connection."
                    } else if errorDesc.contains("405") {
                        friendlyError = "⚠️ Invalid request format.\n\nPlease check your input."
                    } else {
                        friendlyError = "❌ Auth failed: \(errorDesc)"
                    }

                    print("📢 Showing error to user: \(friendlyError)")
                    errorMessage = friendlyError
                    showError = true
                    Logger.shared.error("Auth failed: \(errorDesc)")
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(UserSession())
}
