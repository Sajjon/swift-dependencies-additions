import KeychainAccess

/// Just a namespace for Keychain API, models and protocols.
public enum Keychain {}

public protocol KeychainAttributes: Sendable {
	var label: String? { get }
	var comment: String? { get }
	var isSynchronizable: Bool { get }
	var accessibility: KeychainAccess.Accessibility? { get }
	var maybeAuthenticationPolicy: KeychainAccess.AuthenticationPolicy? { get }
}


extension Keychain {
	
	public typealias Key = String
	public typealias Label = String
	public typealias Comment = String
	public typealias AuthenticationPrompt = String
	
	public struct AttributesWithAuth: KeychainAttributes, Hashable {
		public let label: String?
		public let comment: String?
		public let isSynchronizable: Bool
		public let accessibility: KeychainAccess.Accessibility?
		public let authenticationPolicy: KeychainAccess.AuthenticationPolicy
		
		public init(
			label: String? = nil,
			comment: String? = nil,
			isSynchronizable: Bool = false,
			accessibility: KeychainAccess.Accessibility,
			authenticationPolicy: KeychainAccess.AuthenticationPolicy
		) {
			self.label = label
			self.comment = comment
			self.isSynchronizable = isSynchronizable
			self.accessibility = accessibility
			self.authenticationPolicy = authenticationPolicy
		}
		
		public var maybeAuthenticationPolicy: KeychainAccess.AuthenticationPolicy? { authenticationPolicy }
	}
	
	public struct AttributesWithoutAuth: KeychainAttributes, Hashable {
		public let label: String?
		public let comment: String?
		public let isSynchronizable: Bool
		public let accessibility: KeychainAccess.Accessibility?
		
		public init(
			label: String? = nil,
			comment: String? = nil,
			isSynchronizable: Bool = false,
			accessibility: KeychainAccess.Accessibility? = nil
		) {
			self.label = label
			self.comment = comment
			self.isSynchronizable = isSynchronizable
			self.accessibility = accessibility
		}
		
		public var maybeAuthenticationPolicy: KeychainAccess.AuthenticationPolicy? { nil }
	}
	
	enum Modifier {
		case attributes(any KeychainAttributes)
		case authPrompt(AuthenticationPrompt)
		init?(attributes: (any KeychainAttributes)?) {
			guard let attributes else { return nil }
			self = .attributes(attributes)
		}
		init?(authPrompt: AuthenticationPrompt?) {
			guard let authPrompt else { return nil }
			self = .authPrompt(authPrompt)
		}
	}
}
