// Copyright © Blockchain Luxembourg S.A. All rights reserved.

extension UserDefaults {
    public func set<T: Encodable>(codable: T?, forKey key: String) {
        let encoder = JSONEncoder()
        guard codable != nil else {
            set(nil, forKey: key)
            synchronize()
            return
        }
        do {
            let data = try encoder.encode(codable)
            let jsonString = String(data: data, encoding: .utf8)!
            set(jsonString, forKey: key)
            synchronize()
        } catch {
            Logger.shared.error("Saving \"\(key)\" failed: \(error)")
        }
    }

    public func codable<T: Decodable>(_ codable: T.Type, forKey key: String) -> T? {
        guard let jsonString = string(forKey: key) else { return nil }
        guard let data = jsonString.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(codable, from: data)
    }
}