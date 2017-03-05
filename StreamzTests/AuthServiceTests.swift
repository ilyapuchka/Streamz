import XCTest
@testable import Streamz

class MockCredentials: NSObject, NSCoding, Credentials {
    let isExpired: Bool
    let username: String?
    
    init(isExpired: Bool, username: String? = nil) {
        self.isExpired = isExpired
        self.username = username
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.isExpired = aDecoder.decodeBool(forKey: "isExpired")
        self.username = aDecoder.decodeObject(forKey: "username") as? String
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(isExpired, forKey: "isExpired")
        aCoder.encode(username, forKey: "username")
    }
}

class MockAuthProvider: AuthProvider {
    
    var restoreSessionCalledWithCredentials: Credentials?
    var handleURL = false
    var authCredentials: Credentials?
    
    func restoreSession(with credentials: Credentials) {
        restoreSessionCalledWithCredentials = credentials
    }
    
    func authorize(_ completion: @escaping (Credentials?, Error?) -> Void) {
        DispatchQueue.main.async {
            completion(self.authCredentials, nil)
        }
    }
    
    var handleURLCalledWithURL: URL?
    
    func handle(url: URL) -> Bool {
        handleURLCalledWithURL = url
        return handleURL
    }

}

class MockCredentialsProvider: CredentialsProvider {
    
    var readCredentialsResponse: (Data?, Error?) = (nil, nil)
    
    func readCredentials(_ completion: @escaping (Data?, Error?) -> Void) {
        completion(readCredentialsResponse.0, readCredentialsResponse.1)
    }
    
    var saveCredentialsCalledWithCredentials: Data?
    
    func saveCredentials(_ credentials: Data) {
        saveCredentialsCalledWithCredentials = credentials
    }
    
    var deleteCredentialsCalled = false
    
    func deleteCredentials() {
        deleteCredentialsCalled = true
    }
}

class AuthServiceTests: XCTestCase {
    
    var userDefaults = UserDefaults(suiteName: String(describing: AuthServiceTests.self))!
    
    override func setUp() {
        userDefaults.register(defaults: [AuthService.authorsedKey: false])
        userDefaults.removeObject(forKey: AuthService.authorsedKey)
    }
    
    func testThatItDoesNotRestoresSessionIfNotNeeded() {
        //given
        let sut = AuthService(oauth: MockAuthProvider(), userDefaults: userDefaults, credentialsProvider: MockCredentialsProvider())

        //expect
        let exp = expectation(description: "session restored")
        sut.restoreSession { (cred) in
            XCTAssertNil(cred)
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }
    
    func testThatItDoesNotRestoreSessionIfNoCredentialsStored() {
        //given
        userDefaults.set(true, forKey: AuthService.authorsedKey)
        
        let sut = AuthService(oauth: MockAuthProvider(), userDefaults: userDefaults, credentialsProvider: MockCredentialsProvider())
        
        //expect
        let exp = expectation(description: "session restored")
        sut.restoreSession { (cred) in
            XCTAssertNil(cred)
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }
    
    func testThatItDoesNotRestoreSessionWithExpiredCredentials() {
        //given
        userDefaults.set(true, forKey: AuthService.authorsedKey)

        let credentials = MockCredentials(isExpired: true, username: nil)
        let credentialsData = NSKeyedArchiver.archivedData(withRootObject: credentials)
        
        let credentialsProvider = MockCredentialsProvider()
        credentialsProvider.readCredentialsResponse = (credentialsData, nil)
        
        let sut = AuthService(oauth: MockAuthProvider(), userDefaults: userDefaults, credentialsProvider: credentialsProvider)
        
        //expect
        let exp = expectation(description: "session restored")
        sut.restoreSession { (cred) in
            XCTAssertNil(cred)
            XCTAssertTrue(credentialsProvider.deleteCredentialsCalled)
            XCTAssertFalse(self.userDefaults.bool(forKey: AuthService.authorsedKey))
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }

    func testThatItRestoresSessionWithValidCredentials() {
        //given
        userDefaults.set(true, forKey: AuthService.authorsedKey)
        
        let credentials = MockCredentials(isExpired: false, username: nil)
        let credentialsData = NSKeyedArchiver.archivedData(withRootObject: credentials)
        let authProvider = MockAuthProvider()
        
        let credentialsProvider = MockCredentialsProvider()
        credentialsProvider.readCredentialsResponse = (credentialsData, nil)

        let sut = AuthService(oauth: authProvider, userDefaults: userDefaults, credentialsProvider: credentialsProvider)
        
        //expect
        let exp = expectation(description: "session restored")
        sut.restoreSession { (cred) in
            XCTAssertNotNil(cred)
            XCTAssertNotNil(authProvider.restoreSessionCalledWithCredentials)
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }
    
    func testThatItAuthorises() {
        //given
        let authProvider = MockAuthProvider()
        authProvider.authCredentials = MockCredentials(isExpired: false)
        
        let credentialsProvider = MockCredentialsProvider()
        let sut = AuthService(oauth: authProvider, userDefaults: userDefaults, credentialsProvider: credentialsProvider)
        
        //expect
        let exp = expectation(description: "authorised")
        sut.authorise { (cred, error) in
            XCTAssertNotNil(cred)
            XCTAssertTrue(self.userDefaults.bool(forKey: AuthService.authorsedKey))
            XCTAssertEqual(credentialsProvider.saveCredentialsCalledWithCredentials, NSKeyedArchiver.archivedData(withRootObject: cred!))
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }
    
    func testThatItHandlesURL() {
        //given
        let authProvider = MockAuthProvider()
        
        let sut = AuthService(oauth: authProvider, userDefaults: userDefaults, credentialsProvider: MockCredentialsProvider())
        let url = URL(string: "http://google.com")!
        
        //then
        authProvider.handleURL = false
        XCTAssertFalse(sut.handle(url: url))
        
        authProvider.handleURL = true
        XCTAssertTrue(sut.handle(url: url))
        
        XCTAssertEqual(authProvider.handleURLCalledWithURL, url)
    }
}
