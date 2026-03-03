/// Defines a creative style for error message rewriting.
///
/// The generation engine reads ``promptHint`` and ``temperature`` to
/// configure how the model rewrites error messages. Consumers can
/// conform their own types for exhaustive switching:
///
/// ```swift
/// enum BrandStyle: String, ErrorStyle, CaseIterable {
///     case klingon, apologetic, legalese
///
///     var promptHint: String {
///         switch self {
///         case .klingon: "Write it as a Klingon warrior declaration."
///         case .apologetic: "Write an overly apologetic message."
///         case .legalese: "Write it as dense legal boilerplate."
///         }
///     }
///
///     var temperature: Double { 0.9 }
/// }
/// ```
public protocol ErrorStyle: Hashable, Sendable {
    /// Instruction appended to the prompt telling the model how to write.
    var promptHint: String { get }
    /// Sampling temperature for this style, clamped to `0.0...1.0` by the engine.
    ///
    /// Defaults to `1.0`. Override to control sampling creativity per style.
    var temperature: Double { get }
}

extension ErrorStyle {
    public var temperature: Double { 1.0 }
}
