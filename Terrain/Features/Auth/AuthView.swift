//
//  AuthView.swift
//  Terrain
//
//  Authentication screen: email/password, Apple Sign In, or skip (local-only).
//  Shown before onboarding for new users and accessible from You tab settings.
//

import SwiftUI
import AuthenticationServices
import CryptoKit

struct AuthView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let syncService: SupabaseSyncService
    let onContinueWithoutAccount: (() -> Void)?
    var onNameReceived: ((String) -> Void)?

    @State private var firstName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentNonce: String?

    init(
        syncService: SupabaseSyncService,
        onContinueWithoutAccount: (() -> Void)? = nil,
        onNameReceived: ((String) -> Void)? = nil
    ) {
        self.syncService = syncService
        self.onContinueWithoutAccount = onContinueWithoutAccount
        self.onNameReceived = onNameReceived
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
                            if isSignUp {
                                TextField("First name (optional)", text: $firstName)
                                    .textContentType(.givenName)
                                    .autocapitalization(.words)
                                    .font(theme.typography.bodyMedium)
                                    .padding(theme.spacing.sm)
                                    .background(theme.colors.surface)
                                    .cornerRadius(theme.cornerRadius.medium)
                                    .accessibilityLabel("First name, optional")
                            }

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
                        request.requestedScopes = [.email, .fullName]
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.nonce = sha256(nonce)
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

    /// Client-side validation before hitting the network.
    /// Returns a user-friendly error string, or nil if valid.
    private func validateInput() -> String? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedEmail.contains("@") || !trimmedEmail.contains(".") {
            return "Please enter a valid email address."
        }
        if password.count < 6 {
            return "Password must be at least 6 characters."
        }
        return nil
    }

    private func handleEmailAuth() async {
        if let validationError = validateInput() {
            errorMessage = validationError
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            if isSignUp {
                try await syncService.signUp(email: email, password: password)
                let trimmedName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    onNameReceived?(trimmedName)
                }
            } else {
                try await syncService.signIn(email: email, password: password)
            }
            // Trigger full sync after auth (force bypasses debounce)
            await syncService.sync(force: true)
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
                errorMessage = "Could not process Apple Sign In credentials"
                TerrainLogger.sync.error("Apple Sign In: missing credential or token data")
                return
            }

            // Extract given name from Apple credential (only provided on first sign-in)
            if let givenName = credential.fullName?.givenName, !givenName.isEmpty {
                onNameReceived?(givenName)
            }

            guard let nonce = currentNonce, !nonce.isEmpty else {
                errorMessage = "Security validation failed. Please try again."
                TerrainLogger.sync.error("Apple Sign In: nonce is empty or missing")
                return
            }

            isLoading = true
            errorMessage = nil
            Task {
                do {
                    try await syncService.signInWithApple(
                        idToken: idToken,
                        nonce: nonce
                    )
                    await syncService.sync(force: true)
                    await MainActor.run { dismiss() }
                } catch {
                    TerrainLogger.sync.error("Apple Sign In Supabase error: \(error.localizedDescription)")
                    await MainActor.run {
                        errorMessage = friendlyError(error)
                    }
                }
                await MainActor.run { isLoading = false }
            }

        case .failure(let error):
            TerrainLogger.sync.error("Apple Sign In ASAuthorization error: \(error.localizedDescription)")
            let nsError = error as NSError
            let errorCode = ASAuthorizationError.Code(rawValue: nsError.code)
            switch errorCode {
            case .canceled:
                // User tapped Cancel — not an error, but log it
                TerrainLogger.sync.info("Apple Sign In: user canceled")
            case .notHandled, .invalidResponse:
                errorMessage = "Apple Sign In is temporarily unavailable. Please try again."
            case .notInteractive:
                errorMessage = "Apple Sign In could not be shown. Please try again."
            case .unknown:
                // This often happens when the simulator isn't signed into an Apple ID
                errorMessage = "Apple Sign In failed. Make sure you're signed into an Apple ID in Settings."
            default:
                errorMessage = "Apple Sign In error: \(nsError.localizedDescription)"
            }
        }
    }

    // MARK: - Nonce Helpers

    /// Generates a cryptographically random 32-character string for Apple Sign In nonce.
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            // Fallback: use UUID-based randomness (still unique, just less entropy)
            return (0..<length).map { _ in
                String(format: "%02x", UInt8.random(in: 0...255))
            }.joined().prefix(length).description
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    /// SHA256 hash of the nonce, required by Apple Sign In for verification.
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
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
