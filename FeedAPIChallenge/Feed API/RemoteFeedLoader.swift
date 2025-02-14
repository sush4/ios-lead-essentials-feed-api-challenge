//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient
	private static let ok_200 = 200

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] result in
			guard self != nil else { return }
			switch result {
			case let .success((data, response)):
				RemoteFeedLoader.mapSuccessResponse(data: data, response: response, completion: completion)
			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}

	private static func mapSuccessResponse(data: Data, response: HTTPURLResponse, completion: @escaping (FeedLoader.Result) -> Void) {
		if response.statusCode == RemoteFeedLoader.ok_200, let feedImages = try? JSONDecoder().decode(FeedImageAPIResponse.self, from: data).feedImages {
			completion(.success(feedImages))
		} else {
			completion(.failure(Error.invalidData))
		}
	}
}

private struct FeedImageAPIResponse: Decodable {
	private struct FeedImageResponse: Decodable {
		let image_id: UUID
		let image_desc: String?
		let image_loc: String?
		let image_url: URL
	}

	private let items: [FeedImageResponse]

	var feedImages: [FeedImage] {
		return items.map {
			return FeedImage(
				id: $0.image_id,
				description: $0.image_desc,
				location: $0.image_loc,
				url: $0.image_url
			)
		}
	}
}
