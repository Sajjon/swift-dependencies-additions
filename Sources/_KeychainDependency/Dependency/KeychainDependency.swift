import Dependencies
import Foundation
@_spi(Internals) import DependenciesAdditionsBasics
extension DependencyValues {
	/// A dependency that exposes an ``Keychain.Dependency`` value that you can use to read and
	/// write to `Keychain`.
	public var keychain: Keychain.Dependency {
		get { self[Keychain.Dependency.self] }
		set { self[Keychain.Dependency.self] = newValue }
	}
}

/// A type that abstract `Keychain` storage. You can use this type as it, or build your
/// own abstraction on top of it.
extension Keychain {
	public struct Dependency: Sendable {
		
		public typealias Key = Keychain.Key
		public typealias AuthenticationPrompt = Keychain.AuthenticationPrompt
		public typealias AttributesWithAuth = Keychain.AttributesWithAuth
		public typealias AttributesWithoutAuth = Keychain.AttributesWithoutAuth
		
		@_spi(Internals)
		public typealias GetWithAuth = @Sendable (
			_ key: Key,
			_ authenticationPrompt: AuthenticationPrompt,
			_ ignoringAttributeSynchronizable: Bool
		) async throws -> Data?
		
		@_spi(Internals)
		public typealias SetWithAuth =  @Sendable (
			_ data: Data?,
			_ key: Key,
			_ attributes: AttributesWithAuth,
			_ ignoringAttributeSynchronizable: Bool
		) async throws -> Void
		
		@_spi(Internals)
		public typealias GetWithoutAuth = @Sendable (
			_ key: Key,
			_ ignoringAttributeSynchronizable: Bool
		) async throws -> Data?
		
		@_spi(Internals)
		public typealias SetWithoutAuth = @Sendable (
			_ data: Data?,
			_ key: Key,
			_ attributes: AttributesWithoutAuth,
			_ ignoringAttributeSynchronizable: Bool
		) async throws -> Void
		
		@_spi(Internals)
		public typealias GetSetIfNilWithAuth = @Sendable (
			_ setIfNil: (value: Data, attributes: AttributesWithAuth),
			_ key: Key,
			_ authenticationPrompt: AuthenticationPrompt,
			_ ignoringAttributeSynchronizable: Bool
		) async throws -> (value: Data, wasNil: Bool)
		
		@_spi(Internals)
		public typealias GetSetIfNilWithoutAuth = @Sendable (
			_ setIfNil: (value: Data, attributes: AttributesWithoutAuth),
			_ key: Key,
			_ ignoringAttributeSynchronizable: Bool
		) async throws -> (value: Data, wasNil: Bool)
		
		@_spi(Internals)
		public typealias RemoveItem = @Sendable (
			_ key: Key,
			_ ignoringAttributeSynchronizable: Bool
		) async throws -> Void
		
		@_spi(Internals)
		public typealias RemoveAllItems = @Sendable () async throws -> Void
		
		@_spi(Internals)
		public typealias Events = @Sendable (_ key: Key) -> AsyncStream<Event>
		
		let _getWithAuth: GetWithAuth
		let _setWithAuth: SetWithAuth
		let _getWithoutAuth: GetWithoutAuth
		let _setWithoutAuth: SetWithoutAuth
		let _getSetIfNilWithAuth: GetSetIfNilWithAuth
		let _getSetIfNilWithoutAuth: GetSetIfNilWithoutAuth
		let _removeItem: RemoveItem
		let _removeAllItems: RemoveAllItems
		let _events: Events
		
		@_spi(Internals)
		public init(
			getWithAuth: @escaping GetWithAuth,
			getSetIfNilWithAuth: @escaping GetSetIfNilWithAuth,
			setWithAuth: @escaping SetWithAuth,

			getWithoutAuth: @escaping GetWithoutAuth,
			getSetIfNilWithoutAuth: @escaping GetSetIfNilWithoutAuth,
			setWithoutAuth: @escaping SetWithoutAuth,

			removeItem: @escaping RemoveItem,
			removeAllItems: @escaping RemoveAllItems,
			events: @escaping Events
		) {
			self._getWithAuth = getWithAuth
			self._getSetIfNilWithAuth = getSetIfNilWithAuth
			self._setWithAuth = setWithAuth
			
			self._getWithoutAuth = getWithoutAuth
			self._getSetIfNilWithoutAuth = getSetIfNilWithoutAuth
			self._setWithoutAuth = setWithoutAuth
			
			self._removeItem = removeItem
			self._removeAllItems = removeAllItems
			self._events = events
		}
		
