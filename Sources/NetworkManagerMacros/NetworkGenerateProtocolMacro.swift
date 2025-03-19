import SwiftSyntaxBuilder
import Foundation
import SwiftSyntaxMacros
import SwiftSyntax
import SwiftCompilerPluginMessageHandling
import SwiftDiagnostics

public struct NetworkGenerateProtocolMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let protocolDecl = try Self.getProtocolDecl(of: node, providingPeersOf: declaration, in: context)
        let typeKeyword = Self.extractNetworkGenerateType(from: node)
        let isAllowCookie = Self.extractAllowCookie(from: node)
        
        let protocolName = protocolDecl.name.text
        let className = "\(protocolName)Impl"
        
        let properties = try protocolDecl.memberBlock.members.compactMap { member -> String? in
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                return try Self.getVariableDeclSyntax(varDecl)
            }
            return nil
        }
        
        let methods = try protocolDecl.memberBlock.members.compactMap { member -> String? in
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                return try Self.getFunctionDeclSyntax(of: node, funcDecl,in: context, isAllowCookie: isAllowCookie)
            }
            return nil
        }
        
        let classImplementation = """
            \(typeKeyword.swiftString) \(className): \(protocolName) {
                private let session: NetworkSession
                private let headers: [String: String]
                private let interceptors: [NMInterceptor]
            
                init(
                    session: NetworkSession,
                    headers: [String: String] = [:],
                    interceptors: [NMInterceptor] = []
                ) {
                    self.session = session
                    self.headers = headers
                    self.interceptors = interceptors
                }
                \(properties.joined(separator: "\n    "))
                
                \(methods.joined(separator: "\n    "))
            }
            """
        
        return [DeclSyntax(stringLiteral: classImplementation)]
    }
    
    private static func getProtocolDecl(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> ProtocolDeclSyntax {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            context.diagnose(
                NetworkManagerDiagnostics().diagnostic(
                    for: node,
                    message: "@NetworkGenerateProtocol can only be applied to protocols",
                    id: "Conform protocol"
                )
            )
            throw MacroExpansionErrorMessage("@NetworkGenerateProtocol can only be applied to protocols")
        }
        return protocolDecl
    }
    
    private static func extractNetworkGenerateType(from node: AttributeSyntax) -> NetworkGenerateType {
        guard let argumentList = node.arguments?.as(LabeledExprListSyntax.self),
              let firstArgument = argumentList.first?.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        else {
            return .struct
        }
        
        switch firstArgument {
        case "class":
            return .class
        case "actor":
            return .actor
        default:
            return .struct
        }
    }
    
    private static func extractAllowCookie(from node: AttributeSyntax) -> Bool? {
        guard let argumentList = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        
        for argument in argumentList {
            if argument.label?.text == "allowCookie" {
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    return boolLiteral.literal.tokenKind == .keyword(.true)
                }
            }
        }
        
        return nil
    }
    
    private static func getFunctionDeclSyntax(
        of node: AttributeSyntax,
        _ funcDecl: FunctionDeclSyntax,
        in context: some MacroExpansionContext,
        isAllowCookie: Bool?
    ) throws -> String {
        let functionName = funcDecl.name.text
        let attributes = attributesBuild(funcDecl.attributes)
        let (params, paths, queries, headers, body, cookie, interceptors, interceptorsArray) = try parameterBuild(
            of: node,
            funcDecl.signature,
            in: context
        )
        
        let returnType = funcDecl.signature.returnClause?.type.description.trimmingCharacters(in: .whitespaces)
        let returnTypeString: String
        if let returnType {
            returnTypeString = " -> \(returnType)"
        } else {
            returnTypeString = ""
        }
        let pathAfterReplacePath = try replacePathPlaceholders(of: node, in: context, path: attributes.memberPath, paths: paths)
        let pathWithQuery = appendQueriesToPath(path: String(pathAfterReplacePath.dropLast()), queries: queries) + "\""
        
        var appendHeaders = [String]()
        for header in headers {
            appendHeaders.append("headers[\"\(header.replacingOccurrences(of: "_", with: "-"))\"] = \(header).value")
        }
        let isAllowCookie = attributes.isAllowCookie ?? isAllowCookie
        let cookieStr = cookie ?? "nil"
        let interceptorsArrayStr = if interceptorsArray.isEmpty {
            ""
        } else {
            " + \(interceptorsArray.joined(separator: " + "))"
        }
        return """
            func \(functionName)(\(params))\(returnTypeString) {
                    \(appendHeaders.isEmpty ? "let" : "var") headers = \(attributes.headers).merging(self.headers) { new, _ in new }
                    \(appendHeaders.joined(separator: "\n        "))
                    \(interceptors.isEmpty ? "let" : "var") requestInterceptor = self.interceptors\(interceptorsArrayStr)
                    \(interceptors.map { "requestInterceptor.append(\($0))" }.joined(separator: "\n        "))
                    return session.request(
                        url: \(pathWithQuery),
                        method: \(attributes.method),
                        headers: headers,
                        isDefaultCookie: \(boolToString(isAllowCookie)),
                        cookie: \(cookieStr),
                        interceptors: requestInterceptor\(body == nil ? "": ",\n            body: body")
                    )
            }
            """
    }
    
    private static func boolToString(_ value: Bool?) -> String {
        if let value {
            return String(value)
        }
        return "nil"
    }
    
    private static func replacePathPlaceholders(
        of node: AttributeSyntax,
        in context: some MacroExpansionContext,
        path: String,
        paths: [String]
    ) throws -> String {
        var result = path
        
        // Extract placeholders from the path (e.g., {a}, {b})
        let placeholderPattern = #"\{(\w+)\}"#
        let regex = try NSRegularExpression(pattern: placeholderPattern)
        let matches = regex.matches(in: path, range: NSRange(path.startIndex..., in: path))
        
        // Collect all placeholders from the path
        var placeholders = Set<String>()
        for match in matches {
            if let range = Range(match.range(at: 1), in: path) {
                placeholders.insert(String(path[range]))
            }
        }
        
        // Find missing parameters
        let missingParams = placeholders.subtracting(paths)
        if !missingParams.isEmpty {
            let msgError = "\(missingParams.joined(separator: ", ")) need to fill path on function parameters"
            context.diagnose(
                NetworkManagerDiagnostics().diagnostic(
                    for: node,
                    message: msgError,
                    id: "Need fill path"
                )
            )
            throw MacroExpansionErrorMessage(msgError)
        }
        
        // Replace placeholders with interpolation
        for key in paths {
            result = result.replacingOccurrences(of: "{\(key)}", with: "\\(\(key).value)")
        }
        
        return result
    }
    
    private static func appendQueriesToPath(path: String, queries: [String]) -> String {
        var result = path
        let queryString = queries.map { "\($0)=\\(\($0).value)" }.joined(separator: "&")
        
        if let queryStartIndex = result.firstIndex(of: "?") {
            let queryInsertionIndex = result.index(after: queryStartIndex)
            result.insert("&", at: queryInsertionIndex)
            result.insert(contentsOf: queryString, at: result.index(after: queryStartIndex))
        } else {
            result += "?\(queryString)"
        }
        
        return result
    }
    
    private static func getVariableDeclSyntax(_ varDecl: VariableDeclSyntax) throws -> String {
        let bindings = try varDecl.bindings.compactMap { binding  -> String? in
            var isAsyncGet: Bool = false
            var isThrowsGet: Bool = false
            if let accessorBlock = binding.accessorBlock {
                let accessorDeclList =  accessorBlock.accessors.cast(AccessorDeclListSyntax.self)
                let hasSetter = accessorDeclList.contains { accessor in
                    return accessor.accessorSpecifier.tokenKind == .keyword(.set)
                }
                if hasSetter {
                    throw MacroExpansionErrorMessage("@NetworkGenerateProtocol can only be used on read-only variable")
                }
                
                isAsyncGet = accessorDeclList.contains { accessor in
                    if accessor.accessorSpecifier.tokenKind == .keyword(.get) {
                        return accessor.effectSpecifiers?.asyncSpecifier?.tokenKind == .keyword(.async)
                    }
                    return false
                }
                isThrowsGet = accessorDeclList.contains { accessor in
                    if accessor.accessorSpecifier.tokenKind == .keyword(.get) {
                        return accessor.effectSpecifiers?.throwsClause != nil
                    }
                    return false
                }
            }
            
            // Extract var name and type
            let varName = binding.pattern.description.trimmingCharacters(in: .whitespaces)
            let varType = binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespaces) ?? "Any"
            
            //            let attribute = attributeBuild(varDecl.attributes)
            
            if isAsyncGet || isThrowsGet {
                let asyncText = if isAsyncGet { " async" } else { "" }
                let throwsText = if isThrowsGet { " throws" } else { "" }
                return """
                var \(varName): \(varType) {
                        get\(asyncText)\(throwsText) {
                    
                        }
                }
                """
            } else {
                return """
                var \(varName): \(varType) {
                    
                }
                """
            }
        }
        return bindings.joined(separator: "\n    ")
    }
    
    private static func parameterBuild(
        of node: AttributeSyntax,
        _ signature: FunctionSignatureSyntax,
        in context: some MacroExpansionContext
    ) throws -> (header: String, paths: [String], queries: [String], params: [String], body: String?, cookie: String?, interceptors: [String], interceptorsArray: [String]) {
        var params = [String]()
        var paths = [String]()
        var queries = [String]()
        var headers = [String]()
        var body: String? = nil
        var cookie: String?
        var interceptors: [String] = []
        var interceptorsArray: [String] = []
        
        for param in signature.parameterClause.parameters {
            let label = param.firstName.text
            let name = param.secondName?.text ?? param.firstName.text
            let paramType = param.type.description.trimmingCharacters(in: .whitespaces)
            
            
            let labelText = if param.secondName == nil {
                ""
            } else {
                "\(label) "
            }
            
            if name == "body" {
                body = name
            } else if paramType.hasPrefix("HTTPCookie") {
                if cookie == nil {
                    cookie = name
                } else {
                    context.diagnose(
                        NetworkManagerDiagnostics().diagnostic(
                            for: node,
                            message: "Cookie only appear once time",
                            id: "Single cookie on request"
                        )
                    )
                    throw MacroExpansionErrorMessage("Cookie only once time")
                }
            } else if isInterceptorsArray(paramType) {
                interceptorsArray.append(name)
            } else if isInterceptor(paramType) {
                interceptors.append(name)
            } else if isPath(paramType) {
                paths.append(name)
            } else if isQuery(paramType) {
                queries.append(name)
            } else if isHeader(paramType) {
                headers.append(name)
            }
            
            params.append("\(labelText)\(name): \(paramType)")
        }
        
        let paramString = params.joined(separator: ", ")
        
        return (
            paramString,
            paths,
            queries,
            headers,
            body,
            cookie,
            interceptors,
            interceptorsArray
        )
    }
    
    private static func isQuery(_ typeString: String) -> Bool {
        let pattern = #"(^|\.)Query<[^,<>]+>$"#
        return typeString.range(of: pattern, options: .regularExpression) != nil
    }
    
    private static func isPath(_ typeString: String) -> Bool {
        let pattern = #"(^|\.)(Path<[^,<>]+>)$"#
        return typeString.range(of: pattern, options: .regularExpression) != nil
    }
    
    private static func isHeader(_ typeString: String) -> Bool {
        let pattern = #"(^|\.)Header$"#
        return typeString.range(of: pattern, options: .regularExpression) != nil
    }
    
    private static func isInterceptor(_ typeString: String) -> Bool {
        let pattern = #"(?:^|\.)(NMInterceptor)$"#
        return typeString.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
    
    private static func isInterceptorsArray(_ typeString: String) -> Bool {
        let pattern = #"\[(?:.*\.)?NMInterceptor\]"#
           return typeString.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
    
    private static func attributesBuild(_ attributes: AttributeListSyntax) -> AtrributeValue {
        var memberPath: String = ""
        var method: String = ""
        var headers: [String: String] = [:]
        var isAllowCookie: Bool? = nil
        for attr in attributes {
            if let attribute = attr.as(AttributeSyntax.self) {
                let attributeName = attribute.attributeName
                let arguments = attr.as(AttributeSyntax.self)?.arguments?.as(LabeledExprListSyntax.self)
                
                if ["CONNECT", "DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT", "QUERY", "TRACE"].contains(attributeName.description) {
                    let nameDescription = attributeName.description
                    let firstArgument = arguments?.first?.expression.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    memberPath = firstArgument
                    method = "\"" + nameDescription + "\""
                } else if attributeName.description == "Request" {
                    memberPath = arguments?.first?.expression.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    method = arguments?.dropFirst().first?.expression.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                } else if attributeName.description == "HEADER" {
                    if let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) {
                        // Handle HEADER(key: value)
                        if arguments.count == 2,
                           let keyExpr = arguments.first?.expression,
                           let valueExpr = arguments.last?.expression {
                            
                            let key = keyExpr.description.trimmingCharacters(in: .whitespacesAndNewlines)
                            let value = valueExpr.description.trimmingCharacters(in: .whitespacesAndNewlines)
                            headers[String(key.dropFirst().dropLast())] = String(value.dropFirst().dropLast())
                        } else if arguments.count == 1,
                                  let singleArg = arguments.first?.expression,
                                  let dictExpr = singleArg.as(DictionaryExprSyntax.self) {
                            
                            // Handle HEADER([:])
                            if case let .elements(elements) = dictExpr.content {
                                for element in elements {
                                    let key = element.value.description
                                    let value = element.key.description
                                    headers[String(key.dropFirst().dropLast())] = String(value.dropFirst().dropLast())
                                }
                            }
                        }
                    }
                } else if attributeName.description == "AllowCookie" {
                    if let value = arguments?.first?.expression.description {
                        isAllowCookie = !value.isEmpty && value == "true"
                    } else {
                        isAllowCookie = false
                    }
//                    if let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) {
//                        for argument in arguments {
//                            test = argument.
//                            if let labeledExpr = argument.as(LabeledExprSyntax.self),
//                               labeledExpr.label?.text == "isAllow",
//                               let value = labeledExpr.expression.as(BooleanLiteralExprSyntax.self) {
//                                isAllowCookie = value.literal.tokenKind == .keyword(.true)
//                            }
//                        }
//                    } else {
//                        isAllowCookie = false
//                    }
                }
            }
        }
        
        return AtrributeValue(
            memberPath: memberPath,
            method: method,
            headers: headers,
            isAllowCookie: isAllowCookie
        )
    }
    
}

struct AtrributeValue {
    let memberPath: String
    let method: String
    let headers: [String: String]
    let isAllowCookie: Bool?
}

struct ParameterValue {
    let name: String
}

enum ParameterType {
    case query
    case path
    case header
}
