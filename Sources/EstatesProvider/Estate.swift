import Foundation

public struct Estate: Codable, Hashable {
    public let title: String
    public let url: String

    public init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}
