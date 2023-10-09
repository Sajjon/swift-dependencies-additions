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

let studyWithAuthKey = "studyWithAuthKey"
let studyWithoutAuthKey = "studyWithoutAuthKey"

@MainActor
final class KeychainStudy: ObservableObject {
	
	@Published var status: Status = .new
	@Published var eventForAuthKey: Keychain.Event?
	@Published var eventForNoAuthKey: Keychain.Event?
	@Dependency(\.keychain) var keychain
	
	func initialize() async {
		status = .initializing
		do {
			try await keychain.removeAllItems()
			let noAuth = try await keychain.dataWithoutAuth(forKey: studyWithoutAuthKey)
			let auth = try await keychain.dataWithoutAuth(forKey: studyWithAuthKey)
			if noAuth == nil && auth == nil {
				status = .initialized("keychain reset")
			} else {
				status = .failedToInitialize("Failed to remove items")
			}
		} catch {
			status = .failedToInitialize("Failed to remove all items in keychain \(error)")
		}
	}
	
	func doTestAuth() async {
		await _doTest {
			try await self.keychain
				.authGetSavedDataElseSaveNewRandom(
					key: studyWithAuthKey
				)
		}
	}
	
	func doTestNoAuth() async {
		await _doTest {
			try await self.keychain.noAuthGetSavedDataElseSaveNewRandom(
				key: studyWithoutAuthKey
			)
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
			EventView(key: studyWithAuthKey)
			EventView(key: studyWithoutAuthKey)
			
			Spacer(minLength: 0)
			
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
		.padding()
		.task {
			await model.initialize()
		}
	}
}

struct EventView: View {
	@Dependency(\.keychain) var keychain
	let key: Keychain.Key
	@State var event: Keychain.Event?
	var body: some View {
		VStack {
			Text("Event for key: `\(key)`")
			if let event {
				switch event {
				case let .added(addEvent):
					Text("Added #\(addEvent.data.count)bytes")
				case .removed:
					Text("Removed data")
				}
			} else {
				Text("Received no event yet.")
			}
		}
		.background {
			if let event {
				event.added ? Color.green : (event.removed ? Color.orange : Color.gray)
			} else {
				Color.blue
			}
		}
		.frame(maxWidth: .infinity)
		.task {
			for await event in keychain.events(forKey: key) {
				self.event = event
			}
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
		.font(.headline)
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
