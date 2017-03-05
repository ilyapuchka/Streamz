import UIKit

class TweetCell: UITableViewCell, Reusable {
    
    static let reuseIdentifier = "TweetCell"
    
    override func layoutSubviews() {
        textLabel?.numberOfLines = 0
        super.layoutSubviews()
    }
    
    func update(with model: TweetViewModel) {
        textLabel?.attributedText = model.text
        detailTextLabel?.text = model.detailedText
    }
    
}
