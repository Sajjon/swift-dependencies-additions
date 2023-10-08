import Foundation
import KeychainAccess

extension Keychain {
	
	/// An event when data is added or removed.
	public enum Event: Sendable, Hashable {
		public enum Attributes: Sendable, Hashable {
			case withAuth(Keychain.AttributesWithAuth)
			case withoutAuth(Keychain.AttributesWithoutAuth)
		}
		public struct Add: Sendable, Hashable {
			public let data: Data
			public let key: Keychain.Key
			public let attributes: Attributes
			public let ignoringAttributeSynchronizable: Bool
			public var auth: Bool {
				switch attributes {
				case .withAuth:
					return true
				case .withoutAuth: return false
				}
			}
		}
		public struct Removed: Sendable, Hashable {
			public let key: Keychain.Key
			public let ignoringAttributeSynchronizable: Bool?
		}
		case added(Add)
		case removed(Removed)
	}
}

public final actor KeychainActor {
	
	/// A wrapper around Keychain, using `https://github.com/kishikawakatsumi/KeychainAccess`
	private let keychain: KeychainAccess.Keychain
	
	/// A set of all keys that have been used on this actor. It is of course possible that keychain contains
	/// more items which has not been set via this keychain actor, if the `service` is shared, the keys
	/// of those items will note be int this set.
	///
	/// This is used internally to emit `(key, nil)` events, when `removeAllItems` is called, to
	/// emit events for all keys.
	private var keys: Set<Key>
	
	/// An async stream of values or `nil` for removals, which can be used to subscribe to updates.
	nonisolated private let stream: AsyncStream<Event>
	
	/// A continuation to yield values or `nil` on, representing events of adding data or removing data,
	/// identfied by the corresponding key of the item.
	private let continuation: AsyncStream<Event>.Continuation

	public init(service: String, accessGroup: String? = nil) {
		self.keychain = .init(service: service, accessGroup: accessGroup)
		self.keys = []
		(self.stream, self.continuation) =  AsyncStream<Event>.makeStream()
	}
}

// MARK: Public
extension KeychainActor {
	
	public typealias Key = Keychain.Key
	public typealias Event = Keychain.Event
	public typealias Label = Keychain.Label
	public typealias Comment = Keychain.Comment
	public typealias AuthenticationPrompt = Keychain.AuthenticationPrompt
}

// MARK: API - No Auth
extension KeychainActor {
	
	/// Inserts or updates data for `key` which will not require auth.
	///
	/// - Parameters:
	///   - data: data to set
	///   - key: key which identifies data
	///   - ignoringAttributeSynchronizable: Specifies that both synchronizable and non-synchronizable results should be returned from a query.
	///   - attributes: attributes of the data to insert or update.
	@_spi(Internal) public func setDataWithoutAuth(
		_ data: Data,
		forKey key: Key,
		with attributes: Keychain.AttributesWithoutAuth,
		ignoringAttributeSynchronizable: Bool = true
	) async throws {
		try await accessingKeychain {
			try $0.modifier(.init(attributes: attributes))
				.set(data, key: key, ignoringAttributeSynchronizable: ignoringAttributeSynchronizable)
			
			self.notify(added: .init(
				data: data,
				key: key,
				attributes: .withoutAuth(attributes),
				ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
			))
		}
	}
	
	
	/// Gets data that requires auth, for some `key`
	/// - Parameters:
	///   - key: key used to lookop data
	///   - ignoringAttributeSynchronizable: Specifies that both synchronizable and non-synchronizable results should be returned from a query
	/// - Returns: Data for given `key` if present, else nil.
	@_spi(Internal) public func getDataWithoutAuth(
		forKey key: Key,
		ignoringAttributeSynchronizable: Bool = true
	) async throws -> Data? {
		try await accessingKeychain {
			try $0.getData(key, ignoringAttributeSynchronizable: ignoringAttributeSynchronizable)
		}
	}
	
}

// MARK: API - Auth
extension KeychainActor {
	
	
	/// Inserts or updates `data` for `key`, given `attributes`.
	///
	/// - Parameters:
	///   - data: data to save
	///   - key: key of item to save
	///   - attributes: attributes to set on the data
	///   - ignoringAttributeSynchronizable: Specifies that both synchronizable and non-synchronizable results should be returned from a query.
	@_spi(Internal) public func setDataWithAuth(
		_ data: Data,
		forKey key: Key,
		with attributes: Keychain.AttributesWithAuth,
		ignoringAttributeSynchronizable: Bool = true
	) async throws {
		try await accessingKeychain {
			dispatchPrecondition(condition: .notOnQueue(DispatchQueue.main))
			try $0.modifier(.init(attributes: attributes))
				.set(data, key: key)
			
			self.notify(added: .init(
				data: data,
				key: key,
				attributes: .withAuth(attributes),
				ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
			))
		}
	}
	
	/// Reads out data requiring auth for some `key`, using `authenticationPrompt`.
	///
	/// - Parameters:
	///   - key: key of item to read
	///   - authenticationPrompt: message to show when authenticating user
	///   - ignoringAttributeSynchronizable: Specifies that both synchronizable and non-synchronizable results should be returned from a query.
	/// - Returns: Data for given `key` if present, else nil.
	@_spi(Internal) public func getDataWithAuth(
		forKey key: Key,
		authenticationPrompt: AuthenticationPrompt,
		ignoringAttributeSynchronizable: Bool = true
	) async throws -> Data? {
		try await accessingKeychain {
			dispatchPrecondition(condition: .notOnQueue(DispatchQueue.main))
			return try $0.modifier(.init(authPrompt: authenticationPrompt))
				.getData(key, ignoringAttributeSynchronizable: ignoringAttributeSynchronizable)
		}
	}

}

// MARK: API - Remove
extension KeychainActor {
	
	/// Removes item for `key`.
	/// - Parameters:
	///   - key: key of item to remove
	///   - ignoringAttributeSynchronizable: Specifies that both synchronizable and non-synchronizable results should be returned from a query.
	@_spi(Internal) public func removeItem(
		forKey key: Key,
		ignoringAttributeSynchronizable: Bool = true
	) async throws {
		try await accessingKeychain {
			try $0.remove(
				key,
				ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
			)
			self.notify(removed: .init(
				key: key,
				ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
			))
		}
	}
	
	/// Removes all items from keychain.
	@_spi(Internal) public func removeAllItems() async throws {
		try await accessingKeychain {
			try $0.removeAll()
			for key in self.keys {
				self.notify(removed: .init(
					key: key,
					ignoringAttributeSynchronizable: nil
				))
			}
		}
	}
	
	@_spi(Internal) public nonisolated func events() -> AsyncStream<Event> {
		stream
	}
}

private extension KeychainActor {
	func accessingKeychain<T>(
		_ accessingKeychain: @escaping (KeychainAccess.Keychain) throws -> T
	) async throws -> T {
		try accessingKeychain(self.keychain)
	}
	
	func notify(added: Event.Add) {
		keys.insert(added.key) // noop if present
		continuation.yield(.added(added))
	}
	
	func notify(removed: Event.Removed) {
		keys.remove(removed.key) // noop if present
		continuation.yield(.removed(removed))
	}
}
