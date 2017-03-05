import XCTest
@testable import Streamz

class TweetViewModelTests: XCTestCase {
    
    func testTextIsSetProperly() {
        //given
        let tweet = Tweet(username: "me", text: "my tweet", createdAt: Date())
        
        let username = NSAttributedString(string: "@\(tweet.username)", attributes: [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)
            ])
        let expectedText = NSMutableAttributedString()
        expectedText.append(username)
        expectedText.append(NSAttributedString(string: ": \(tweet.text)"))
        
        //then
        XCTAssertEqual(TweetViewModel(tweet: tweet).text, expectedText)
    }
    
    func testDetailedTextIsSetProperly() {
        //given
        let now = Date()
        let tweet = Tweet(username: "me", text: "my tweet", createdAt: now)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "HH:mm MMM d yyyy", options: 0, locale: Locale.current)
        let expectedCreatedAt = dateFormatter.string(from: tweet.createdAt)
        
        XCTAssertEqual(TweetViewModel(tweet: tweet).detailedText, expectedCreatedAt)
    }

}

class TweetStreamViewModelTests: XCTestCase {
    
    func testThatItAddsItemsToMaxCapacity() {
        //given
        let tweet1 = Tweet(username: "", text: "1", createdAt: Date())
        let tweet2 = Tweet(username: "", text: "2", createdAt: Date())
        var sut = TweetStreamViewModel(capacity: 1)
        
        var onInsertCalled = false
        var onDeleteCalled = false
        
        //when
        sut.append(tweet: tweet1, onInsert: {_ in onInsertCalled = true }, onDelete: {_ in onDeleteCalled = true })
        
        //then
        XCTAssertEqual(sut.count, 1)
        XCTAssertTrue(onInsertCalled)
        XCTAssertFalse(onDeleteCalled)
        
        onInsertCalled = false
        onDeleteCalled = false

        //and when
        sut.append(tweet: tweet2, onInsert: {_ in onInsertCalled = true }, onDelete: {_ in onDeleteCalled = true })
        
        //then
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut[0].text, TweetViewModel(tweet: tweet2).text)
        XCTAssertTrue(onInsertCalled)
        XCTAssertTrue(onDeleteCalled)
    }
    
}
