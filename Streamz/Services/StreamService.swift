import Foundation

struct Tweet {
    let username: String
    let text: String
    let createdAt: Date
    
    enum Keys {
        static let username     = "user.screen_name"
        static let text         = "text"
        static let createdAt    = "created_at"
    }
    
    static let dateFormat = "EEE MMM d HH:mm:ss Z yyyy"
    
    init?(json: Any?) throws {
        self.init(
            username:   try json.get(Keys.username),
            text:       try json.get(Keys.text),
            createdAt:  try json.date(Keys.createdAt, format: Tweet.dateFormat)
        )
    }
    
    init(username: String, text: String, createdAt: Date) {
        self.username = username
        self.text = text
        self.createdAt = createdAt
    }
}

protocol StreamService {
    func startStream(keywords: [String], progress: @escaping (Tweet?, Error?) -> Void)
    func stopStream()
}
