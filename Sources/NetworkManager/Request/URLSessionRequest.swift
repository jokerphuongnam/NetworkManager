import Foundation

struct URLSessionRequest: Request {
    private let task: URLSessionDataTask?
    
    init(task: URLSessionDataTask?) {
        self.task = task
    }
    
    func resume() {
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
    }
}
