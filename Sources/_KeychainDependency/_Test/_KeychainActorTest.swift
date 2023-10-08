//
//  KeychainActor+RandomData.swift
//  DummyHost
//
//  Created by Alexander Cyon on 2023-10-07.
//

import Foundation
import KeychainAccess

let authRandomKey = "authRandomDataKey"
let noAuthRandomKey = "noAuthRandomDataKey"

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
		
	@MainActor
	@discardableResult
	@_spi(Internal) public func authGetSavedDataElseSaveNewRandom() async throws -> Data {
		try await getDataWithAuthIfPresent(
			forKey: authRandomKey,
			with: .init(accessibility: .whenUnlockedThisDeviceOnly, authenticationPolicy: .biometryAny),
			elseSetTo: .random(),
			authenticationPrompt: "Keychain demo"
		).data
		
	}
}

extension KeychainActor {
	
	@MainActor
	@discardableResult
	@_spi(Internal) public func noAuthGetSavedDataElseSaveNewRandom() async throws -> Data {
		try await getDataWithoutAuthIfPresent(
			forKey: noAuthRandomKey,
			with: Keychain.AttributesWithoutAuth(),
			elseSetTo: .random()
		).data
	}
}
