//
//  ManyTasks.swift
//  DummyHost
//
//  Created by Alexander Cyon on 2023-10-07.
//

import Foundation

public func valuesFromManyTasks<T: Sendable & Hashable>(
	task: @Sendable @escaping () async throws -> T
) async throws -> Set<T> {
	
	let t0 = Task {
		try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t1 = Task { @MainActor in
		dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
		return try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t2 = Task { @MainActor in
		dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
		return try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t3 = Task {
		try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t4 = Task {
		try await task()
	}
	await Task.yield()
	await Task.yield()
	let t5 = Task {
		try await task()
	}
	await Task.yield()
	await Task.yield()
	let t6 = Task { @MainActor in
		dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
		return try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t7 = Task {
		try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t8 = Task { @MainActor in
		dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
		return try await task()
	}
	await Task.yield()
	await Task.yield()
	await Task.yield()
	let t9 = Task {
		try await task()
	}
	await Task.yield()
	
	let tasks = [t0, t1, t2, t3, t4, t5, t6, t7, t8, t9]
	var values = Set<T>()
	for task in tasks {
		let value = try await task.value
		values.insert(value)
	}
	return values
}
