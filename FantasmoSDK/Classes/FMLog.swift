//
//  FMLog.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/24/21.
//

import Foundation

var log = FMLog()

public struct FMLog {

    public var intercept: ((String) -> Void)?

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZZZ"
        return dateFormatter
    }()
    
    public enum LogLevel: Comparable {
        case debug
        case info
        case warning
        case error
        
        var decorator: String {
            switch self {
            case .debug:
                return "⚙️"
            case .info:
                return "💡"
            case .warning:
                return "⚠️"
            case .error:
                return "💣"
            }
        }
    }
    
    var logLevel = LogLevel.info
    
    // MARK: - Internal methods
    
    func debug(_ message: String = "", parameters: [AnyHashable: Any?]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        if logLevel <= .debug {
            log(format(message: message, parameters: parameters, file: file, function: function, line: line, level: .debug))
        }
    }
    
    func info(_ message: String = "", parameters: [AnyHashable: Any?]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        if logLevel <= .info {
            log(format(message: message, parameters: parameters, file: file, function: function, line: line, level: .info))
        }
    }
    
    func warning(_ message: String = "", parameters: [AnyHashable: Any?]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        if logLevel <= .warning {
            log(format(message: message, parameters: parameters, file: file, function: function, line: line, level: .warning))
        }
    }
    
    func error(_ message: String = "", parameters: [AnyHashable: Any?]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        if logLevel <= .error {
            log(format(message: message, parameters: parameters, file: file, function: function, line: line, level: .error))
        }
    }
    
    func error(_ error: FMError, file: String = #file, function: String = #function, line: Int = #line) {
        let message = error.debugDescription
        if logLevel <= .error {
            log(format(message: message, parameters: nil, file: file, function: function, line: line, level: .error))
        }
    }
    
    // MARK: - Private methods
    
    private func log(_ message: String) {
        if let intercept = intercept {
            intercept(message)
        } else {
            print(message)
        }
    }
    
    private func format(
        message: String,
        parameters: [AnyHashable: Any?]? = nil,
        file: String,
        function: String,
        line: Int,
        level: LogLevel
    ) -> String {
        var output = "\(level.decorator) [FM] \(FMLog.dateFormatter.string(from: Date()))"
        
        #if DEBUG
        output.append("[\(sourceFileName(filePath: file)) \(function):\(line)] \(message)")
        #else
            output.append(message)
        #endif
        
        if let parameters = parameters {
            output.append("\n" + formatParameters(parameters))
        }
        
        return output
    }
    
    private func formatParameters(_ parameters: [AnyHashable: Any?] = [:]) -> String {
        var paramsString = ""
        
        for (key, value) in parameters {
            if !paramsString.isEmpty {
                paramsString.append("\n")
            }

            paramsString.append("\t• \(key): \(value ?? "")")
        }
        
        return paramsString
    }
    
    private func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return (components.isEmpty ? "" : components.last) ?? ""
    }
}
