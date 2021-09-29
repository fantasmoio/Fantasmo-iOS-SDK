//
//  SDKGeometricTests.swift
//  FantasmoSDKTests
//
//  Created by lucas kuzma on 8/4/21.
//  Modified by che fisher on 27/9/21.

import XCTest
import CoreLocation
import ARKit

class SDKGeometricTests: XCTestCase {

    override class func setUp() {
        // Put setup code here that is run once (equal to mocha "before" hook)
    }

    override func setUpWithError() throws {
        // Put setup code here is run before each test (equal to mocha "beforeEach" hook)
    }

    override func tearDownWithError() throws {
        // Put teardown code that is run after each test case (equal to mocha "afterEach" hook)
    }

    override class func tearDown() {
        // Put teardown code that is run once (equal to mocha "after" hook)
    }

    func testGeometricMedian() throws {
        var locations: [CLLocation] = []
        var median = CLLocation()
        var expected = CLLocation()

        locations.append(CLLocation(latitude: 0, longitude: 0))
        median = CLLocation.geometricMedian(locations)
        print(median.coordinate)

        expected = CLLocation(latitude: 0, longitude: 0);
        XCTAssertLessThan(median.degreeDistance(from: expected), 0.001)

        locations = []
        locations.append(CLLocation(latitude: 10, longitude: 0))
        locations.append(CLLocation(latitude: -10, longitude: 0))
        median = CLLocation.geometricMedian(locations)
        print(median.coordinate)

        expected = CLLocation(latitude: 0, longitude: 0);
        XCTAssertLessThan(median.degreeDistance(from: expected), 0.001)

        locations.append(CLLocation(latitude: 0, longitude: 10))
        median = CLLocation.geometricMedian(locations)
        print(median.coordinate)

        expected = CLLocation(latitude: 0, longitude: 5.77);
        XCTAssertLessThan(median.degreeDistance(from: expected), 0.01)

        locations = []
        locations.append(CLLocation(latitude: 10, longitude: 10))
        locations.append(CLLocation(latitude: 20, longitude: 10))
        locations.append(CLLocation(latitude: 10, longitude: 20))
        locations.append(CLLocation(latitude: 20, longitude: 20))
        median = CLLocation.geometricMedian(locations)
        print(median.coordinate)

        expected = CLLocation(latitude: 15, longitude: 15);
        XCTAssertLessThan(median.degreeDistance(from: expected), 0.01)

        locations.append(CLLocation(latitude: 15, longitude: 15))
        median = CLLocation.geometricMedian(locations)
        print(median.coordinate)

        XCTAssertLessThan(median.degreeDistance(from: expected), 0.01)
    }

    func testGeometricMedianColinear() throws {
        var locations: [CLLocation] = []
        var median = CLLocation()
        var expected = CLLocation()

        locations = []
        locations.append(CLLocation(latitude: 0, longitude: 0))
        locations.append(CLLocation(latitude: 0, longitude: 10))
        median = CLLocation.geometricMedian(locations)
        print(median.coordinate)

        expected = CLLocation(latitude: 0, longitude: 5);
        XCTAssertLessThan(median.degreeDistance(from: expected), 0.01)

        locations.append(CLLocation(latitude: 0, longitude: 20))
        median = CLLocation.geometricMedian(locations)
        print(median.coordinate)

        expected = CLLocation(latitude: 0, longitude: 10);
        XCTAssertLessThan(median.degreeDistance(from: expected), 0.01)
    }
}
