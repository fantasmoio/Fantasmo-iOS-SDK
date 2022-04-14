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
    
    override func setUpWithError() throws {
        ImageQualityModel.removeDownloadedModel()
    }
    
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
    
    func testModelNotUpdated() throws {
        // Mock a remote config with an older model
        let testConfig = TestUtils.makeTestConfig(
            imageQualityFilterModelUri: "https://fantasmo-ci.s3.eu-west-3.amazonaws.com/dummy-image-quality-model-0.0.1.mlmodel",
            imageQualityFilterModelVersion: "0.0.1"
        )
        RemoteConfig.update(testConfig)
        
        // Trigger the model update routine
        let imageQualityModelUpdater = ImageQualityModelUpdater.shared
        imageQualityModelUpdater.checkForUpdates()
        
        // Check that the model is not being updated
        XCTAssertFalse(imageQualityModelUpdater.isUpdatingModel)
    }
    
    func testModelUpdated() throws {
        // Mock a remote config with a newer model
        let testConfig = TestUtils.makeTestConfig(
            imageQualityFilterModelUri: "https://fantasmo-ci.s3.eu-west-3.amazonaws.com/dummy-image-quality-model-9.9.9.mlmodel",
            imageQualityFilterModelVersion: "9.9.9"
        )
        RemoteConfig.update(testConfig)
        
        // Trigger the model update routine
        let imageQualityModelUpdater = ImageQualityModelUpdater.shared
        imageQualityModelUpdater.checkForUpdates()
        
        // Check that the model is being updated
        XCTAssertTrue(imageQualityModelUpdater.isUpdatingModel)
        
        // Wait for the model to be downloaded and compiled
        _ = XCTWaiter.wait(for: [expectation(description: "")], timeout: 3.0)
        
        // Check the compiled model is present
        let fileManager = FileManager.default
        let downloadedModelLocation = ImageQualityModel.downloadedModelLocation
        XCTAssertTrue(fileManager.fileExists(atPath: downloadedModelLocation.path))
        
        // Check the downloaded model is loaded
        let model = try ImageQualityModel.loadLatest()
        let modelVersion = try XCTUnwrap(model.model.modelDescription.metadata[.versionString] as? String)
        XCTAssertEqual(modelVersion, "9.9.9")
        
        // Check the current downloaded model version was updated
        XCTAssertEqual(ImageQualityModel.downloadedVersion, "9.9.9")
        
        // Check the model is finished being updated
        XCTAssertFalse(imageQualityModelUpdater.isUpdatingModel)
        
        // Check the update is not triggered again
        imageQualityModelUpdater.checkForUpdates()
        XCTAssertFalse(imageQualityModelUpdater.isUpdatingModel)
    }
    
    func testBundledModelLoadedWhenNewer() throws {
        // Place an older image quality model in the downloaded location
        let oldModelLocation = try XCTUnwrap(TestUtils.url(for: "dummy-image-quality-model-0.0.1.mlmodelc"))
        let downloadedModelLocation = ImageQualityModel.downloadedModelLocation
        try FileManager.default.copyItem(at: oldModelLocation, to: downloadedModelLocation)
        ImageQualityModel.downloadedVersion = "0.0.1"
        
        // Check the bundled model is loaded because it's newer
        let model = try ImageQualityModel.loadLatest()
        let modelVersion = try XCTUnwrap(model.model.modelDescription.metadata[.versionString] as? String)
        XCTAssertEqual(modelVersion, ImageQualityModel.bundledVersion)
    }
}
