//
//  Bundle+Decodable.swift
//  GameLogger
//
//  Created by Justin Gain on 7/14/25.
//
import Foundation

extension Bundle {
    func decode<T: Decodable>(_ type: T.Type, from file: String) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }

        let decoder = JSONDecoder()

        guard let loaded = try? decoder.decode(T.self, from: data) else {
            fatalError("Failed to decode \(file) from bundle.")
        }

        return loaded
    }
    
    // Special method for loading platforms since we need to convert PlatformData to Platform
    func loadPlatforms(from file: String) -> [Platform] {
        let platformDataArray: [PlatformData] = decode([PlatformData].self, from: file)
        return platformDataArray.map { $0.toPlatform() }
    }
}
