import XCTest
@testable import Streamz
import OAuthSwift

class StreamRequestTests: XCTestCase {
    
    func testThatStreamRequestRecievesData() {
        //given
        let expectedJson: [String: String] = ["key": "value"]
        let data = try! JSONSerialization.data(withJSONObject: expectedJson, options: [])

        //then
        let sut = StreamRequest(progress: { json, error in
            XCTAssertNotNil(json as? [String: String])
            if let json = json as? [String: String] {
                XCTAssertEqual(json, expectedJson)
            }
        })
        
        //when
        sut.urlSession(URLSession.shared, dataTask: URLSessionDataTask(), didReceive: data)
    }
    
    func testThatStreamRequestRecievesChunkedData() {
        //given
        let expectedJson1: [String: String] = ["key1": "value1"]
        let expectedJson2: [String: String] = ["key2": "value2"]
        let data1 = try! JSONSerialization.data(withJSONObject: expectedJson1, options: [])
        let data2 = try! JSONSerialization.data(withJSONObject: expectedJson2, options: [])
        
        let string1 = String(data: data1, encoding: .utf8)!
        let string2 = String(data: data2, encoding: .utf8)!
        
        let string = "\(string1)\r\n\(string2)"
        let data = string.data(using: .utf8)!
        
        var expectedJsons = [expectedJson1, expectedJson2]
        
        //then
        let sut = StreamRequest(progress: { json, error in
            XCTAssertNotNil(json as? [String: String])
            if let json = json as? [String: String] {
                let expectedJson = expectedJsons.removeFirst()
                XCTAssertEqual(json, expectedJson)
            }
        })
        
        //when
        sut.urlSession(URLSession.shared, dataTask: URLSessionDataTask(), didReceive: data)
    }
    
    func testThatItBuildsCorrectRequest() {
        let sut = StreamRequest(progress: { _ in })
        
        let track = ["swift", "iosdev"]
        sut.start(client: OAuthSwiftClient(consumerKey: "", consumerSecret: ""), track: track)
        let request = sut.request as! OAuthSwiftHTTPRequest
        sut.cancel()
        
        XCTAssertEqual(request.request?.url?.absoluteString, "https://stream.twitter.com/1.1/statuses/filter.json?track=swift,iosdev")
    }
}
