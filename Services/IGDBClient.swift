//
//  IGDBClient.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import Foundation

// MARK: - IGDB Data Models
struct IGDBCompany: Codable {
    let name: String
}

struct IGDBInvolvedCompany: Codable {
    let developer: Bool
    let publisher: Bool
    let company: IGDBCompany
}

struct IGDBGenre: Codable {
    let name: String
}

struct IGDBGame: Codable, Identifiable {
    let id: Int
    let name: String
    let cover: IGDBImage?
    let platforms: [IGDBPlatform]?
    let first_release_date: Int?
    let genres: [IGDBGenre]?
    let involved_companies: [IGDBInvolvedCompany]?
    // Note: time_to_beat is not available in search results
}

struct IGDBPlatform: Codable, Identifiable {
    let id: Int
    let name: String
    let platform_logo: IGDBImage?
}

struct IGDBImage: Codable {
    let url: String?
    
    var highResURL: URL? {
        guard let urlString = url else { return nil }
        // Use t_1080p for highest res cover art
        var highResString = "https:" + urlString
        highResString = highResString.replacingOccurrences(of: "t_thumb", with: "t_1080p")
        highResString = highResString.replacingOccurrences(of: "t_cover_big", with: "t_1080p")
        return URL(string: highResString)
    }
}

// MARK: - IGDB API Client
class IGDBClient {
    private let clientId = "q4z51z25mdfwt5jbuo62u9ok71p2k8" // <-- IMPORTANT
    private let clientSecret = "w01l8cf7fiuqq90x4ay3tx8caghdy4" // <-- IMPORTANT
    private var accessToken: String?
    private let apiBaseURL = "https://api.igdb.com/v4/"
    private var lastRequestTime: Date = Date.distantPast
    private let minimumRequestInterval: TimeInterval = 1.0 // 1 second between requests
    
    func getAccessToken(completion: @escaping (Bool) -> Void) {
        if accessToken != nil {
            print("IGDB: Using existing access token.")
            completion(true)
            return
        }
        
        print("IGDB: Requesting new access token...")
        let urlString = "https://id.twitch.tv/oauth2/token?client_id=\(clientId)&client_secret=\(clientSecret)&grant_type=client_credentials"
        guard let url = URL(string: urlString) else {
            print("IGDB ERROR: Invalid token URL.")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                print("IGDB ERROR: Token request failed - \(error.localizedDescription)")
                completion(false); return
            }
            guard let data = data else {
                print("IGDB ERROR: No data received for token.")
                completion(false); return
            }
            
            struct TokenResponse: Codable { let access_token: String }
            if let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                self?.accessToken = tokenResponse.access_token
                print("IGDB: Successfully received new access token.")
                completion(true)
            } else {
                print("IGDB ERROR: Failed to decode access token. Response: \(String(data: data, encoding: .utf8) ?? "Unreadable")")
                completion(false)
            }
        }.resume()
    }
    
    func searchGames(query: String, completion: @escaping ([IGDBGame]) -> Void) {
        // Rate limiting
        let timeSinceLastRequest = Date().timeIntervalSince(lastRequestTime)
        if timeSinceLastRequest < minimumRequestInterval {
            let delay = minimumRequestInterval - timeSinceLastRequest
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.performSearch(query: query, completion: completion)
            }
            return
        }
        
        performSearch(query: query, completion: completion)
    }
    
    private func performSearch(query: String, completion: @escaping ([IGDBGame]) -> Void) {
        lastRequestTime = Date()
        
        getAccessToken { [weak self] success in
            guard success, let self = self, let token = self.accessToken else {
                print("IGDB ERROR: Cannot perform search, access token is missing.")
                DispatchQueue.main.async { completion([]) }; return
            }
            
            guard let url = URL(string: self.apiBaseURL + "games") else { return }
            
            // Remove time_to_beat fields for now due to API limitations
            let requestBody = """
            search "\(query)";
            fields
                name,
                cover.url,
                first_release_date,
                genres.name,
                platforms.name,
                platforms.platform_logo.url,
                involved_companies.developer,
                involved_companies.publisher,
                involved_companies.company.name;
            limit 25;
            """
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = requestBody.data(using: .utf8)
            request.setValue(self.clientId, forHTTPHeaderField: "Client-ID")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    print("IGDB ERROR: Search request failed - \(error.localizedDescription)")
                    DispatchQueue.main.async { completion([]) }; return
                }
                guard let data = data else {
                    print("IGDB ERROR: No data received from search.")
                    DispatchQueue.main.async { completion([]) }; return
                }
                
                do {
                    let games = try JSONDecoder().decode([IGDBGame].self, from: data)
                    print("IGDB: Successfully decoded \(games.count) games.")
                    DispatchQueue.main.async { completion(games) }
                } catch {
                    print("IGDB ERROR: Failed to decode search results. Error: \(error)")
                    print("IGDB RAW RESPONSE: \(String(data: data, encoding: .utf8) ?? "Unreadable")")
                    DispatchQueue.main.async { completion([]) }
                }
            }.resume()
        }
    }
    
    func fetchAllPlatforms() async throws -> [IGDBPlatform] {
        guard let token = accessToken else {
            // Ensure we have a token first.
            // In a real app, you might want more robust error handling here.
            throw URLError(.userAuthenticationRequired)
        }
        
        var allPlatforms: [IGDBPlatform] = []
        var currentOffset = 0
        let limit = 500 // Max limit per request
        var hasMoreData = true
        
        print("Starting to fetch all platforms from IGDB...")
        
        while hasMoreData {
            let requestBody = "fields id, name; limit \(limit); offset \(currentOffset);"
            
            guard let url = URL(string: apiBaseURL + "platforms") else { throw URLError(.badURL) }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = requestBody.data(using: .utf8)
            request.setValue(self.clientId, forHTTPHeaderField: "Client-ID")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let fetchedPlatforms = try JSONDecoder().decode([IGDBPlatform].self, from: data)
            
            allPlatforms.append(contentsOf: fetchedPlatforms)
            
            if fetchedPlatforms.count < limit {
                hasMoreData = false
            } else {
                currentOffset += limit
            }
        }
        
        print("Finished fetching. Found \(allPlatforms.count) platforms.")
        return allPlatforms.sorted { $0.name < $1.name }
    }
}
