import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct NetworkManagerPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        NetworkGenerateProtocolMacro.self,
        MethodMacro.self,
        ParamMacro.self
    ]
}
