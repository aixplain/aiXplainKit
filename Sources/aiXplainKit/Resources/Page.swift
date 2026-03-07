import Foundation

/// Generic pagination container.
///
/// Mirrors Python v2 `Page(Generic[ResourceT])` from `resource.py`.
public struct Page<T>: @unchecked Sendable {
    public let results: [T]
    public let pageNumber: Int
    public let pageTotal: Int
    public let total: Int

    public init(results: [T], pageNumber: Int, pageTotal: Int, total: Int) {
        self.results = results
        self.pageNumber = pageNumber
        self.pageTotal = pageTotal
        self.total = total
    }

    public var isEmpty: Bool { results.isEmpty }
    public var count: Int { results.count }
}
