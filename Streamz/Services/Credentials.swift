import Foundation

protocol Credentials: NSCoding {
    var isExpired: Bool { get }
    var username: String? { get }
}

protocol CredentialsProvider {
    func readCredentials(_ completion: @escaping (Data?, Error?) -> Void)
    func saveCredentials(_ credentials: Data)
    func deleteCredentials()
}
