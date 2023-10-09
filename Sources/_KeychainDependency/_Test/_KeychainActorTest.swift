//
//  KeychainActor+RandomData.swift
//  DummyHost
//
//  Created by Alexander Cyon on 2023-10-07.
//

import Foundation
import KeychainAccess

extension KeychainActor {
	
	@discardableResult
	@_spi(Internal) public func getDataWithAuthIfPresent(
		forKey key: Key,
		with attributes: Keychain.AttributesWithAuth,
		elseSetTo new: Data,
		authenticationPrompt: AuthenticationPrompt
	) async throws -> (data: Data, foundExisting: Bool) {
		if let value = try await getDataWithAuth(
			forKey: key,
			authenticationPrompt: authenticationPrompt
		) {
			return (value, foundExisting: true)
		} else {
			try await setDataWithAuth(
				new,
				forKey: key,
				with: attributes
			)
			return (new, foundExisting: false)
		}
	}
	
	@discardableResult
	@_spi(Internal) public func getDataWithoutAuthIfPresent(
		forKey key: Key,
		with attributes: Keychain.AttributesWithoutAuth,
		elseSetTo new: Data
	) async throws -> (data: Data, foundExisting: Bool) {
		if let value = try await getDataWithoutAuth(
			forKey: key
		) {
			return (value, foundExisting: true)
		} else {
			try await setDataWithoutAuth(
				new,
				forKey: key,
				with: attributes
			)
			return (new, foundExisting: false)
		}
	}
}

extension KeychainActor {
		
	// We dont "want" `MainActor`, but we have it here to assert that
	// the KeychainActor correctly runs its methods (actor isolated)
	// on a different thread than main thread, since all AUTH operation
	// must NOT be run on main thread.
	@MainActor
	@discardableResult
	@_spi(Internal) public func authGetSavedDataElseSaveNewRandom(
		key: String
	) async throws -> Data {
		try await getDataWithAuthIfPresent(
			forKey: key,
			with: .init(accessibility: .whenUnlockedThisDeviceOnly, authenticationPolicy: .biometryAny),
			elseSetTo: .random(),
			authenticationPrompt: "Keychain demo"
		).data
		
	}
}

extension KeychainActor {
	
	// We dont "want" `MainActor`, but we have it here to assert that
	// the KeychainActor correctly runs its methods (actor isolated)
	// on a different thread than main thread, since all AUTH operation
	// must NOT be run on main thread, and even though this is using
	// the `withoutAuth` variant, we could read/write with auth in between.
	@MainActor
	@discardableResult
	@_spi(Internal) public func noAuthGetSavedDataElseSaveNewRandom(
		key: String
	) async throws -> Data {
		try await getDataWithoutAuthIfPresent(
			forKey: key,
			with: Keychain.AttributesWithoutAuth(),
			elseSetTo: .random()
		).data
	}
}
