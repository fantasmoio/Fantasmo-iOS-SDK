//
//  SDKLocationTests.swift
//  FantasmoSDKTests
//
//  Created by lucas kuzma on 8/4/21.
//  Modified by che fisher on 27/9/21

import XCTest
import CoreLocation
import ARKit

class SDKLocationTests: XCTestCase {

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

    func testLocationFusion() {
        var fuser = LocationFuser()
        var result: FMLocationResult
        var expected = CLLocation()

        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 0, longitude: 0), zones: nil)
        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 0, longitude: 0);
        XCTAssertLessThan(result.location.degreeDistance(from: expected), 0.01)
        XCTAssertEqual(result.confidence, .low)

        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 0, longitude: 10), zones: nil)
        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 0, longitude: 5);
        XCTAssertLessThan(result.location.degreeDistance(from: expected), 0.01)
        XCTAssertEqual(result.confidence, .low)

        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 0, longitude: 20), zones: nil)
        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 0, longitude: 10);
        XCTAssertLessThan(result.location.degreeDistance(from: expected), 0.01)
        XCTAssertEqual(result.confidence, .medium)
    }

    func testInliers() {
        var locations = [CLLocation]()
        var inliers: [CLLocation]

        locations.append(CLLocation(latitude: 0, longitude: 0.00))
        locations.append(CLLocation(latitude: 0, longitude: 0.01))
        locations.append(CLLocation(latitude: 0, longitude: 0.02))
        inliers = CLLocation.classifyInliers(locations)
        XCTAssertEqual(inliers.count, 3)

        locations.append(CLLocation(latitude: 1, longitude: 0.00))
        inliers = CLLocation.classifyInliers(locations)
        XCTAssertEqual(inliers.count, 3)

        locations.append(CLLocation(latitude: 1, longitude: 0.00))
        inliers = CLLocation.classifyInliers(locations)
        XCTAssertEqual(inliers.count, 3)
    }

    func testLocationFusionOutliers() {
        var fuser = LocationFuser()
        var result: FMLocationResult
        var expected = CLLocation()

        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 0, longitude: 0.00), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 0, longitude: 0.01), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 0, longitude: 0.02), zones: nil)

        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 1, longitude: 0), zones: nil)
        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 0, longitude: 0.01);
        XCTAssertLessThan(result.location.degreeDistance(from: expected), 0.01)
        XCTAssertEqual(result.confidence, .medium)

        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 1, longitude: 0), zones: nil)
        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 0, longitude: 0.01);
        XCTAssertLessThan(result.location.degreeDistance(from: expected), 0.01)
        XCTAssertEqual(result.confidence, .high)
    }

    func testLocationFusionRealData() {
        var fuser = LocationFuser()
        var result: FMLocationResult
        var expected = CLLocation()

        // sample data from 290_FE600-009_2021_04_24T13_50_12_UTC_done
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826571, longitude: 2.327442), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826571, longitude: 2.327438), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826578, longitude: 2.327439), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826589, longitude: 2.327399), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826602, longitude: 2.327396), zones: nil)
        XCTAssertEqual(result.confidence, .high)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826588, longitude: 2.327391), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826576, longitude: 2.327437), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826580, longitude: 2.327411), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826581, longitude: 2.327449), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826575, longitude: 2.327381), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826578, longitude: 2.327449), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826599, longitude: 2.327395), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826598, longitude: 2.327391), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826579, longitude: 2.327437), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826578, longitude: 2.327443), zones: nil)

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
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826571, longitude: 2.327442), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826571, longitude: 2.327438), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826578, longitude: 2.327439), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826589, longitude: 2.327399), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826602, longitude: 2.327396), zones: nil)
        XCTAssertEqual(result.confidence, .high)

        // fudge some outliers
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 45, longitude: 2.327391), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 45, longitude: 2.327437), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 45, longitude: 2.327411), zones: nil)

        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826581, longitude: 2.327449), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826575, longitude: 2.327381), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826578, longitude: 2.327449), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826599, longitude: 2.327395), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826598, longitude: 2.327391), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826579, longitude: 2.327437), zones: nil)
        result = fuser.locationFusedWithNew(location: CLLocation(latitude: 48.826578, longitude: 2.327443), zones: nil)

        print(result.location.coordinate)
        print(result.confidence)

        expected = CLLocation(latitude: 48.82, longitude: 2.32);
        XCTAssertLessThan(result.location.degreeDistance(from: expected), 0.01)
        XCTAssertEqual(result.confidence, .high)
    }

    func testConfidence() {
        var locations = [CLLocation]()

        locations.append(CLLocation(latitude: 10, longitude: 10))
        XCTAssertEqual(LocationFuser.standardDeviationConfidence(locations), .low)
        XCTAssertEqual(LocationFuser.confidence(locations), .low)

        locations.append(CLLocation(latitude: 10, longitude: 10.000001))
        XCTAssertEqual(LocationFuser.standardDeviationConfidence(locations), .high)
        XCTAssertEqual(LocationFuser.confidence(locations), .high)

        locations = [CLLocation]()
        locations.append(CLLocation(latitude: 10, longitude: 10))
        locations.append(CLLocation(latitude: 10, longitude: 10.000002))
        print(locations[0].distance(from: locations[1]))
        XCTAssertEqual(LocationFuser.standardDeviationConfidence(locations), .high)
        XCTAssertEqual(LocationFuser.confidence(locations), .high)

        locations = [CLLocation]()
        locations.append(CLLocation(latitude: 10, longitude: 10))
        locations.append(CLLocation(latitude: 10, longitude: 10.000004))
        print(locations[0].distance(from: locations[1]))
        XCTAssertEqual(LocationFuser.standardDeviationConfidence(locations), .medium)
        XCTAssertEqual(LocationFuser.confidence(locations), .medium)

        locations = [CLLocation]()
        locations.append(CLLocation(latitude: 10, longitude: 10))
        locations.append(CLLocation(latitude: 10, longitude: 10.000010))
        print(locations[0].distance(from: locations[1]))
        XCTAssertEqual(LocationFuser.standardDeviationConfidence(locations), .low)
        XCTAssertEqual(LocationFuser.confidence(locations), .low)

        locations.append(CLLocation(latitude: 10, longitude: 10))
        XCTAssertEqual(LocationFuser.confidence(locations), .medium) // 3 samples

        locations.append(CLLocation(latitude: 10, longitude: 10))
        XCTAssertEqual(LocationFuser.confidence(locations), .medium) // 4 samples

        locations.append(CLLocation(latitude: 10, longitude: 10))
        XCTAssertEqual(LocationFuser.confidence(locations), .high) // 5 samples
    }
}