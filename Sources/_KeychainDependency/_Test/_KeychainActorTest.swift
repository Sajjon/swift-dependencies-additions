//
//  KeychainActor+RandomData.swift
//  DummyHost
//
//  Created by Alexander Cyon on 2023-10-07.
//

import Foundation
import KeychainAccess

extension Keychain.Dependency {
	
	
	@MainActor
	@discardableResult
	@_spi(Internal) public func authGetSavedDataElseSaveNewRandom(
		key: String
	) async throws -> Data {
		try await getDataWithAuth(
			forKey: key,
			setIfNil: (.random(), attributes: AttributesWithAuth(
				accessibility: .whenUnlockedThisDeviceOnly,
				authenticationPolicy: .biometryAny)
			),
			authenticationPrompt: "Keychain demo"
		).value
	}
	
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
		try await getDataWithoutAuth(
			forKey: key,
			setIfNil: (.random(), attributes: Keychain.AttributesWithoutAuth())
		).value
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
		).value
		
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
		).value
	}
}
