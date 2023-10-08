//
//  KeychainAttributes.swift
//  KeychainDemoTests
//
//  Created by Alexander Cyon on 2023-10-07.
//

import Foundation
import KeychainAccess

extension KeychainAccess.Accessibility: @unchecked Sendable {}
extension KeychainAccess.AuthenticationPolicy: @unchecked Sendable {}
extension KeychainAccess.AuthenticationPolicy: Hashable {}

extension KeychainAccess.Keychain {
	func withAttributes(
		label: String?,
		comment: String?,
		isSynchronizable: Bool?,
		accessibility: KeychainAccess.Accessibility?,
		authenticationPolicy: KeychainAccess.AuthenticationPolicy?
	) -> KeychainAccess.Keychain {
		assert(!(authenticationPolicy != nil && accessibility == nil), "Specifying `authenticationPolicy` has no effect if you are not also specifying `accessibility`.")
		var keychain = self
		if let label {
			keychain = keychain.label(label)
		}
		if let comment {
			keychain = keychain.comment(comment)
		}
		if let isSynchronizable {
			keychain = synchronizable(isSynchronizable)
		}
		if let accessibility {
			if let authenticationPolicy {
				keychain = keychain.accessibility(accessibility, authenticationPolicy: authenticationPolicy)
			} else {
				keychain = keychain.accessibility(accessibility)
			}
		}
		return keychain
	}
	
	func with(
		attributes: KeychainAttributes?
	) -> KeychainAccess.Keychain {
		withAttributes(
			label: attributes?.label,
			comment: attributes?.comment,
			isSynchronizable: attributes?.isSynchronizable,
			accessibility: attributes?.accessibility,
			authenticationPolicy: attributes?.maybeAuthenticationPolicy
		)
	}
	
	func modifier(_ modifier: Keychain.Modifier?) -> KeychainAccess.Keychain {
		guard let modifier else { return self }
		switch modifier {
		case let .attributes(attributes):
			return with(attributes: attributes)
		case let .authPrompt(authPrompt):
			return authenticationPrompt(authPrompt)
		}
	}
	
	convenience init(service: String, accessGroup: String? = nil) {
		if let accessGroup {
			self.init(
				service: service,
				accessGroup: accessGroup
			)
		} else {
			self.init(
				service: service
			)
		}
	}
}
