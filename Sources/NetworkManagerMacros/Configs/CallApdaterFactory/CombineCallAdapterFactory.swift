import Foundation
import SharedModels

struct CombineCallAdapterFactory: CallApdaterFactory {
    static let shared: CombineCallAdapterFactory = .init()
    
    private init() {}
    
    public func isApply(returnsType: String) -> Bool {
        let pattern = #"(^|\.)(Future<([^<>]+|<[^<>]+>)*, Error>)$"#
        return returnsType.range(of: pattern, options: .regularExpression) != nil
    }
    
    public func makeCallAdapter(type: NetworkGenerateType, enqueueCall: String) -> String {
        """
            return Future {\(type.isRefType ? " [weak self, weak call]": "") promise in\(type.isRefType ? """
                    
                        guard let call else {
                            return
                        }
                        guard let self else {
                            call.cancel()
                            return
                        }
                    """ : "")
                \(enqueueCall
                    .replacingOccurrences(of: "{success}", with: "promise(.success(response))")
                    .replacingOccurrences(of: "{error}", with: "promise(.failure(error))")
                )
        }
        """
    }
}
