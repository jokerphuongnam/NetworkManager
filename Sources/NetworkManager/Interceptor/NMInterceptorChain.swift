import Foundation

public class NMInterceptorChain {
    private var interceptors: [NMInterceptor]
    
    public init(interceptors: [NMInterceptor]) {
        self.interceptors = interceptors
    }
    
    public func proceed(request: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Request) -> Request {
        var finalRequest: URLRequest = request
        var errorOccurred: Error?
        let group = DispatchGroup()
        
        group.enter()
        runInterceptors(request: request, index: 0) { result in
            switch result {
            case .success(let modifiedRequest):
                finalRequest = modifiedRequest
            case .failure(let error):
                errorOccurred = error
            }
            group.leave()
        }
        
        group.wait()
        
        if let error = errorOccurred {
            return completion(.failure(error))
        }
        
        return completion(.success(finalRequest))
    }
    
    public func proceed(request: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var finalRequest: URLRequest = request
        var errorOccurred: Error?
        let group = DispatchGroup()
        
        group.enter()
        runInterceptors(request: request, index: 0) { result in
            switch result {
            case .success(let modifiedRequest):
                finalRequest = modifiedRequest
            case .failure(let error):
                errorOccurred = error
            }
            group.leave()
        }
        
        group.wait()
        
        if let error = errorOccurred {
            completion(.failure(error))
        }
        
        completion(.success(finalRequest))
    }
    
    private func runInterceptors(request: URLRequest, index: Int, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard index < interceptors.count else {
            completion(.success(request))
            return
        }
        
        interceptors[index].intercept(request: request) { result in
            switch result {
            case .success(let modifiedRequest):
                self.runInterceptors(request: modifiedRequest, index: index + 1, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
