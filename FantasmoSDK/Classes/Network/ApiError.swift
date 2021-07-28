//
//  AFError.swift
//
//  Copyright (c) 2014-2018 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

enum ApiError: Error {
    
    case requestSerializationFailed(reason: SerializationFailureReason? = nil)
    /// Multipart form encoding failed.
    case multipartEncodingFailed(reason: MultipartEncodingFailureReason)
    case multipartConstructionFailed(error: Error? = nil, msg: String? = nil)
    case unknown(message: String)
    
    enum SerializationFailureReason {
        /// JSON encoding failed with an underlying system error.
        case jsonEncodingFailed(error: Error? = nil, msg: String? = nil)
        /// String serialization failed using the provided `String.Encoding`.
        case stringSerializationFailed(encoding: String.Encoding)
    }
    
    /// The underlying reason the `.multipartEncodingFailed` error occurred.
    public enum MultipartEncodingFailureReason {
        /// The `fileURL` provided for reading an encodable body part isn't a file `URL`.
        case bodyPartURLInvalid(url: URL)
        /// The filename of the `fileURL` provided has either an empty `lastPathComponent` or `pathExtension.
        case bodyPartFilenameInvalid(in: URL)
        /// The file at the `fileURL` provided was not reachable.
        case bodyPartFileNotReachable(at: URL)
        /// Attempting to check the reachability of the `fileURL` provided threw an error.
        case bodyPartFileNotReachableWithError(atURL: URL, error: Error)
        /// The file at the `fileURL` provided is actually a directory.
        case bodyPartFileIsDirectory(at: URL)
        /// The size of the file at the `fileURL` provided was not returned by the system.
        case bodyPartFileSizeNotAvailable(at: URL)
        /// The attempt to find the size of the file at the `fileURL` provided threw an error.
        case bodyPartFileSizeQueryFailedWithError(forURL: URL, error: Error)
        /// An `InputStream` could not be created for the provided `fileURL`.
        case bodyPartInputStreamCreationFailed(for: URL)
        /// An `OutputStream` could not be created when attempting to write the encoded data to disk.
        case outputStreamCreationFailed(for: URL)
        /// The encoded body data could not be written to disk because a file already exists at the provided `fileURL`.
        case outputStreamFileAlreadyExists(at: URL)
        /// The `fileURL` provided for writing the encoded body data to disk is not a file `URL`.
        case outputStreamURLInvalid(url: URL)
        /// The attempt to write the encoded body data to disk failed with an underlying error.
        case outputStreamWriteFailed(error: Error)
        /// The attempt to read an encoded body part `InputStream` failed with underlying system error.
        case inputStreamReadFailed(error: Error)
    }
    
}
