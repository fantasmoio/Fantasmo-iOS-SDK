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
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        var locations: [CLLocation] = []
        var median = CLLocation()
        var expected = CLLocation()

//        locations.append(CLLocation(latitude: 0, longitude: 0))
//        median = CLLocation.geometricMedian(locations)
//        print(median.coordinate)

//        XCTAssertEqual(median, CLLocation(latitude: 0, longitude: 0))

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
    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
