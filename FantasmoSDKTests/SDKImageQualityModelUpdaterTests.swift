//
//  SDKImageQualityModelUpdaterTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 13.04.22.
//

import XCTest
import CoreML
@testable import FantasmoSDK


class SDKImageQualityModelUpdaterTests: XCTestCase {
        
    func testBundledModelVersion() throws {
        let bundledModel = try ImageQualityModel(configuration: MLModelConfiguration())
        let bundledModelVersion = try XCTUnwrap(bundledModel.model.modelDescription.metadata[.versionString] as? String)
        // Check the shipped model version matches our constant
        XCTAssertEqual(bundledModelVersion, ImageQualityModel.bundledVersion)
    }
    
    func testDownloadedModelVersion() throws {
        // Check the downloaded version getter/setter persists in UserDefaults
        ImageQualityModel.downloadedVersion = nil
        XCTAssertNil(ImageQualityModel.downloadedVersion)
        XCTAssertNil(UserDefaults.standard.string(forKey:ImageQualityModel.downloadedVersionKey))
        
        ImageQualityModel.downloadedVersion = "1.0.0"
        XCTAssertEqual(ImageQualityModel.downloadedVersion, "1.0.0")
        XCTAssertEqual(UserDefaults.standard.string(forKey:ImageQualityModel.downloadedVersionKey), "1.0.0")
    }
    
    func testLatestVersion() throws {
        // Assign the downloaded version to nil
        ImageQualityModel.downloadedVersion = nil
        // Check latest version returns the bundled version
        XCTAssertEqual(ImageQualityModel.latestVersion, ImageQualityModel.bundledVersion)
        
        // Assign a non-nil, but lower downloaded version number
        ImageQualityModel.downloadedVersion = "0.0.1"
        // Check latest version returns the bundled version
        XCTAssertEqual(ImageQualityModel.latestVersion, ImageQualityModel.bundledVersion)
        
        // Assign a higher downloaded version number
        ImageQualityModel.downloadedVersion = "9.9.9"
        // Check latest version returns the downloaded version
        XCTAssertEqual(ImageQualityModel.latestVersion, ImageQualityModel.downloadedVersion)
    }
    
    func testModelUpdated() throws {
        // Clear the downloaded version number
        ImageQualityModel.downloadedVersion = nil
        let testConfig = TestUtils.makeTestConfig(
            imageQualityFilterModelUri: "https://fantasmo-ci.s3.eu-west-3.amazonaws.com/dummy-image-quality-model-9.9.9.mlmodel",
            imageQualityFilterModelVersion: "9.9.9"
        )
        RemoteConfig.update(testConfig)
        let imageQualityModelUpdater = ImageQualityModelUpdater.shared
        imageQualityModelUpdater.checkForUpdates()
        // Check that the update started
        XCTAssert(imageQualityModelUpdater.isUpdatingModel)
    }
}