		/// Returns the data requiring authentication associated with the specified key, using the provided authenticationPrompt
		public func dataWithAuth(
			forKey key: Key,
			authenticationPrompt: AuthenticationPrompt,
			ignoringAttributeSynchronizable: Bool = true
		) async throws -> Data? {
			try await self._getWithAuth(key, authenticationPrompt, ignoringAttributeSynchronizable)
		}

		/// Sets the value of the specified default key, which will require authentication,  configured with attributes.
		public func setDataWithAuth(
			_ data: Data?,
			forKey key: Key,
			with attributes: AttributesWithAuth,
			ignoringAttributeSynchronizable: Bool = true
		) async throws {
			try await self._setWithAuth(data, key, attributes, ignoringAttributeSynchronizable)
		}
		
		/// Returns the data, which will require authentication, associated with the specified key if present,
		/// else sets it to the specified value and returns either existing or new value with info about which value was used.
		public func getDataWithAuth(
			forKey key: Key,
			setIfNil: (value: Data, attributes: AttributesWithAuth),
			authenticationPrompt: AuthenticationPrompt,
			ignoringAttributeSynchronizable: Bool = true
		) async throws -> (value: Data, wasNil: Bool) {
			try await self._getSetIfNilWithAuth(
				setIfNil,
				key,
				authenticationPrompt,
				ignoringAttributeSynchronizable
			)
		}
		
		/// Returns the data associated with the specified key.
		public func dataWithoutAuth(
			forKey key: Key,
			ignoringAttributeSynchronizable: Bool = true
		) async throws -> Data? {
			try await self._getWithoutAuth(key, ignoringAttributeSynchronizable)
		}
		
		/// Sets the value of the specified default key, configured with attributes.
		public func setDataWithoutAuth(
			_ data: Data?, 
			forKey key: Key,
			with attributes: AttributesWithoutAuth,
			ignoringAttributeSynchronizable: Bool = true
		) async throws {
			try await self._setWithoutAuth(data, key, attributes, ignoringAttributeSynchronizable)
		}
		
		/// Returns the data associated with the specified key if present, else sets it to the specified
		/// value and returns either existing or new value with info about which value was used.
		public func getDataWithoutAuth(
			forKey key: Key,
			setIfNil: (value: Data, attributes: AttributesWithoutAuth),
			ignoringAttributeSynchronizable: Bool = true
		) async throws -> (value: Data, wasNil: Bool) {
			try await self._getSetIfNilWithoutAuth(setIfNil, key, ignoringAttributeSynchronizable)
		}
		
		/// An `AsyncStream` of events for a given `key` as they change. The stream
		/// contains `added` and `removed` events.
		/// - Parameter key: The key that references this user preference.
		/// - Returns: An `AsyncSequence` of `event` values, excluding any initial values.
		public func events(forKey key: Key) -> AsyncStream<Event> {
			self._events(key)
		}
		
		/// Removes item for `key`.
		/// - Parameters:
		///   - key: key of item to remove
		///   - ignoringAttributeSynchronizable: Specifies that both synchronizable and non-synchronizable results should be returned from a query.
		public func removeItem(
			forKey key: Key,
			ignoringAttributeSynchronizable: Bool = true
		) async throws -> Void {
			try await self._removeItem(key, ignoringAttributeSynchronizable)
		}
		
		/// Removes all items from keychain
		public func removeAllItems() async throws -> Void {
			try await self._removeAllItems()
		}
		
	}
}

extension Keychain.Dependency: DependencyKey {
	public static var liveValue: Self { .init() }
	
