import Foundation
import OAuthSwift

class OAuthSwiftStreamService: StreamService {
    
    private(set) var stream: StreamRequest?
    let oauth: OAuthSwift
    
    init(oauth: OAuthSwift) {
        self.oauth = oauth
    }
    
    func startStream(keywords: [String], progress: @escaping (Tweet?, Error?) -> Void) {
        stopStream()
        
        stream = StreamRequest(progress: { (json, error) in
            guard json != nil else {
                progress(nil, error)
                return
            }
            
            do {
                let tweet = try Tweet(json: json)
                progress(tweet, nil)
            }
            catch {
                progress(nil, error)
            }
        })
        stream?.start(client: oauth.client, track: keywords)
    }
    
    func stopStream() {
        stream?.cancel()
        stream = nil
    }
    
}

/// Handles data stream via URLSessionDataDelegate
class StreamRequest: NSObject, URLSessionDataDelegate, OAuthSwiftRequestHandle {
    
    let progress: (Any?, Error?) -> Void
    private(set) var request: OAuthSwiftRequestHandle?
    
    var response: HTTPURLResponse!
    var responseData: Data = Data()
    
    init(progress: @escaping (Any?, Error?) -> Void) {
        self.progress = progress
        super.init()
    }
    
    func start(client: OAuthSwiftClient, track: [String]) {
        client.sessionFactory.delegate = self
        var components = URLComponents(string: "https://stream.twitter.com/1.1/statuses/filter.json")!
        components.queryItems = [URLQueryItem(name: "track", value: track.joined(separator: ","))]
        request = client.post(components.url!.absoluteString, success: { (resp) in
            self.progress(resp, nil)
        }, failure: { (error) in
            self.progress(nil, error)
        })
    }
    
    func cancel() {
        request?.cancel()
    }
    
    // MARK: - URLSessionDataDelegate

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.responseData.append(data)
        
        guard !data.isEmpty else { return }

        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            progress(json, nil)
        } else {
            let jsonString = String(data: data, encoding: .utf8)
            let jsonChunks = jsonString!.components(separatedBy: "\r\n")
            let chunks = jsonChunks.filter({ !$0.utf8.isEmpty }).flatMap({ $0.data(using: .utf8) })
            guard !chunks.isEmpty else { return }
            
            for chunkData in chunks {
                guard let jsonResult = try? JSONSerialization.jsonObject(with: chunkData, options: []) else { continue }
                progress(jsonResult, nil)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response as? HTTPURLResponse
        self.responseData.count = 0
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let request = self.request as? OAuthSwiftHTTPRequest
        request?.completeRequest(successHandler: { self.progress($0, nil) },
                                 failureHandler: { self.progress(nil, $0) },
                                 data: responseData, response: response, error: error)
    }
    
}
