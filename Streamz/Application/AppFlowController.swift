import UIKit
import OAuthSwift

/// Root flow controller, where all user stories begin
final class AppFlowController {
    
    private(set) var window: UIWindow!
    
    lazy private(set) var authViewController: AuthViewController! = {
        // In production I would use code generator for app resources, personally I prefer R.swift
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "AuthViewController") as! AuthViewController
    }()
    
    lazy private(set) var streamViewController: StreamViewController! = {
        let storyboard = UIStoryboard(name: "Stream", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "StreamViewController") as! StreamViewController
    }()
    
    let authService: AuthService
    let streamService: StreamService
    
    init(authService: AuthService, streamService: StreamService) {
        self.authService = authService
        self.streamService = streamService
    }
    
    func showAuth(window: UIWindow) {
        authViewController.authService = authService
        authViewController.flowController = self
        window.rootViewController = authViewController
        self.window = window
    }
    
    func showStream(window: UIWindow) {
        streamViewController.streamService = streamService
        window.rootViewController = streamViewController
        self.window = window
    }
    
}

protocol AuthFlowController: class {
    func authorised()
}

/// In real life app there should be a single flow controller per user story
extension AppFlowController: AuthFlowController {
    
    func authorised() {
        showStream(window: window)
    }
    
}
