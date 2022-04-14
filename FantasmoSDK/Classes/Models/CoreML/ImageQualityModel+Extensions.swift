//
//  ImageQualityModel+Extensions.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 12.04.22.
//

import CoreML

@available(iOS 13.0, *)
extension ImageQualityModel {
    
    // Current bundled model version, hardcoded for inexpensive reads
    static let bundledVersion: String = "0.2.1"
        
    // UserDefault-backed property for caching the current downloaded model version
    static let downloadedVersionKey: String = "ImageQualityModel.downloadedVersionKey"
    static var downloadedVersion: String? {
        get { return UserDefaults.standard.string(forKey: downloadedVersionKey) }
        set { UserDefaults.standard.set(newValue, forKey: downloadedVersionKey) }
    }
    
    // Loads the latest `ImageQualityModel` model based on the `bundledVersion` and `downloadedVersion` values.
    static func loadLatest() throws -> ImageQualityModel {
        if let downloadedModelVersion = downloadedVersion, downloadedModelVersion.compare(bundledVersion, options: .numeric) == .orderedDescending {
            // we have a downloaded model and it's newer than the bundled one
            let modelName = String(describing: ImageQualityModel.self)
            let fileManager = FileManager.default
            let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let downloadedModelLocation = appSupportDirectory.appendingPathComponent(modelName).appendingPathExtension("mlmodelc")
            // check the downloaded model file exists
            if fileManager.fileExists(atPath: downloadedModelLocation.path) {
                do {
                    // attempt to load the downloaded model
                    let downloadedModel = try ImageQualityModel(contentsOf: downloadedModelLocation)
                    return downloadedModel
                } catch {
                    // failed to load the downloaded model, remove it
                    log.error("error loading downloaded model: \(error.localizedDescription)")
                    try? fileManager.removeItem(at: downloadedModelLocation)
                    ImageQualityModel.downloadedVersion = nil
                }
            }
        }
        // bundled model is newer or we failed to load a downloaded one
        return try ImageQualityModel(configuration: MLModelConfiguration())
    }
    
    static var downloadedModelLocation: URL {
        let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let modelName = String(describing: self)
        return appSupportDirectory.appendingPathComponent(modelName).appendingPathExtension("mlmodelc")
    }
    
    static func removeDownloadedModel() {
        try? FileManager.default.removeItem(at: downloadedModelLocation)
        downloadedVersion = nil
    }
}
