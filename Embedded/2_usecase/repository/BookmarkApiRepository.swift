//
//  BookmarkApiRepository.swift
//  Embedded
//
//  Created by abeyuya on 2019/09/22.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation

public enum BookmarkApiRepository {
    private static let endpoint = "https://asia-northeast1-twibu-c4d5a.cloudfunctions.net/execFetchTop"

    private struct BookmarkResponse: Codable {
        let bookmarks: [Bookmark]
    }

    public static func fetchBookmarks(completion: @escaping (Result<[Bookmark]>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(TwibuError.apiError("不正なURLです: \(endpoint)")))
            return
        }

        URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                completion(.failure(TwibuError.apiError(error.localizedDescription)))
                return
            }

            guard let data = data else {
                completion(.failure(TwibuError.apiError("レスポンスデータが不正です")))
                return
            }

            do {
                let res = try JSONDecoder().decode(
                    BookmarkResponse.self,
                    from: JSONSerialization.data(withJSONObject: data)
                )
                completion(.success(res.bookmarks))
                return
            } catch {
                let message = "\(BookmarkResponse.self)のdecodeに失敗しました error: \(error.localizedDescription)"
                completion(.failure(TwibuError.apiError(message)))
                return
            }
        }
    }
}
