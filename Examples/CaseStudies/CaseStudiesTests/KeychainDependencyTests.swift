//
//  KeychainDependencyTests.swift
//  CaseStudiesTests
//
//  Created by Alexander Cyon on 2023-10-08.
//

import Foundation
import XCTest
@_spi(Internal) import _KeychainDependency

let noAuthRandomKey = "noAuthRandomKey"
final class KeychainDependencyTests: XCTestCase {
	let sut = KeychainActor(service: "KeychainDependencyTests")
	
	func testNoAuth() async throws {
		for _ in 0..<100 {
			try await onceNoAuthTest()
		}
	}
//	
//	func testAuth() async throws {
////		for _ in 0..<100 {
//			try await onceAuthTest()
////		}
//	}
//	
	func onceNoAuthTest() async throws {
		try await sut.removeAllItems()
		let startValue = try await sut.getDataWithoutAuth(forKey: noAuthRandomKey)
		XCTAssertNil(startValue)
	
		let values = try await valuesFromManyTasks {
			try await self.sut.noAuthGetSavedDataElseSaveNewRandom()
		}
		XCTAssertEqual(values.count, 1)
	}
//	
//	func onceAuthTest() async throws {
//		try await sut.removeAllItems()
//		let startValue = try await sut.getDataWithAuth(forKey: authRandomKey, authenticationPrompt: "onceAuthTest")
//		XCTAssertNil(startValue)
//	
//		let values = try await valuesFromManyTasks {
//			try await self.sut.authGetSavedDataElseSaveNewRandom()
//		}
//		XCTAssertEqual(values.count, 1)
//	}
}
