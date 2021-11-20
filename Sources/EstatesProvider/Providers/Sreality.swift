import Foundation
import ComposableArchitecture
import Networking

public struct Sreality: EstatesProvider {
    public typealias Region = String

    fileprivate static let regions: [String: Region] = [
        "Stochov": "3729",
        "Kladno": "3661"
    ]

    static func flatBuyUrl(with region: String) -> URL {
        return URL(string: "https://www.sreality.cz/api/cs/v2/estates?category_main_cb=1&category_type_cb=1&per_page=20&region=\(region)")!
    }
    static func flatRentUrl(with region: String) -> URL {
        return URL(string: "https://www.sreality.cz/api/cs/v2/estates?category_main_cb=1&category_type_cb=2&per_page=20&region=\(region)")!
    }
    static func pozemkyUrl(with region: Region) -> URL {
        return URL(string: "https://www.sreality.cz/api/cs/v2/estates?category_main_cb=3&category_type_cb=1&per_page=100&region_entity_id=\(region)&region_entity_type=municipality")!
    }
    static func domyUrl(with region: Region) -> URL {
        return URL(string: "https://www.sreality.cz/api/cs/v2/estates?category_main_cb=2&category_type_cb=1&per_page=100&region_entity_id=\(region)&region_entity_type=municipality")!
    }

    public static func exploreEffects(region: Region) -> [Effect<Result<[Estate], Error>>] {
        let makeEffect: (URL, String) -> Effect<Result<[Estate], Error>> = { url, emoji in
            dataTask(with: url)
                .sync()
                .validate()
                .decode(as: Sreality.Response.self)
                .map { result in
                    switch result {
                    case .success(let response):
                        let estates = response._embedded.estates
                            .filter { $0.region_tip == 0 }
                            .map { Estate(title: "\(emoji) " + $0.title, url: $0.url ?? "Unknown url") }
                        return .success(estates)
                    case .failure(let error):
                        return .failure(error)
                    }
                }
        }

        return [
            makeEffect(Sreality.flatBuyUrl(with: region), "🏢"),
            makeEffect(Sreality.flatRentUrl(with: region), "🏢🕺"),
            makeEffect(Sreality.domyUrl(with: Self.regions[region]!), "🏠"),
            makeEffect(Sreality.pozemkyUrl(with: Self.regions[region]!), "🗺")
        ]
    }
}

// MARK: - Model

extension Sreality {

    struct Response: Decodable {
        let _embedded: Embedded

        struct Embedded: Decodable {
            let estates: [SrealityEstate]

            struct SrealityEstate: Decodable {
                let hash_id: Int
                let name: String
                let region_tip: Int
                let price: Int
                let seo: Seo

                var formattedPrice: String {
                    "\(numberFormatter.string(for: price)!) Kč"
                }

                var locality: String { seo.locality }
                var title: String {
                    "\(name), \(formattedPrice)"
                }
                var disposition: String? {
                    name.matches(for: #"([1-9]\+(?:kk|1))"#).first
                }
                var dispositionUrl: String? {
                    disposition?.folding(options: .diacriticInsensitive, locale: .init(identifier: "cs"))
                }
                var surface: String? {
                    name.matches(for: #"[1-9][0-9]+ m²"#).first
                }

                var url: String? {
                    if let dispositionUrl = dispositionUrl {
                        return "https://www.sreality.cz/detail/prodej/byt/\(dispositionUrl)/\(locality)/\(hash_id)"
                    } else {
                        return "https://www.sreality.cz/detail/prodej/pozemek/bydleni/\(locality)/\(hash_id)"
                    }
                }

                struct Seo: Decodable {
                    let locality: String
                }
            }
        }
    }
}

// MARK: - EstatesProvider

extension EstatesProvider where Self == Sreality {
    public static var providerName: String { "sreality" }
    
    public static var availableRegions: [String] {
        Array(Self.regions.keys)
    }

    public static func isRegionNameValid(_ region: String) -> Bool {
        Self.regions.keys.contains(region)
    }
}
