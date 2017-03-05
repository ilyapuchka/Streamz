import Foundation
import OAuthSwift

class OAuthCredentials: NSObject, NSCoding, Credentials {
    
    let credential: OAuthSwiftCredential
    let parameters: [String: Any]
    
    enum Keys {
        static let credential = "credential"
        static let parameters = "parameters"
        static let screenName = "screen_name"
    }
    
    init(credential: OAuthSwiftCredential, parameters: [String: Any]) {
        self.credential = credential
        self.parameters = parameters
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard
            let credential = aDecoder.decodeObject(forKey: Keys.credential) as? OAuthSwiftCredential,
            let parameters = aDecoder.decodeObject(forKey: Keys.parameters) as? [String : Any] else {
                return nil
        }
        self.credential = credential
        self.parameters = parameters
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(credential, forKey: Keys.credential)
        aCoder.encode(parameters, forKey: Keys.parameters)
    }
    
    var isExpired: Bool {
        return credential.isTokenExpired()
    }
    
    var username: String? {
        return parameters[Keys.screenName] as? String
    }
    
}

/// Implementation of auth provider based on OAuthSwift library
class OAuthSwiftProvider: AuthProvider {
    
    let callbackURL: URL
    let oauth: OAuth1Swift
    
    init(callbackURL: URL, oauth: OAuth1Swift) {
        self.callbackURL = callbackURL
        self.oauth = oauth
    }
    
    func authorize(_ completion: @escaping (Credentials?, Error?) -> Void) {
        oauth.authorize(withCallbackURL: callbackURL, success: { credential, _, parameters in
            completion(OAuthCredentials(credential: credential, parameters: parameters), nil)
        }, failure: {
            completion(nil, $0)
        })
    }
    
    func restoreSession(with credentials: Credentials) {
        guard let credentials = credentials as? OAuthCredentials else { return }
        let client = OAuthSwiftClient(credential: credentials.credential)
        oauth.client = client
    }
    
    func handle(url: URL) -> Bool {
        guard url.host == callbackURL.host else { return false }
        OAuthSwift.handle(url: url)
        return true
    }
    
}