	/// Creates an `Keychain.Dependency` that read and writes to some Keychain service.
	/// - Parameter service: an service used to create a Keychain instance to read and write into.
	/// `service: "keychain"` is used by default.
	/// - Parameter accessGroup: A key with a value that’s a string indicating the access group the item is in.
	public init(service: String = "keychain", accessGroup: String? = nil) {
		
		/// The underyling implementation of this dependency, actor protects us from data races.
		let actor = KeychainActor(service: service, accessGroup: accessGroup)
		
		self = Keychain.Dependency { key, authenticationPrompt, ignoringAttributeSynchronizable in
			try await actor.getDataWithAuth(
				forKey: key,
				authenticationPrompt: authenticationPrompt,
				ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
			)
		} getSetIfNilWithAuth: { setIfNil, key, authenticationPrompt, ignoringAttributeSynchronizable in
			try await actor.getDataWithAuthIfPresent(
				forKey: key,
				with: setIfNil.attributes,
				elseSetTo: setIfNil.value,
				authenticationPrompt: authenticationPrompt,
				ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
			)
		} setWithAuth: { data, key, attributes, ignoringAttributeSynchronizable in
			if let data {
				try await actor.setDataWithAuth(
					data,
					forKey: key,
					with: attributes,
					ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
				)
			} else {
				try await actor.removeItem(
					forKey: key,
					ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
				)
			}
		} getWithoutAuth: { key, ignoringAttributeSynchronizable in
			try await actor.getDataWithoutAuth(
				forKey: key,
				ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
			)
		} getSetIfNilWithoutAuth: { setIfNil, key, ignoringAttributeSynchronizable in
			try await actor.getDataWithoutAuthIfPresent(
				forKey: key,
				with: setIfNil.attributes,
				elseSetTo: setIfNil.value,
				ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
			)
		} setWithoutAuth: { data, key, attributes, ignoringAttributeSynchronizable in
			if let data {
				try await actor.setDataWithoutAuth(
					data,
					forKey: key,
					with: attributes, 
					ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
				)
			} else {
				try await actor.removeItem(
					forKey: key,
					ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
				)
			}
		} removeItem: { key, ignoringAttributeSynchronizable in
			try await actor.removeItem(
				forKey: key, 
				ignoringAttributeSynchronizable: ignoringAttributeSynchronizable
			)
		} removeAllItems: {
			try await actor.removeAllItems()
		} events: { key in
			actor.events()
		}
	}
}

extension Keychain.Dependency: TestDependencyKey {
	public static let testValue: Self = {
		XCTFail(#"Unimplemented: @Dependency(\.keychain)"#)
//		return ephemeral()
		fatalError()
	}()

	/*
	public static var previewValue: Self { ephemeral() }

	/// An ephemeral ``Keychain.Dependency`` that reads from and writes to memory only.
	///
	/// It behaves similarly to a `Keychain`-backed ``Keychain.Dependency``, but without the
	/// persistance layer. This makes this value convienent for testing or SwiftUI previews.
	///
	/// Please note that the behavior can be sligtly different when storing/reading `URL`s, as
	/// `UserDefaults` normalizes `URL` values before storing them (you can check the documentation of
	/// `UserDefaults.set(:URL?:String)` for more information).
	public static func ephemeral() -> Keychain.Dependency {
		let storage = LockIsolated([String: any Sendable]())
		let continuations = LockIsolated([String: [UUID: AsyncStream<(any Sendable)?>.Continuation]]())

		return Keychain.Dependency { key, _ in
			storage.value[key]
		} set: { value, key in
			storage.withValue {
				$0[key] = value
			}
			for continuation in continuations.value[key]?.values ?? [:].values {
				continuation.yield(value)
			}
		} values: { key, _ in
			let id = UUID()
			let stream = AsyncStream((any Sendable)?.self) { streamContinuation in
				continuations.withValue {
					$0[key, default: [:]][id] = streamContinuation
				}
			}
			defer { continuations.value[key]?[id]?.yield(storage.value[key]) }
			return stream
		}
	}
	 */
}
