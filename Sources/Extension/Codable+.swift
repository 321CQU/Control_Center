//
//  Codable+.swift
//
//
//  Created by 朱子骏 on 2023/8/25.
//

import Foundation

public protocol DefaultCodableStrategy {
    associatedtype DefaultValue: Decodable
    
    /// The fallback value used when decoding fails
    static var defaultValue: DefaultValue { get }
}

@propertyWrapper
public struct DefaultCodable<Default: DefaultCodableStrategy> {
    public var wrappedValue: Default.DefaultValue
    
    public init(wrappedValue: Default.DefaultValue) {
        self.wrappedValue = wrappedValue
    }
}

extension DefaultCodable: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = (try? container.decode(Default.DefaultValue.self)) ?? Default.defaultValue
    }
}

extension DefaultCodable: Encodable where Default.DefaultValue: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension KeyedDecodingContainer {
    func decode<T>(_ type: DefaultCodable<T>.Type, forKey key: Key) throws -> DefaultCodable<T> where T: DefaultCodableStrategy {
        (try decodeIfPresent(type, forKey: key)) ?? DefaultCodable(wrappedValue: T.defaultValue)
    }
}

extension Decodable {
    static func fromJsonString(_ json: String) throws -> Self {
        guard let data = json.data(using: .utf8) else {
            fatalError("Failed to convert string to data")
        }
        return try JSONDecoder().decode(Self.self, from: data)
    }
    
    static func fromFile(_ url: URL) throws -> Self {
        guard FileManager.default.fileExists(atPath: url.path) else {
            fatalError("File not exists")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Self.self, from: data)
    }
}
