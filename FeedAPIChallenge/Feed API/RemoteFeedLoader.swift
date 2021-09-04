//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

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
			guard let _ = self else { return }
			switch result {
			case .success((let data, let response)):
				let decoder = JSONDecoder()
				if response.statusCode == 200, let feedImages = try? decoder.decode(FeedImageParser.self, from: data).feedImages {
					completion(.success(feedImages))
				} else {
					completion(.failure(.invalidData))
				}
			case .failure:
				completion(.failure(.connectivity))
			}
		}
	}
}

private struct FeedImageParser: Decodable {
	private struct FeedImageResponse: Decodable {
		let image_id: String
		let image_desc: String?
		let image_loc: String?
		let image_url: String
	}

	private let items: [FeedImageResponse]

	var feedImages: [FeedImage] {
		return items.map {
			return FeedImage(
				id: UUID(uuidString: $0.image_id) ?? UUID(),
				description: $0.image_desc,
				location: $0.image_loc,
				url: URL(string: $0.image_url) ?? URL(fileURLWithPath: "")
			)
		}
	}
}
