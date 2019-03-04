//
//  Reactionable.swift
//  GetStream-iOS
//
//  Created by Alexey Bukhtin on 12/02/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol Reactionable {
    associatedtype ReactionType = ReactionProtocol
    
    /// Include reactions added by current user to all activities.
    var userOwnReactions: [ReactionKind: [ReactionType]]? { get set }
    /// Include recent reactions to activities.
    var latestReactions: [ReactionKind: [ReactionType]]? { get set }
    /// Include reaction counts to activities.
    var reactionCounts: [ReactionKind: Int]? { get set }
}

extension Reactionable {
    /// The original reactionable object.
    ///
    /// In case if the reactionable object has a referance to the original reactionable object, then it should be redefined here.
    ///
    /// For example: Reposted activity should have a reference to the original activity
    /// and all reactions of a reposted activity should referenced to the original activity reactions.
    /// Usually the original activity should be stored in the activity object property as an enum
    /// and in this case the origin property could be redefined in this way:
    /// ```
    /// public var original: Activity {
    ///     if case .repost(let original) = object {
    ///         return original
    ///     }
    ///
    ///     return self
    /// }
    /// ```
    public var original: Self {
        return self
    }
}

// MARK: - Access

extension Reactionable where ReactionType: ReactionProtocol {
    
    /// Check user reactions with a given reaction kind.
    ///
    /// - Parameter reactionKind: a kind of the reaction.
    /// - Returns: true if exists the reaction of the user.
    public func hasUserOwnReaction(_ reactionKind: ReactionKind) -> Bool {
        return original.userOwnReactionsCount(reactionKind) > 0
    }
    
    /// The number of user reactions with a given reaction kind.
    ///
    /// - Parameter reactionKind: a kind of the reaction.
    /// - Returns: the number of user reactions.
    public func userOwnReactionsCount(_ reactionKind: ReactionKind) -> Int {
        return original.userOwnReactions?[reactionKind]?.count ?? 0
    }
    
    /// Try to get the first user reaction with a given reaction kind.
    ///
    /// - Parameter reactionKind: a kind of the reaction.
    /// - Returns: the user reaction.
    public func userOwnReaction(_ reactionKind: ReactionKind) -> ReactionType? {
        return original.userOwnReactions?[reactionKind]?.first
    }
}

// MARK: - Managing

extension Reactionable where ReactionType: ReactionProtocol {
    
    /// Update the activity with a new user own reaction.
    ///
    /// - Parameter reaction: a new user own reaction.
    public mutating func addUserOwnReaction(_ reaction: ReactionType) {
        var userOwnReactions = self.userOwnReactions ?? [:]
        var latestReactions = self.latestReactions ?? [:]
        var reactionCounts = self.reactionCounts ?? [:]
        userOwnReactions[reaction.kind, default: []].insert(reaction, at: 0)
        latestReactions[reaction.kind, default: []].insert(reaction, at: 0)
        reactionCounts[reaction.kind, default: 0] += 1
        self.userOwnReactions = userOwnReactions
        self.latestReactions = latestReactions
        self.reactionCounts = reactionCounts
    }
    
    /// Remove an existing own reaction for the activity.
    ///
    /// - Parameter reaction: an existing user own reaction.
    public mutating func removeUserOwnReaction(_ reaction: ReactionType) {
        var userOwnReactions = self.userOwnReactions ?? [:]
        var latestReactions = self.latestReactions ?? [:]
        var reactionCounts = self.reactionCounts ?? [:]
        
        if let firstIndex = userOwnReactions[reaction.kind]?.firstIndex(where: { $0.id == reaction.id }) {
            userOwnReactions[reaction.kind, default: []].remove(at: firstIndex)
            self.userOwnReactions = userOwnReactions
            
            if let firstIndex = latestReactions[reaction.kind]?.firstIndex(where: { $0.id == reaction.id }) {
                latestReactions[reaction.kind, default: []].remove(at: firstIndex)
                self.latestReactions = latestReactions
            }
            
            if let count = reactionCounts[reaction.kind], count > 0 {
                reactionCounts[reaction.kind, default: 0] = count - 1
                self.reactionCounts = reactionCounts
            }
        }
    }
}
