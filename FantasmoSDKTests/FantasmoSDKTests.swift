//
//  FantasmoSDKTests.swift
//  FantasmoSDKTests
//
//  Created by lucas kuzma on 8/4/21.
//

import XCTest
import CoreLocation
import ARKit

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
    
    func testMovementFilter() {
        let filter = FMMovementFilter()
        var transform = simd_float4x4(1)
        var pixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)
        if let nonnilBuffer = pixelBuffer {
            var frame = MockFrame(fmCamera: MockCamera(transform: transform), capturedImage: nonnilBuffer)
            XCTAssertEqual(filter.accepts(frame), .rejected(reason: .movingTooLittle))
            transform = simd_float4x4(1.1)
            frame = MockFrame(fmCamera: MockCamera(transform: transform), capturedImage: nonnilBuffer)
            XCTAssertEqual(filter.accepts(frame), .accepted)
            transform = simd_float4x4(1.099)
            XCTAssertEqual(filter.accepts(frame), .rejected(reason: .movingTooLittle))
        } else {
            print ("Couldn't allocate mock pixel buffer")
        }
    }
    func testCameraPitchFilter() {
        let filter = FMCameraPitchFilter()
        var pixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)
        var pitch : Float = deg2rad(-90)
        if let nonnilBuffer = pixelBuffer {
            var frame = MockFrame(fmCamera: MockCamera(pitch: pitch), capturedImage: nonnilBuffer)
            XCTAssertEqual(filter.accepts(frame), .rejected(reason: .pitchTooLow))
            pitch = deg2rad(-65)
            frame = MockFrame(fmCamera: MockCamera(pitch: pitch), capturedImage: nonnilBuffer)
            XCTAssertEqual(filter.accepts(frame), .accepted)
            pitch = deg2rad(0)
            frame = MockFrame(fmCamera: MockCamera(pitch: pitch), capturedImage: nonnilBuffer)
            XCTAssertEqual(filter.accepts(frame), .accepted)
            pitch = deg2rad(30)
            frame = MockFrame(fmCamera: MockCamera(pitch: pitch), capturedImage: nonnilBuffer)
            XCTAssertEqual(filter.accepts(frame), .accepted)
            pitch = deg2rad(60)
            frame = MockFrame(fmCamera: MockCamera(pitch: pitch), capturedImage: nonnilBuffer)
            XCTAssertEqual(filter.accepts(frame), .rejected(reason: .pitchTooHigh))
       } else {
            print ("Couldn't allocate mock pixel buffer")
        }
    }
    
    func testBlurFilter() {
        let filter = FMBlurFilter()
        let onStreet = UIImage(named: "onStreet", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let onStreetFrame = MockFrame(capturedImage: onStreet!.pixelBuffer()!)
        XCTAssertEqual(filter.accepts(onStreetFrame), .accepted)
    }
    //    func testPerformanceExample() throws {
    //        // This is an example of a performance test case.
    //        measure {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }

}
