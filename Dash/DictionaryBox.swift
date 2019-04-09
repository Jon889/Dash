//
//  DictionaryBox.swift
//  Dash
//
//  Created by Jonathan Bailey on 09/04/2019.
//  Copyright © 2019 jonathan. All rights reserved.
//

import Foundation

protocol DictionaryProvider {
	var dictionary: [String: Any] { get }
}

@dynamicCallable
class DictionaryBox<Keys: RawRepresentable>: DictionaryProvider, ExpressibleByDictionaryLiteral where Keys.RawValue == String {
	
	let dictionary: [String : Any]
	
	required init(dictionaryLiteral elements: (Keys, Any)...) {
		self.dictionary = Dictionary(uniqueKeysWithValues: elements.map { ($0.0.rawValue, $0.1) })
	}
	init(dictionary: [String: Any]) {
		self.dictionary = dictionary
	}
	
	func get<T>(_ key: Keys) throws -> T {
		guard let unTypedValue = dictionary[key.rawValue] else {
			throw MissingKeyError(key: key.rawValue)
		}
		guard let value = unTypedValue as? T else {
			throw ValueIncorrectTypeError(key: key.rawValue, expectedType: String(describing: T.self), actualType: String(describing: type(of: unTypedValue)))
		}
		return value
	}
	
	
	// Can't use generics because https://bugs.swift.org/browse/SR-10313
	func dynamicallyCall(withArguments args: [Keys]) throws -> String {
		return try get(args[0])
	}
	
	func dynamicallyCall(withArguments args: [Keys]) throws -> CGFloat {
		return try get(args[0])
	}
	
	func dynamicallyCall(withArguments args: [Keys]) throws -> Bool {
		return try get(args[0])
	}
	
	func dynamicallyCall(withArguments args: [Keys]) throws -> [String: Any] {
		return try get(args[0])
	}
	
	func dynamicallyCall(withArguments args: [Keys]) throws -> [[String: Any]] {
		return try get(args[0])
	}
	
	func dynamicallyCall(withArguments args: [Keys]) throws -> TimeInterval {
		return try get(args[0])
	}
	
	// Convenience
	
	func dynamicallyCall(withArguments args: [Keys]) throws -> URL {
		let key = args[0]
		let urlString: String = try get(key)
		guard let url = URL(string: urlString) else {
			throw InvalidValueError(key: key.rawValue, message: "Unable to create url from \(urlString)")
		}
		return url
	}
}
