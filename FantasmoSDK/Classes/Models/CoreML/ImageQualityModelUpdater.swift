//
//  ImageQualityModelUpdater.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 24.11.21.
//

import Foundation
import CoreML

class ImageQualityModelUpdater {
    
    static let shared = ImageQualityModelUpdater()
    
    var isUpdatingModel: Bool = false
    
    func checkForUpdates() {
        guard #available(iOS 13.0, *) else {
            return
        }
        
        guard !isUpdatingModel else {
            return
        }
        
        log.info("checking for model updates")
        
        let remoteConfig = RemoteConfig.config()
        guard let remoteConfigModelVersion = remoteConfig.imageQualityFilterModelVersion,
              let remoteConfigModelUrlString = remoteConfig.imageQualityFilterModelUri,
              let remoteConfigModelUrl = URL(string: remoteConfigModelUrlString)
        else {
            log.info("no model specified in remote config")
            return
        }
        
        let currentLatestVersion: String
        if let downloadedVersion = ImageQualityModel.downloadedVersion,
           downloadedVersion.compare(ImageQualityModel.bundledVersion, options: .numeric) == .orderedDescending {
            currentLatestVersion = downloadedVersion
        } else {
            currentLatestVersion = ImageQualityModel.bundledVersion
        }
        log.info("current model version: \(currentLatestVersion)")
        log.info("remote config model version: \(remoteConfigModelVersion)")
        
        let isRemoteConfigModelNewer = remoteConfigModelVersion.compare(currentLatestVersion, options: .numeric) == .orderedDescending
        if !isRemoteConfigModelNewer {
            log.info("current model is already the latest")
            return
        }
        
        log.info("updating model to version \(remoteConfigModelVersion)")
        
        // First create the app support directory if needed, it doesn't exist by default
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !fileManager.fileExists(atPath: appSupportDirectory.path, isDirectory: nil) {
            guard let _  = try? fileManager.createDirectory(
                at: appSupportDirectory, withIntermediateDirectories: true, attributes: nil) else {
                log.error("unable to create app support directory")
                return
            }
        }
                
        isUpdatingModel = true
        
        downloadModel(at: remoteConfigModelUrl) { modelData, downloadError in
            guard downloadError == nil, let modelData = modelData else {
                self.isUpdatingModel = false
                log.error("error downloading model: \(downloadError?.localizedDescription ?? "")")
                return
            }
        
            let downloadedModelLocation = ImageQualityModel.getDownloadedModelLocation()
            self.compileModel(data: modelData, overwriting: downloadedModelLocation) { compileError in
                self.isUpdatingModel = false
                if let compileError = compileError {
                    log.error("error compiling model: \(compileError.localizedDescription)")
                    return
                }
                log.info("successfully updated model to version: \(remoteConfigModelVersion)")
                ImageQualityModel.downloadedVersion = remoteConfigModelVersion
            }
        }
    }
    
    private func downloadModel(at url: URL, completion: @escaping ((Data?, Error?) -> Void)) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = "GET"
        let downloadTask = URLSession.shared.dataTask(with: request) { data, response, downloadError in
            DispatchQueue.main.async {
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    completion(nil, URLError(.badServerResponse))
                    return
                }
                completion(data, downloadError)
            }
        }
        downloadTask.resume()
        log.info("downloading model \(url)")
    }
    
    private func compileModel(data: Data, overwriting destFile: URL, completion: @escaping ((Error?) -> Void)) {
        var compileError: Error?
        DispatchQueue.global(qos: .background).async {
            do {
                // Write the model data to a temporary file
                let fileManager = FileManager.default
                let tempName = "\(UUID().uuidString).mlmodel"
                let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let tempModelFile = tempDirectory.appendingPathComponent(tempName)
                try data.write(to: tempModelFile, options: .atomic)
                // Compile the model
                log.info("compiling model \(tempModelFile)")
                let compiledModelFile = try MLModel.compileModel(at: tempModelFile)
                // Replace the destination file with the newly compiled model
                log.info("replacing model \(tempModelFile) => \(destFile)")
                _ = try! fileManager.replaceItemAt(destFile, withItemAt: compiledModelFile)
            } catch {
                compileError = error
            }
            DispatchQueue.main.async {
                completion(compileError)
            }
        }
    }
}
