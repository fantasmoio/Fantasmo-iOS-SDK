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
    
    let imageQualityModelCompiledFilename = "ImageQualityModel.mlmodelc"
    let imageQualityModelCurrentVersionKey = "ImageQualityModelCurrentVersionKey"
    
    var isCheckingForUpdates: Bool = false
    
    func checkForUpdates() {
        guard !isCheckingForUpdates else {
            return  // Previous update in progress
        }
        
        let remoteConfig = RemoteConfig.config()
        guard let latestModelUrlString = remoteConfig.imageQualityFilterModelUri,
                let latestModelUrl = URL(string: latestModelUrlString) else {
            return  // No model in the remote config
        }

        let fileManager = FileManager.default
        let userDefaults = UserDefaults.standard
        
        // Check if we have a downloaded a model file already and if it matches what's in remote config
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let currentCompiledModelFile = appSupportDirectory.appendingPathComponent(imageQualityModelCompiledFilename)
        if fileManager.fileExists(atPath: currentCompiledModelFile.path),
            userDefaults.string(forKey: imageQualityModelCurrentVersionKey) == latestModelUrlString {
            return  // Model is up to date
        }

        // Create the app support directory if needed, it doesn't exist by default
        if !fileManager.fileExists(atPath: appSupportDirectory.path, isDirectory: nil) {
            guard let _  = try? fileManager.createDirectory(
                at: appSupportDirectory, withIntermediateDirectories: true, attributes: nil) else {
                log.error("unable to create app support directory")
                return
            }
        }
                
        isCheckingForUpdates = true
        
        // Download the latest model
        downloadModel(at: latestModelUrl) { modelData, downloadError in
            guard downloadError == nil, let modelData = modelData else {
                // Download error
                self.isCheckingForUpdates = false
                log.error("Error downloading model: \(downloadError?.localizedDescription ?? "")")
                return
            }
            self.compileModel(data: modelData, overwriting: currentCompiledModelFile) { compileError in
                self.isCheckingForUpdates = false
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
                let compiledModelFile = try MLModel.compileModel(at: tempModelFile)
                // Replace the destination file with the newly compiled model
                _ = try! fileManager.replaceItemAt(destFile, withItemAt: compiledModelFile)
            } catch {
                compileError = error
            }
            DispatchQueue.main.async {
                completion(compileError)
            }
        }
    }
    
    private func getApplicationSupportDirectory() -> URL {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }
}
