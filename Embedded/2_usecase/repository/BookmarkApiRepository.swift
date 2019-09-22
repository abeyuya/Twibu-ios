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

        //
        // 日付はこんな構造で返ってくる
        //
        //  "created_at": {
        //    "_seconds": 1569144510,
        //    "_nanoseconds": 299000000
        //  },
        //

        init?(data: Data) {
            guard let d = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let oldBookmarksDict = d["bookmarks"] as? Array<[String: Any]> else {
                    return nil
            }

            let newBookmarksDict = oldBookmarksDict.map { (d: [String: Any]) -> [String : Any] in
                var new = d

                if let createdAt = d["created_at"] as? [String: Any] {
                    new["created_at"] = createdAt["_seconds"]
                } else {
                    new.removeValue(forKey: "created_at")
                }

                if let updatedAt = d["updated_at"] as? [String: Any] {
                    new["updated_at"] = updatedAt["_seconds"]
                } else {
                    new.removeValue(forKey: "updated_at")
                }

                return new
            }

            let dict = ["bookmarks": newBookmarksDict]

            do {
                self = try JSONDecoder().decode(
                    Self.self,
                    from: JSONSerialization.data(withJSONObject: dict)
                )
            } catch {
                Logger.print("\(Self.self)のdecodeに失敗しました dict: \(dict)")
                return nil
            }
        }
    }

    public static func fetchBookmarks(completion: @escaping (Result<[Bookmark]>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(TwibuError.apiError("不正なURLです: \(endpoint)")))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                completion(.failure(TwibuError.apiError(error.localizedDescription)))
                return
            }

            guard let data = data else {
                completion(.failure(TwibuError.apiError("レスポンスデータが不正です")))
                return
            }

            guard let res = BookmarkResponse(data: data) else {
                let message = "\(BookmarkResponse.self)のdecodeに失敗しました"
                completion(.failure(TwibuError.apiError(message)))
                return
            }

            completion(.success(res.bookmarks))
        }
        task.resume()
    }
}
