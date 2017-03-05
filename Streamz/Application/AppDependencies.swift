import Foundation
import OAuthSwift

class AppDependencies {
    
    let authService: AuthService
    let streamService: StreamService
    let flowController: AppFlowController
    
    init() {
        // I'm using OAuthSwift library as a Twitter API client as I beleive the last thing developers should do today
        // is to implement OAuth protocol from scratch (I had lots of fun with it in the past though when there were no such solutions).
        // Though it does not dismiss need to understand a protocol itself.
        
        let oauthswift = OAuth1Swift(
            consumerKey:        "NWMrdVQhOvLx9cuHYavBSilYU",
            consumerSecret:     "oSmlRFepP0LurmuKeOAkr8VRySobY1MkhkHkuPBN0ntNSf7A8y",
            requestTokenUrl:    "https://api.twitter.com/oauth/request_token",
            authorizeUrl:       "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:     "https://api.twitter.com/oauth/access_token"
        )
        
        let oauth = OAuthSwiftProvider(callbackURL: URL(string: "streamz://auth")!, oauth: oauthswift)
        let keychainItem = KeychainPasswordItem(service: "ilya.puchka.streamz", account: "twitter")
        let keychain = KeychainCredentialsProvider(passwordItem: keychainItem)
        
        authService = AuthService(oauth: oauth, userDefaults: UserDefaults.standard, credentialsProvider: keychain)
        /// make both services to use the same oauth client so that they share its state (credentials)
        streamService = OAuthSwiftStreamService(oauth: oauthswift)
        
        flowController = AppFlowController(authService: authService, streamService: streamService)
        
        oauthswift.authorizeURLHandler = SafariURLHandler(viewController: flowController.authViewController, oauthSwift: oauthswift)
    }
    
}
