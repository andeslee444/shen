//
//  TerrainTextField.swift
//  Terrain
//
//  Text field and input components
//

import SwiftUI

// MARK: - Text Field

struct TerrainTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    @Environment(\.terrainTheme) private var theme
    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(theme.typography.bodyMedium)
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .stroke(isFocused ? theme.colors.accent : theme.colors.textTertiary.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(theme.cornerRadius.medium)
        .focused($isFocused)
    }
}

// MARK: - Text Area

struct TerrainTextArea: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100

    @Environment(\.terrainTheme) private var theme
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textTertiary)
                    .padding(theme.spacing.md)
            }

            TextEditor(text: $text)
                .font(theme.typography.bodyMedium)
                .scrollContentBackground(.hidden)
                .padding(theme.spacing.sm)
                .frame(minHeight: minHeight)
        }
        .background(theme.colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .stroke(isFocused ? theme.colors.accent : theme.colors.textTertiary.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(theme.cornerRadius.medium)
        .focused($isFocused)
    }
}

// MARK: - Selection Option

struct TerrainSelectionOption: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(title)
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(theme.colors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer()

                Circle()
                    .strokeBorder(isSelected ? theme.colors.accent : theme.colors.textTertiary, lineWidth: 2)
                    .background(
                        Circle()
                            .fill(isSelected ? theme.colors.accent : Color.clear)
                            .padding(4)
                    )
                    .frame(width: 24, height: 24)
            }
            .padding(theme.spacing.md)
            .background(isSelected ? theme.colors.accent.opacity(0.08) : theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(isSelected ? theme.colors.accent : theme.colors.textTertiary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Checkbox Option

struct TerrainCheckboxOption: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(title)
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(theme.colors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer()

                RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                    .strokeBorder(isSelected ? theme.colors.accent : theme.colors.textTertiary, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                            .fill(isSelected ? theme.colors.accent : Color.clear)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.colors.textInverted)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .frame(width: 24, height: 24)
            }
            .padding(theme.spacing.md)
            .background(isSelected ? theme.colors.accent.opacity(0.08) : theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(isSelected ? theme.colors.accent : theme.colors.textTertiary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview("Inputs") {
    VStack(spacing: 16) {
        TerrainTextField(placeholder: "Enter your name", text: .constant(""))
        TerrainTextField(placeholder: "Password", text: .constant("secret"), isSecure: true)
        TerrainTextArea(placeholder: "Add notes...", text: .constant(""))

        TerrainSelectionOption(
            title: "Always cold",
            subtitle: "You often need extra layers",
            isSelected: true,
            action: {}
        )

        TerrainSelectionOption(
            title: "Often hot",
            isSelected: false,
            action: {}
        )

        TerrainCheckboxOption(
            title: "Sleep",
            subtitle: "Improve sleep quality",
            isSelected: true,
            action: {}
        )
    }
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
