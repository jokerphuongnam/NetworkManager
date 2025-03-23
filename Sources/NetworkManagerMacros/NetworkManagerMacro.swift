import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct NetworkManagerPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        RestAPIServiceProtocolMacro.self,
        MethodMacro.self,
        ParamMacro.self
    ]
}
