import Foundation

public struct RetryTriggerError: Error {
    let retryImmediately: Bool
    let delay: TimeInterval
    let count: Int
}

public class RestAPIInterceptorChain: @unchecked Sendable {
    private var interceptors: [RestAPIInterceptor]
    
    public init(interceptors: [RestAPIInterceptor]) {
        self.interceptors = interceptors
    }
    
    // MARK: Request Interceptor Chain
    public func proceed(
        request: URLRequest,
        completion: @Sendable @escaping (Result<URLRequest, Error>) -> Request
    ) -> Request {
        let resultHolder = SafeBox<Result<URLRequest, Error>?>(nil)
        let group = DispatchGroup()
        group.enter()
        runInterceptors(request: request, index: 0) { result in
            resultHolder.value = result
            group.leave()
        }
        group.wait()
        return completion(resultHolder.value!)
    }
    
    private func runInterceptors(
        request: URLRequest,
        index: Int,
        completion: @Sendable @escaping (Result<URLRequest, Error>) -> Void
    ) {
        guard index < interceptors.count else {
            completion(.success(request))
            return
        }
        
        interceptors[index].intercept(request: request) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let modifiedRequest):
                self.runInterceptors(request: modifiedRequest, index: index + 1, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: Response Interceptor + Retry
    public func proceedWithRetry(
        response result: Result<(Data, URLResponse), Error>,
        for request: URLRequest,
        maxRetries: Int,
        retryCount: Int = 0,
        completion: @Sendable @escaping (Result<(Data, URLResponse), Error>) -> Void
    ) {
        let finalResponse = interceptors.reversed().reduce(result) { partialResult, interceptor in
            let resultHolder = SafeBox<Result<(Data, URLResponse), Error>>(partialResult)
            let sema = DispatchSemaphore(value: 0)
            
            interceptor.intercept(response: resultHolder.value, for: request) { newResult in
                resultHolder.value = newResult
                sema.signal()
            }
            sema.wait()
            return resultHolder.value
        }
        
        for interceptor in interceptors.reversed() {
            let sema = DispatchSemaphore(value: 0)
            let retryDecision = SafeBox<RetryResult>(.doNotRetry)
            interceptor.retry(response: finalResponse, for: request) { decision in
                retryDecision.value = decision
                sema.signal()
            }
            sema.wait()
            
            switch retryDecision.value {
            case .retry:
                if retryCount < maxRetries {
                    completion(.failure(RetryTriggerError(retryImmediately: true, delay: 0, count: retryCount + 1)))
                    return
                }
            case .retryWithDelay(let delay):
                if retryCount < maxRetries {
                    completion(.failure(RetryTriggerError(retryImmediately: false, delay: delay, count: retryCount + 1)))
                    return
                }
            case .doNotRetry:
                break
            case .doNotRetryWithError(let err):
                completion(.failure(err))
                return
            }
        }
        
        completion(finalResponse)
    }
}
