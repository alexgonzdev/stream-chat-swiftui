//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

open class ChannelHeaderLoader: ObservableObject {
    @Injected(\.images) var images
    @Injected(\.utils) var utils
    @Injected(\.chatClient) var chatClient
    
    /// The maximum number of images that combine to form a single avatar
    private let maxNumberOfImagesInCombinedAvatar = 4
    
    /// Context provided utils.
    internal lazy var imageLoader = utils.imageLoader
    internal lazy var imageCDN = utils.imageCDN
    internal lazy var channelAvatarsMerger = utils.channelAvatarsMerger
    internal lazy var channelNamer = utils.channelNamer
    
    /// Placeholder images.
    internal lazy var placeholder1 = images.userAvatarPlaceholder1
    internal lazy var placeholder2 = images.userAvatarPlaceholder2
    internal lazy var placeholder3 = images.userAvatarPlaceholder3
    internal lazy var placeholder4 = images.userAvatarPlaceholder4
    
    @Published var loadedImages = [String: UIImage]()
    
    public init() {}
    
    /// Loads an image for the provided channel.
    /// If the image is not downloaded, placeholder is returned.
    /// - Parameter channel: the provided channel.
    /// - Returns: the available image.
    public func image(for channel: ChatChannel) -> UIImage {
        if let image = loadedImages[channel.cid.id] {
            return image
        }
        
        if let url = channel.imageURL {
            loadChannelThumbnail(for: channel, from: url)
            return placeholder4
        }
        
        if channel.isDirectMessageChannel {
            let lastActiveMembers = self.lastActiveMembers(for: channel)
            if let otherMember = lastActiveMembers.first, let url = otherMember.imageURL {
                loadChannelThumbnail(for: channel, from: url)
                return placeholder3
            } else {
                return placeholder4
            }
        } else {
            let activeMembers = lastActiveMembers(for: channel)
            
            if activeMembers.isEmpty {
                return placeholder4
            }
            
            let urls = activeMembers
                .compactMap(\.imageURL)
                .prefix(maxNumberOfImagesInCombinedAvatar)
            
            if urls.isEmpty {
                return placeholder3
            } else {
                loadMergedAvatar(from: channel, urls: Array(urls))
                return placeholder4
            }
        }
    }
    
    // MARK: - private
    
    private func loadMergedAvatar(from channel: ChatChannel, urls: [URL]) {
        imageLoader.loadImages(
            from: urls,
            placeholders: [],
            loadThumbnails: true,
            thumbnailSize: .avatarThumbnailSize,
            imageCDN: imageCDN
        ) { [weak self] images in
            guard let self = self else { return }
            DispatchQueue.global(qos: .userInteractive).async {
                let image = self.channelAvatarsMerger.createMergedAvatar(from: images) ?? self.placeholder2
                DispatchQueue.main.async {
                    self.loadedImages[channel.cid.id] = image
                }
            }
        }
    }
    
    private func loadChannelThumbnail(
        for channel: ChatChannel,
        from url: URL
    ) {
        imageLoader.loadImage(
            url: url,
            imageCDN: imageCDN,
            resize: true,
            preferredSize: .avatarThumbnailSize
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(image):
                self.loadedImages[channel.cid.id] = image
            case let .failure(error):
                log.error("error loading image: \(error.localizedDescription)")
            }
        }
    }
    
    private func lastActiveMembers(for channel: ChatChannel) -> [ChatChannelMember] {
        channel.lastActiveMembers
            .sorted { $0.memberCreatedAt < $1.memberCreatedAt }
            .filter { $0.id != chatClient.currentUserId }
    }
}