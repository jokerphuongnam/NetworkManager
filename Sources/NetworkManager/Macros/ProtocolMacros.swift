public import SharedModels

@attached(peer, names: suffixed(Impl))
public macro NetworkGenerateProtocol(_ type: NetworkGenerateType = .struct, path: String = "", allowCookie: Bool? = nil, callAdapter: CallAdapterType? = nil) = #externalMacro(module: "NetworkManagerMacros", type: "NetworkGenerateProtocolMacro")
