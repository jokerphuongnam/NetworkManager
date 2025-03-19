import NetworkManagerMacros

@attached(peer, names: suffixed(Impl))
public macro NetworkGenerateProtocol(_ type: NetworkGenerateType = .struct, _ path: String = "", allowCookie: Bool? = nil) = #externalMacro(module: "NetworkManagerMacros", type: "NetworkGenerateProtocolMacro")
