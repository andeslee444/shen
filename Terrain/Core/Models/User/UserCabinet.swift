//
//  UserCabinet.swift
//  Terrain
//
//  SwiftData model for user's ingredient cabinet
//

import Foundation
import SwiftData

/// User's ingredient cabinet - tracks ingredients they have or want
@Model
final class UserCabinet {
    @Attribute(.unique) var id: UUID

    var ingredientId: String
    var isStaple: Bool
    var addedAt: Date
    var lastUsedAt: Date?

    init(
        id: UUID = UUID(),
        ingredientId: String,
        isStaple: Bool = false,
        addedAt: Date = Date(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.ingredientId = ingredientId
        self.isStaple = isStaple
        self.addedAt = addedAt
        self.lastUsedAt = lastUsedAt
    }

    func markUsed() {
        lastUsedAt = Date()
    }
}
