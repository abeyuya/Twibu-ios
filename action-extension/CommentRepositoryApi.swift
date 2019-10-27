//
//  CommentRepositoryApi.swift
//  action-extension
//
//  Created by abeyuya on 2019/09/23.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Embedded

final class CommentRepositoryApi {
    static let shared = CommentRepositoryApi()
    private init() {}
    private static let endpoint = "https://asia-northeast1-twibu-c4d5a.cloudfunctions.net/execFetchBookmarkAndComments"
    private var res: ApiResponse?

    struct ApiResponse: Codable {
        let bookmark: Bookmark
        let comments: [Comment]

        init?(data: Data) {
            guard let d = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return nil
            }

            do {
                self = try JSONDecoder().decode(
                    Self.self,
                    from: JSONSerialization.data(withJSONObject: d)
                )
            } catch {
                Logger.print("\(Self.self)のdecodeに失敗しました dict: \(d)")
                return nil
            }
        }
    }
}

extension CommentRepositoryApi {
    func getResponse() -> ApiResponse? {
        return res
    }

    func fetchBookmarkAndCommentsApi(
        bookmarkUrl: String,
        completion: @escaping (Result<ApiResponse, TwibuError>) -> Void
    ) {
        guard var components = URLComponents(string: CommentRepositoryApi.endpoint) else {
            completion(.failure(.apiError("endpoint予期せぬエラー")))
            return
        }

        components.queryItems = [URLQueryItem(name: "url", value: bookmarkUrl)]
        guard let url = components.url else {
            completion(.failure(.apiError("不正なURLです: \(bookmarkUrl)")))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                completion(.failure(.apiError(error.localizedDescription)))
                return
            }

            guard let data = data else {
                completion(.failure(.apiError("レスポンスデータが不正です")))
                return
            }

            guard let res = ApiResponse(data: data) else {
                let message = "\(ApiResponse.self)のdecodeに失敗しました"
                completion(.failure(.apiError(message)))
                return
            }

            self?.res = res
            completion(.success(res))
        }
        task.resume()
    }
}
