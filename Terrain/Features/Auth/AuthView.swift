//
//  AuthView.swift
//  Terrain
//
//  Authentication screen: email/password, Apple Sign In, or skip (local-only).
//  Shown before onboarding for new users and accessible from You tab settings.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let syncService: SupabaseSyncService
    let onContinueWithoutAccount: (() -> Void)?

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(
        syncService: SupabaseSyncService,
        onContinueWithoutAccount: (() -> Void)? = nil
    ) {
        self.syncService = syncService
        self.onContinueWithoutAccount = onContinueWithoutAccount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Header
                    VStack(spacing: theme.spacing.sm) {
                        Text("Terrain")
                            .font(theme.typography.displayLarge)
                            .foregroundColor(theme.colors.textPrimary)

                        Text("Sync your wellness journey across devices")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, theme.spacing.xxl)

                    // Email/Password form
                    VStack(spacing: theme.spacing.md) {
                        VStack(spacing: theme.spacing.sm) {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(theme.typography.bodyMedium)
                                .padding(theme.spacing.sm)
                                .background(theme.colors.surface)
                                .cornerRadius(theme.cornerRadius.medium)
                                .accessibilityLabel("Email address")

                            SecureField("Password", text: $password)
                                .textContentType(isSignUp ? .newPassword : .password)
                                .font(theme.typography.bodyMedium)
                                .padding(theme.spacing.sm)
                                .background(theme.colors.surface)
                                .cornerRadius(theme.cornerRadius.medium)
                                .accessibilityLabel("Password")
                        }

                        // Error message
                        if let errorMessage {
                            Text(errorMessage)
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.colors.error)
                                .multilineTextAlignment(.center)
                        }

                        // Sign In / Sign Up button
                        Button {
                            Task { await handleEmailAuth() }
                        } label: {
                            HStack(spacing: theme.spacing.xs) {
                                if isLoading {
                                    ProgressView()
                                        .tint(theme.colors.textInverted)
                                }
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(theme.typography.labelLarge)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacing.md)
                            .background(theme.colors.accent)
                            .foregroundColor(theme.colors.textInverted)
                            .cornerRadius(theme.cornerRadius.medium)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)
                        .accessibilityLabel(isSignUp ? "Create account" : "Sign in")

                        // Toggle sign in / sign up
                        Button {
                            isSignUp.toggle()
                            errorMessage = nil
                        } label: {
                            Text(isSignUp
                                ? "Already have an account? Sign In"
                                : "Don't have an account? Sign Up")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.colors.accent)
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(theme.colors.textTertiary.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                        Rectangle()
                            .fill(theme.colors.textTertiary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(theme.cornerRadius.medium)
                    .padding(.horizontal, theme.spacing.lg)

                    // Continue without account
                    if let onContinueWithoutAccount {
                        Button {
                            onContinueWithoutAccount()
                        } label: {
                            Text("Continue without account")
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textSecondary)
                                .underline()
                        }
                        .padding(.top, theme.spacing.sm)
                        .accessibilityLabel("Continue without creating an account")
                        .accessibilityHint("Your data will only be stored on this device")
                    }

                    Spacer(minLength: theme.spacing.xxl)
                }
            }
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if onContinueWithoutAccount == nil {
                        // Shown when accessed from Settings — allow dismissal
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        .accessibilityLabel("Close")
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func handleEmailAuth() async {
        isLoading = true
        errorMessage = nil

        do {
            if isSignUp {
                try await syncService.signUp(email: email, password: password)
            } else {
                try await syncService.signIn(email: email, password: password)
            }
            // Trigger full sync after auth
            await syncService.sync()
            dismiss()
        } catch {
            errorMessage = friendlyError(error)
        }

        isLoading = false
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                errorMessage = "Could not process Apple Sign In"
                return
            }

            isLoading = true
            Task {
                do {
                    // Apple Sign In with Supabase uses the ID token
                    try await syncService.signInWithApple(
                        idToken: idToken,
                        nonce: "" // Supabase handles nonce internally
                    )
                    await syncService.sync()
                    dismiss()
                } catch {
                    errorMessage = friendlyError(error)
                }
                isLoading = false
            }

        case .failure(let error):
            // User cancelled is not an error worth showing
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = friendlyError(error)
            }
        }
    }

    /// Converts technical errors into user-friendly messages
    private func friendlyError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("invalid login") || message.contains("invalid credentials") {
            return "Incorrect email or password. Please try again."
        } else if message.contains("already registered") || message.contains("already exists") {
            return "An account with this email already exists. Try signing in."
        } else if message.contains("network") || message.contains("connection") {
            return "Network error. Please check your connection."
        } else if message.contains("weak password") || message.contains("password") {
            return "Password must be at least 6 characters."
        }
        return "Something went wrong. Please try again."
    }
}

#Preview {
    AuthView(
        syncService: SupabaseSyncService(),
        onContinueWithoutAccount: { }
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
