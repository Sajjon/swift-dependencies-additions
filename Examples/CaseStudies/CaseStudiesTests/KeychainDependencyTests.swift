//
//  KeychainDependencyTests.swift
//  CaseStudiesTests
//
//  Created by Alexander Cyon on 2023-10-08.
//

import Foundation
import XCTest
@_spi(Internal) import _KeychainDependency

final class KeychainDependencyTests: XCTestCase {
	let sut = KeychainActor(service: "KeychainDependencyTests")
	
	func testNoAuth() async throws {
		try await sut.removeAllItems()
		let startValue = try await sut.getDataWithoutAuth(forKey: noAuthRandomKey)
		XCTAssertNil(startValue)
	
		let values = try await valuesFromManyTasks {
			try await self.sut
				.noAuthGetSavedDataElseSaveNewRandom(
					key: authRandomKey
				)
		}
		XCTAssertEqual(values.count, 1)
	}
	
	func testAuth() async throws {
		try await sut.removeAllItems()
		let startValue = try await sut.getDataWithAuth(
			forKey: authRandomKey,
			authenticationPrompt: "onceAuthTest"
		)
		XCTAssertNil(startValue)
	
		let values = try await valuesFromManyTasks {
			try await self.sut
				.authGetSavedDataElseSaveNewRandom(
					key: noAuthRandomKey
				)
		}
		XCTAssertEqual(values.count, 1)
	}
}

let noAuthRandomKey = "noAuthRandomKey"
let authRandomKey = "authRandomKey"
