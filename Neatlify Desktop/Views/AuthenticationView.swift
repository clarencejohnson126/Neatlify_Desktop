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
        isLoading = true
        errorMessage = ""

        Task {
            do {
                if isSignUp {
                    _ = try await AuthenticationService.shared.signUp(
                        email: email.lowercased().trimmingCharacters(in: .whitespaces),
                        password: password,
                        fullName: fullName
                    )
                } else {
                    let response = try await AuthenticationService.shared.signIn(
                        email: email.lowercased().trimmingCharacters(in: .whitespaces),
                        password: password
                    )

                    // Save session and user info
                    if let session = response.session, let user = response.user {
                        AuthSessionStorage.shared.saveSession(session, userId: user.id, email: user.email)
                        Logger.shared.info("Auth successful for user: \(user.email)")
                    }
                }

                await MainActor.run {
                    isLoading = false
                    // UserSession will listen for auth changes
                    userSession.checkAuthStatus()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                    Logger.shared.error("Auth failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(UserSession())
}
