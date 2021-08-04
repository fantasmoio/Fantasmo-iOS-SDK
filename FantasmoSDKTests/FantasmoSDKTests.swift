//
//  FantasmoSDKTests.swift
//  FantasmoSDKTests
//
//  Created by lucas kuzma on 8/4/21.
//

import XCTest
import CoreLocation

class FantasmoSDKTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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

    func testLocationFusion() {
        var fuser = LocationFuser()
        var result: FMLocationResult
        var expected = CLLocation()

        result = fuser.fusedResult(location: CLLocation(latitude: 0, longitude: 0), zones: nil)
        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 0, longitude: 0);
        XCTAssertLessThan(result.location.degreeDistance(from: expected), 0.01)
        XCTAssertEqual(result.confidence, .low)

        result = fuser.fusedResult(location: CLLocation(latitude: 0, longitude: 10), zones: nil)
        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 0, longitude: 5);
        XCTAssertLessThan(result.location.degreeDistance(from: expected), 0.01)
        XCTAssertEqual(result.confidence, .low)

        result = fuser.fusedResult(location: CLLocation(latitude: 0, longitude: 20), zones: nil)
        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 0, longitude: 10);
        XCTAssertLessThan(result.location.degreeDistance(from: expected), 0.01)
        XCTAssertEqual(result.confidence, .medium)
    }

    func testLocationFusionOutliers() {
        var fuser = LocationFuser()
        var result: FMLocationResult
        var expected = CLLocation()

        result = fuser.fusedResult(location: CLLocation(latitude: 0, longitude: 0), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 0, longitude: 10), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 0, longitude: 20), zones: nil)

        result = fuser.fusedResult(location: CLLocation(latitude: 100, longitude: 20), zones: nil)
        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 0, longitude: 10);
        XCTAssertLessThan(result.location.degreeDistance(from: expected), 0.01)
        XCTAssertEqual(result.confidence, .medium)

        result = fuser.fusedResult(location: CLLocation(latitude: 100, longitude: 20), zones: nil)
        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 0, longitude: 10);
        XCTAssertLessThan(result.location.degreeDistance(from: expected), 0.01)
        XCTAssertEqual(result.confidence, .high)
    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
