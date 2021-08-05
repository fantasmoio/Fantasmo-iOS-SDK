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

    func testLocationFusionRealData() {
        var fuser = LocationFuser()
        var result: FMLocationResult
        var expected = CLLocation()

        // sample data from 290_FE600-009_2021_04_24T13_50_12_UTC_done
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826571, longitude: 2.327442), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826571, longitude: 2.327438), zones: nil)
        XCTAssertEqual(result.confidence, .low)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826578, longitude: 2.327439), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826589, longitude: 2.327399), zones: nil)
        XCTAssertEqual(result.confidence, .medium)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826602, longitude: 2.327396), zones: nil)
        XCTAssertEqual(result.confidence, .high)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826588, longitude: 2.327391), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826576, longitude: 2.327437), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826580, longitude: 2.327411), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826581, longitude: 2.327449), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826575, longitude: 2.327381), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826578, longitude: 2.327449), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826599, longitude: 2.327395), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826598, longitude: 2.327391), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826579, longitude: 2.327437), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826578, longitude: 2.327443), zones: nil)

        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 48.82, longitude: 2.32);
        XCTAssertLessThan(result.location.degreeDistance(from: expected), 0.01)
        XCTAssertEqual(result.confidence, .high)
    }

    func testLocationFusionRealDataOutlier() {
        var fuser = LocationFuser()
        var result: FMLocationResult
        var expected = CLLocation()

        // sample data from 290_FE600-009_2021_04_24T13_50_12_UTC_done
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826571, longitude: 2.327442), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826571, longitude: 2.327438), zones: nil)
        XCTAssertEqual(result.confidence, .low)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826578, longitude: 2.327439), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826589, longitude: 2.327399), zones: nil)
        XCTAssertEqual(result.confidence, .medium)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826602, longitude: 2.327396), zones: nil)
        XCTAssertEqual(result.confidence, .high)

        // fudge some outliers
        result = fuser.fusedResult(location: CLLocation(latitude: 45, longitude: 2.327391), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 45, longitude: 2.327437), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 45, longitude: 2.327411), zones: nil)

        result = fuser.fusedResult(location: CLLocation(latitude: 48.826581, longitude: 2.327449), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826575, longitude: 2.327381), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826578, longitude: 2.327449), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826599, longitude: 2.327395), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826598, longitude: 2.327391), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826579, longitude: 2.327437), zones: nil)
        result = fuser.fusedResult(location: CLLocation(latitude: 48.826578, longitude: 2.327443), zones: nil)

        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 48.82, longitude: 2.32);
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
