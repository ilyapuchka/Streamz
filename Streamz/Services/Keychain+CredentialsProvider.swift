import Foundation

class KeychainCredentialsProvider: CredentialsProvider {
    
    let passwordItem: KeychainPasswordItem
    private let queue = DispatchQueue(label: "KeychainCredentialsProvider")
    
    init(passwordItem: KeychainPasswordItem) {
        self.passwordItem = passwordItem
    }
    
    func readCredentials(_ completion: @escaping (Data?, Error?) -> Void) {
        queue.async {
            do {
                print("Reading credentials")
                let password = try self.passwordItem.readPassword()
                print("Credentials were successfully read")
                completion(password, nil)
            } catch {
                print("Error reading stored credentials: \(error)")
                completion(nil, error)
            }
        }
    }
    
    func saveCredentials(_ credentials: Data) {
        // read-write lock ensure that no reads happen during writes
        queue.async(flags: .barrier) {
            do {
                print("Saving credentials")
                try self.passwordItem.savePassword(credentials)
                print("Credentials were successfully saved")
            } catch {
                print("Error saving credentials: \(error)")
            }
        }
    }
    
    func deleteCredentials() {
        queue.async(flags: .barrier) {
            do {
                print("Deleting credentials")
                try self.passwordItem.deleteItem()
                print("Credentials were successfully deleted")
            } catch {
                print("Error deleting stored credentials: \(error)")
            }
        }
    }
    
}
