import Foundation
import SharedModels

struct RxSwiftCallAdapterFactory: CallApdaterFactory {
    static let shared: RxSwiftCallAdapterFactory = .init()
    
    private init() {}
    
    public func isApply(returnsType: String) -> Bool {
        let pattern = #"(^|\.)(Single<([^<>]+|<[^<>]+>)*>)$"#
        return returnsType.range(of: pattern, options: .regularExpression) != nil
    }
    
    public func makeCallAdapter(type: NetworkGenerateType, enqueueCall: String) -> String {
        """
            return Single.create {\(type.isRefType ? " [weak self, weak call]": "") single in\(type.isRefType ? """
                    
                    guard let call else {
                        return
                    }
                    guard let self else {
                        call.cancel()
                        return
                    }
                    """ : "")
                \(enqueueCall
                    .replacingOccurrences(of: "{success}", with: "single(.success(response))")
                    .replacingOccurrences(of: "{error}", with: "single(.failure(error))")
                )
            return Disposables.create { \(type.isRefType ? " [weak self, weak call] in": "")\(type.isRefType ? """
                    
                            guard let call else {
                                return
                            }
                    """ : "")
                call.cancel()
            }
        }
        """
    }
}
