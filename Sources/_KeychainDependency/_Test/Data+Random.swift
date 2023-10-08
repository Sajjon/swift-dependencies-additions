//
//  File.swift
//  KeychainDemoTests
//
//  Created by Alexander Cyon on 2023-10-06.
//

import Foundation

extension Data {
	static func random(byteCount: Int = 8) -> Data {
		var randomNumberGenerator = SecRandomNumberGenerator()
		return Data((0 ..< byteCount).map { _ in UInt8.random(in: UInt8.min ... UInt8.max, using: &randomNumberGenerator) })
	}
}
struct SecRandomNumberGenerator: RandomNumberGenerator {
	func next() -> UInt64 {
		var bytes: UInt64 = 0
		let result = withUnsafeMutableBytes(of: &bytes, { buffer in
			SecRandomCopyBytes(kSecRandomDefault, buffer.count, buffer.baseAddress!)
		})
		
		guard result == errSecSuccess else {
			// Figure out how you'd prefer to deal with this.
			fatalError()
		}
		
		return bytes
	}
}


extension Data {
	public struct HexEncodingOptions: OptionSet {
		public let rawValue: Int
		public init(rawValue: Int) {
			self.rawValue = rawValue
		}
		static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
	}

	public func hexEncodedString(options: HexEncodingOptions = []) -> String {
		let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
		return self.map { String(format: format, $0) }.joined()
	}
}
