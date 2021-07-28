public protocol APIRequest {
    
    /// Endpoint URL.
    /// Allows to change URL for the given request.
    /// If `nil` then APIClient uses some default value.
    /// For REST requests is used as base URL
    /// - note: Can be useful to provide stub for the response to the given request. Just provide file with needed content
    /// of response and set this property to appropriate file URL.
    var URL: String? { get }
    
    var httpMethod: HTTPMethod { get }
    
    /// Default implementation is provided.
    var httpHeaders: [String : String]? { get }
    
    /// Parameters of the request that are passed as URL query or in http request body.
    /// Default value is provided.
    /// Sometimes when calculating parameters some error may occur and it is needed to pass this error outside, this is why we do not shape
    /// `parameters` as property.
    func parameters() throws -> [String : Any]?
    
    /// - throws `ApiError.requestSerializationFailed` in case of failure
    func multipartFormData() throws -> MultipartFormData?
}


public extension APIRequest {
    
    // Default implementation for `URL` property.
    // Adding this property to some base class is bad idea because base class will have to provide default implementation 
    // for methods of all protocols that it conforms to, and thus will non allow compile-time checking whether all needed
    // methods are implemented when creating new subclass for some request.
    var URL: String? {
        get {
            return nil
        }
    }
    
    var httpMethod: HTTPMethod {
        return .get
    }
    
    var httpHeaders: [String : String]? {
        return nil
    }
    
    func parameters() throws -> [String : Any]? {
        return nil
    }
    
    func multipartFormData() throws -> MultipartFormData? {
        return nil
    }

}

