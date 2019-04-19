//
//  main.swift
//  SwiftPointerTry
//
//  Created by Daisuke T on 2019/04/18.
//  Copyright © 2019 SwiftPointerTry. All rights reserved.
//

import Foundation
import CoreAudio

/// The map will store object's address.
var addressMap = [String: Bool]()


/// Get address of object.
func address(_ object: AnyObject) -> String {
	return "\(Unmanaged.passUnretained(object).toOpaque())"
}


/// Mock class for Test.
class Mock {
	
	init () {
		print("init   : \(address(self))")
		addressMap[address(self)] = true	// Store address.
	}
	
	init(_ value: Int) {
		print("init   : \(address(self))")
		addressMap[address(self)] = true	//  Store address.
		
		v1 = value
	}
	
	deinit {
		print("deinit : \(address(self))")
		addressMap.removeValue(forKey: address(self))	//  Remove address.
	}
	
	
	var v1 = Int(0)
}


// MARK: - Test cases
func testFinally() {
	assert(addressMap.count == 0)	// Check leaks.
	print("- OK\n")
}


func testAllocateAndDeallocate() {
	print("# \(#function)")
	
	do {
		let p = UnsafeMutablePointer<Mock>.allocate(capacity: 1)
		
		// Uninitialized memory must be initialized before access.
		// p.pointee.v1 = ...
		
		p.deallocate()	// The memory leak occurs if do not call deallocate().
	}
	
	testFinally()
}

func testInitializeAndDeinitialize() {
	print("# \(#function)")
	
	do {
		var mock = Mock()
		mock.v1 = 10
		
		let p = UnsafeMutablePointer<Mock>.allocate(capacity: 1)
		defer {
			p.deallocate()
		}
		
		p.initialize(from: &mock, count: 1)
		p.pointee.v1 = 20
		
		assert(address(mock) == address(p.pointee))
		assert(mock.v1 == 20)
		
		p.deinitialize(count: 1)	// The memory leak occurs if do not call deinitialize().
	}
	
	testFinally()
}

func testInitializeAndMove() {
	print("# \(#function)")

	do {
		let p = UnsafeMutablePointer<Mock>.allocate(capacity: 1)
		defer {
			p.deallocate()
		}
		
		p.initialize(to: Mock())
		p.pointee.v1 = 10
		
		let mock = p.move()	// 'p' will deinitialize.
		
		assert(address(mock) == address(p.pointee))	// Check same address.
		assert(mock.v1 == 10)
	}
	
	testFinally()
}

func testMoveInitialize() {
	print("# \(#function)")
	
	do {
		var mock = Mock()
		mock.v1 = 10
		
		let p = UnsafeMutablePointer<Mock>.allocate(capacity: 1)
		defer {
			p.deallocate()
		}
		
		p.moveInitialize(from: &mock, count: 1)
		p.pointee.v1 = 20
		
		assert(address(mock) == address(p.pointee))	// Check same address.
		assert(p.pointee.v1 == 20)
	}
	
	testFinally()
}

func testInitializeAndAssign() {
	print("# \(#function)")
	
	do {
		var mock = Mock()
		mock.v1 = 10
		
		var mock2 = Mock()
		mock2.v1 = 20
		
		let p = UnsafeMutablePointer<Mock>.allocate(capacity: 1)
		defer {
			p.deallocate()
		}
		
		p.initialize(from: &mock, count: 1)
		p.assign(from: &mock2, count: 1)
		p.pointee.v1 = 30
		
		assert(address(mock2) == address(p.pointee))	// Check same address.
		assert(mock2.v1 == 30)
		
		p.deinitialize(count: 1)
	}
	
	testFinally()
}
	
func testMoveAssign() {
	print("# \(#function)")
	
	do {
		var mock = Mock()
		mock.v1 = 10
		
		var mock2 = Mock()
		mock2.v1 = 20
		
		let p = UnsafeMutablePointer<Mock>.allocate(capacity: 1)
		defer {
			p.deallocate()
		}
		
		p.initialize(from: &mock, count: 1)
		p.moveAssign(from: &mock2, count: 1)
		p.pointee.v1 = 30
		
		assert(address(mock2) == address(p.pointee))	// Check same address.
		assert(mock2.v1 == 30)
	}
	
	testFinally()
}
	
func testArray() {
	print("# \(#function)")
	
	do {
		var array: [Mock] = [Mock(10), Mock(20), Mock(30)]
		
		let p = UnsafeMutablePointer<[Mock]>.allocate(capacity: 1)
		defer {
			p.deallocate()
		}
		
		p.moveInitialize(from: &array, count: 1)
		p.pointee[0] = Mock(40)
		p.pointee[1] = Mock(50)
		p.pointee[2] = Mock(60)
		
		assert(array.count == p.pointee.count)
		assert(address(array as AnyObject) == address(p.pointee as AnyObject))	// Check same address.
		assert(array[0].v1 == 40)
		assert(array[1].v1 == 50)
		assert(array[2].v1 == 60)
	}
	
	testFinally()
}

func testAudioBufferList() {
	print("# \(#function)")
	
	do {
		let abl = AudioBufferList.allocate(maximumBuffers: 1)
		free(abl.unsafeMutablePointer)
	}
	
	testFinally()
}


while true {
	autoreleasepool {
		testAllocateAndDeallocate()
		testInitializeAndDeinitialize()
		testInitializeAndMove()
		testMoveInitialize()
		testInitializeAndAssign()
		testMoveAssign()
		testArray()
		testAudioBufferList()
		
		Thread.sleep(forTimeInterval: 1)
	}
}
