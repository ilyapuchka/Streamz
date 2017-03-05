import UIKit

struct TweetViewModel {
    static let dateFormatter = DateFormatter()
    static let dateFormat = "HH:mm MMM d yyyy"
    
    let text: NSAttributedString
    let detailedText: String?
    
    init(tweet: Tweet) {
        let username = NSAttributedString(string: "@\(tweet.username)", attributes: [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)
            ])
        let text = NSMutableAttributedString()
        text.append(username)
        text.append(NSAttributedString(string: ": \(tweet.text)"))
        self.text = text
        
        TweetViewModel.dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: TweetViewModel.dateFormat, options: 0, locale: Locale.current)
        self.detailedText = TweetViewModel.dateFormatter.string(from: tweet.createdAt)
    }
}

struct TweetStreamViewModel {
    
    private(set) var tweets: [TweetViewModel] = []
    let capacity: Int
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    mutating func append(tweet: Tweet, onInsert: (Int) -> Void, onDelete: (Int) -> Void) {
        var tweets = self.tweets
        if tweets.count == capacity {
            tweets.removeLast()
            onDelete(capacity - 1)
        }
        tweets.insert(TweetViewModel(tweet: tweet), at: 0)
        onInsert(0)
        self.tweets = tweets
    }
    
    var count: Int {
        return tweets.count
    }
    
    subscript(_ index: Int) -> TweetViewModel {
        return tweets[index]
    }
    
}
