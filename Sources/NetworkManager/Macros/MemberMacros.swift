@attached(peer)
public macro CONNECT(_ path: String = "") = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro DELETE(_ path: String = "") = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro GET(_ path: String = "") = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro HEAD(_ path: String = "") = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro OPTIONS(_ path: String = "") = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro PATCH(_ path: String = "") = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro POST(_ path: String = "") = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro PUT(_ path: String = "") = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro QUERY(_ path: String = "") = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro TRACE(_ path: String = "") = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro Request(_ path: String = "", method: String) = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro HEADER(key: String, _ value: String) = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro HEADER(_ headers: [String: String]) = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")

@attached(peer)
public macro AllowCookie(_ isAllow: Bool = false) = #externalMacro(module: "NetworkManagerMacros", type: "MethodMacro")
