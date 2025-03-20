import SharedModels

protocol CallApdaterFactory {
    func isApply(returnsType: String) -> Bool
    func makeCallAdapter(type: NetworkGenerateType, enqueueCall: String) -> String
}

extension CallAdapterType {
    var factory: CallApdaterFactory {
        switch self {
        case .rxSwift:
            return RxSwiftCallAdapterFactory.shared
        case .combine:
            return CombineCallAdapterFactory.shared
        }
    }
}
