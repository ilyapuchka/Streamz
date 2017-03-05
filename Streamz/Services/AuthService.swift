import Foundation

// Handles actual authorisation on lower level than service,
// defines a boundary between the app and 3rd party dependency used for implementation
protocol AuthProvider {
    func restoreSession(with credentials: Credentials)
    func authorize(_ completion: @escaping (Credentials?, Error?) -> Void)
    func handle(url: URL) -> Bool
}

// Service that handles authorisation on highest level 
// + additional business logic around it, like restoring previous session
final class AuthService {
    
    let oauthProvider: AuthProvider
    let userDefaults: UserDefaults
    let credentialsProvider: CredentialsProvider
    
    static let authorsedKey = "streamz.authorised"
    
    init(oauth: AuthProvider, userDefaults: UserDefaults, credentialsProvider: CredentialsProvider) {
        self.oauthProvider = oauth
        self.userDefaults = userDefaults
        self.credentialsProvider = credentialsProvider
        userDefaults.register(defaults: [AuthService.authorsedKey: false])
    }
    
    func restoreSession(_ completion: @escaping (Credentials?) -> Void) {
        guard userDefaults.bool(forKey: AuthService.authorsedKey) else {
            // Because callbacks should be either sync, or async, not both
            // https://blog.ometer.com/2011/07/24/callbacks-synchronous-and-asynchronous/
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        credentialsProvider.readCredentials({ (credentials, _) in
            DispatchQueue.main.async {
                if let credentials = credentials.map(NSKeyedUnarchiver.unarchiveObject(with:)) as? Credentials,
                    !credentials.isExpired
                {
                    self.oauthProvider.restoreSession(with: credentials)
                    completion(credentials)
                } else {
                    self.credentialsProvider.deleteCredentials()
                    self.userDefaults.set(false, forKey: AuthService.authorsedKey)
                    self.userDefaults.synchronize()
                    completion(nil)
                }
            }
        })
    }
    
    func authorise(completion: @escaping (Credentials?, Error?) -> Void) {
        credentialsProvider.deleteCredentials()
        oauthProvider.authorize { credentials, error in
            DispatchQueue.main.async {
                guard let credentials = credentials else {
                    completion(nil, error)
                    return
                }
                
                self.userDefaults.set(true, forKey: AuthService.authorsedKey)
                self.userDefaults.synchronize()
                self.credentialsProvider.saveCredentials(NSKeyedArchiver.archivedData(withRootObject: credentials))
                completion(credentials, nil)
            }
        }
    }
    
    func handle(url: URL) -> Bool {
        return oauthProvider.handle(url: url)
    }
    
}
