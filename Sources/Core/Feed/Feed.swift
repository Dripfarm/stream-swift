//
//  Feed.swift
//  GetStream
//
//  Created by Alexey Bukhtin on 09/11/2018.
//  Copyright © 2018 Stream.io Inc. All rights reserved.
//

import Foundation
import Moya
import Result

public struct Feed: CustomStringConvertible {
    private let feedId: FeedId
    private let client: Client
    
    public var description: String {
        return feedId.description
    }
    
    public init(_ feedId: FeedId, client: Client) {
        self.feedId = feedId
        self.client = client
    }
}

extension Client {
    public func feed(feedSlug: String, userId: String) -> Feed {
        return feed(FeedId(feedSlug: feedSlug, userId: userId))
    }
    
    public func feed(_ feedIf: FeedId) -> Feed {
        return Feed(feedIf, client: self)
    }
}

// MARK: - Add a new Activity

extension Feed {
    /// Add a new activity.
    @discardableResult
    public func add<T: ActivityProtocol>(_ activity: T, completion: @escaping Completion<T>) -> Cancellable {
        return client.request(endpoint: FeedEndpoint.add(activity, feedId: feedId)) {
            Client.parseResultsResponse($0, completion: completion)
        }
    }
}

// MARK: - Delete a new Activity

extension Feed {
    /// Remove an activity by the activityId.
    @discardableResult
    public func remove(by activityId: UUID, completion: @escaping RemovedCompletion) -> Cancellable {
        return client.request(endpoint: FeedEndpoint.deleteById(activityId, feedId: feedId)) {
            Client.parseRemovedResponse($0, completion: completion)
        }
    }
    
    /// Remove an activity by the foreignId.
    @discardableResult
    public func remove(by foreignId: String, completion: @escaping RemovedCompletion) -> Cancellable {
        return client.request(endpoint: FeedEndpoint.deleteByForeignId(foreignId, feedId: feedId)) {
            Client.parseRemovedResponse($0, completion: completion)
        }
    }
}

// MARK: - Receive Feed Activities

extension Feed {
    /// Receive feed activities.
    ///
    /// - Parameters:
    ///     - pagination: a pagination options.
    ///     - completion: a completion handler with Result of Activity.
    /// - Returns:
    ///     - a cancellable object to cancel the request.
    @discardableResult
    public func get(pagination: FeedPagination = .none, completion: @escaping Completion<Activity>) -> Cancellable {
        return get(typeOf: Activity.self, pagination: pagination, completion: completion)
    }
    
    /// Receive feed activities with a custom activity type.
    ///
    /// - Parameters:
    ///     - pagination: a pagination options.
    ///     - completion: a completion handler with Result of a custom activity type.
    /// - Returns:
    ///     - a cancellable object to cancel the request.
    @discardableResult
    public func get<T: ActivityProtocol>(typeOf type: T.Type,
                                         pagination: FeedPagination = .none,
                                         completion: @escaping Completion<T>) -> Cancellable {
        return client.request(endpoint: FeedEndpoint.get(feedId, pagination: pagination)) {
            Client.parseResultsResponse($0, inContainer: true, completion: completion)
        }
    }
}

// MARK: - Following

extension Feed {
    /// Follows a target feed.
    ///
    /// - Parameters:
    ///     - target: the target feed this feed should follow, e.g. user:44.
    ///     - activityCopyLimit: how many activities should be copied from the target feed, max 1000, default 100.
    @discardableResult
    public func follow(to target: FeedId, activityCopyLimit: Int = 100, completion: @escaping StatusCodeCompletion) -> Cancellable {
        let activityCopyLimit = max(0, min(1000, activityCopyLimit))
        let endpoint = FeedEndpoint.follow(feedId: feedId, target: target, activityCopyLimit: activityCopyLimit)
        
        return client.request(endpoint: endpoint) { Client.parseStatusCodeResponse($0, completion: completion) }
    }
    
    @discardableResult
    public func unfollow(from target: FeedId, keepHistory: Bool = false, completion: @escaping StatusCodeCompletion) -> Cancellable {
        return client.request(endpoint: FeedEndpoint.unfollow(feedId: feedId, target: target, keepHistory: keepHistory)) {
            Client.parseStatusCodeResponse($0, completion: completion)
        }
    }
}
