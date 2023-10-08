//
//  ContentView.swift
//  DummyHost
//
//  Created by Alexander Cyon on 2023-10-07.
//

import Foundation
import SwiftUI
import DependenciesAdditions
@_spi(Internal) import _KeychainDependency

private let noAuthRandomKey = "noAuthRandomKey"
private let authRandomKey = "authRandomKey"

@MainActor
final class KeychainStudy: ObservableObject {
	
	@Published var status: Status = .new
	private let sut: KeychainActor
	
	init() {
		sut = .init(service: "KeychainStudy")
	}
	
	func initialize() async {
		status = .initializing
		do {
			try await sut.removeAllItems()
			let noAuth = try await sut.getDataWithoutAuth(forKey: noAuthRandomKey)
			let auth = try await sut.getDataWithoutAuth(forKey: authRandomKey)
			status = .initialized("Data nil? withAuth:\(auth == nil)/ withoutAuth:\(noAuth == nil)")
		} catch {
			status = .failedToInitialize("Failed to remove all items in keychain \(error)")
		}
	}
	
	func doTestAuth() async {
		await _doTest {
			try await self.sut.authGetSavedDataElseSaveNewRandom()
		}
	}
	
	func doTestNoAuth() async {
		await _doTest {
			try await self.sut.noAuthGetSavedDataElseSaveNewRandom()
		}
	}
	
	private func _doTest(
		_ task: @escaping @Sendable () async throws -> Data
	) async {
		do {
			let values = try await valuesFromManyTasks {
				try await task()
			}
			if values.count == 0 {
				status = .finishedWithFailure("Zero elements")
			} else if values.count == 1 {
				status = .finishedSuccessfully
			} else {
				status = .finishedWithFailure("#\(values.count) elements")
			}
		} catch {
			status = .error("\(error)")
		}
	}
}

enum Status: Equatable {
	case new
	case initializing
	case initialized(String)
	case failedToInitialize(String)
	
	case error(String)
	case finishedWithFailure(String)
	case finishedSuccessfully
}

struct KeychainStudyView: View {
	
	@ObservedObject var model: KeychainStudy
	
	var body: some View {
		VStack(alignment: .center) {
			StatusView(status: model.status)
			
			if model.status.canTest {
				
				Button("Test auth") {
					Task {
						await model.doTestAuth()
					}
				}
				
				Button("Test no auth") {
					Task {
						await model.doTestNoAuth()
					}
				}
			} else {
				Button("Re-initialize") {
					Task {
						await model.initialize()
					}
				}
			}
			
		}
		.buttonStyle(.borderedProminent)
		.font(.title)
		.padding()
		.task {
			await model.initialize()
		}
	}
}



struct StatusView: View {
	let status: Status
	var body: some View {
		HStack {
			Circle().fill(status.color)
				.frame(width: 30, height: 30)
			Text("`\(status.description)`")
			Spacer(minLength: 0)
		}
	}
}

extension Status {
	
	var canTest: Bool {
		switch self {
		case .initialized: return true
		default: return false
		}
	}
	
	var description: String {
		switch self {
		case .new: return "New"
		case .initializing: return "Initializing"
		case let .failedToInitialize(error): return "Failed to initialize \(error)"
		case let .initialized(info): return "Initialized \(info)"
		case let .error(error): return "Error: \(error)"
		case .finishedSuccessfully: return "Success"
		case let .finishedWithFailure(failure): return "Failed: \(failure)"
		}
	}
	var color: Color {
		switch self {
		case .new: return .gray
		case .initializing: return .yellow
		case .failedToInitialize: return .red
		case .initialized: return .blue
		case .error: return .red
		case .finishedSuccessfully: return .green
		case .finishedWithFailure: return .orange
		}
	}
}
