import Foundation

extension Optional {
    
    /// Gets generic value by key paths.
    /// - throws : JSONError.invalidType if value at key path can not be converted to generic type
    public func get<T>(_ keyPaths: String...) throws -> T {
        return try get({ $0 as? T }, keyPaths: keyPaths)
    }
    
    /// Gets generic value by key paths array using provided getter closure
    /// - throws : JSONError.invalidType if getter returns nil
    public func get<T>(_ getter: (Any?) throws -> T?, keyPaths: [String]) throws -> T {
        let keyPaths = normalize(keyPaths)
        let keyPathValue = self.keyPaths(keyPaths)
        guard let _ = keyPathValue else {
            throw JSONError.noData(keyPaths: keyPaths, expectedType: String(describing: T.self), value: nil)
        }
        guard let value = try getter(keyPathValue) else {
            throw JSONError.invalidType(keyPaths: keyPaths, expectedType: String(describing: T.self), value: self)
        }
        return value
    }
    
    public func date(_ keyPaths: String..., format: String) throws -> Date {
        dateFormatter.dateFormat = format
        return try get({ ($0 as? String).flatMap({ dateFormatter.date(from: $0) }) }, keyPaths: keyPaths)
    }
    
}

let dateFormatter = DateFormatter()

extension Optional {
    
    /// If value is array will get it's item by index
    public subscript(index index: Int) -> Any? {
        let array = self as? [Any]
        return array?[safe: index]
    }
    
    /// If value is object will get it's item by key
    public subscript(keyPath keyPath: String) -> Any? {
        let object = self as? [String: Any]
        return object?[keyPath]
    }
    
    /// Analog of `valueForKeyPath:` in NSDictionary
    /// Key paths can be strings or numeric strings.
    /// If key is string and value is dictionary will get value by this key.
    /// If key is numeric string and value is array will get it's item by index
    public subscript(keyPaths: String...) -> Any? {
        return self.keyPaths(normalize(keyPaths))
    }
    
    fileprivate func keyPaths(_ keyPaths: [String]) -> Any? {
        guard !keyPaths.isEmpty else {
            return self
        }
        
        let keyPath = keyPaths.first!
        let value: Any?
        
        if let index = Int(keyPath) {
            value = self[index: index]
        } else {
            value = self[keyPath: keyPath]
        }
        
        return value.keyPaths(Array(keyPaths.suffix(from: 1)))
    }
}

extension Collection where Self.Index: Comparable {
    public subscript(safe index: Index) -> Iterator.Element? {
        return startIndex..<endIndex ~= index ? self[index] : nil
    }
}

private func normalize(_ keyPaths: [String]) -> [String] {
    return keyPaths.flatMap({ $0.components(separatedBy: ".") })
}


enum JSONError: Error {
    
    case invalidType(keyPaths: [String], expectedType: String, value: Any?)
    case noData(keyPaths: [String], expectedType: String, value: Any?)
    
}
