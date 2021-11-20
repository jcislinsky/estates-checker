import Foundation
import ComposableArchitecture
import EstatesProvider
import Notifications
import Storage

public enum CLIError: Swift.Error, Hashable {
    case invalidSlackUrl
    case invalidProvider(availableProviders: [String])
    case invalidRegion(availableRegions: [String])
}

public struct CLIState: Hashable {
    public struct Shared: Hashable {
        public var slackUrl: URL?
        public var estates: [Estate]

        public init(slackUrl: URL?, estates: [Estate]) {
            self.slackUrl = slackUrl
            self.estates = estates
        }
    }
    public struct Inner: Hashable {
        var validationError: CLIError?

        public init() {
            self.validationError = nil
        }
    }

    public var shared: Shared
    public var inner: Inner

    public init(shared: Shared, inner: Inner) {
        self.shared = shared
        self.inner = inner
    }

    public static func == (lhs: CLIState, rhs: CLIState) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

public enum CLIAction {
    case receivedSlackUrl(URL)
    case validate(provider: String, region: String)
    case explore(provider: String, region: String)
    case receivedEstates([Estate])
    case exploreFailed(provider: String, region: String, error: Error)

    case notifyAboutNewEstates([Estate])
    
    case failedToSendNotification(Error)
    case notificationSent

    case finishedRun
}

public func cliReducer(state: inout CLIState, action: CLIAction) -> [Effect<CLIAction>] {
    switch action {
    case .receivedSlackUrl(let url):
        state.shared.slackUrl = url
        return []

    case let .validate(providerName, regionName):
        guard let provider = allEstatesProviders.first(where: { $0.providerName == providerName }) else {
            state.inner.validationError = .invalidProvider(availableProviders: allEstatesProviders.map { $0.providerName })
            return []
        }
        guard provider.isRegionNameValid(regionName) else {
            state.inner.validationError = .invalidRegion(availableRegions: provider.availableRegions)
            return []
        }
        return []

    case let .explore(provider, region):
        return allEstatesProviders
            .first { $0.providerName == provider }!
            .exploreEffects(region: region).map { effect in
                effect.map { result -> CLIAction in
                    switch result {
                    case .success(let estates): return .receivedEstates(estates)
                    case .failure(let error): return .exploreFailed(provider: provider, region: region, error: error)
                    }
                }
            }

    case .receivedEstates(let estates):
        let oldEstates = Set(state.shared.estates)
        let newUniqEstates = Set(estates).subtracting(oldEstates)
        state.shared.estates += newUniqEstates
        return !newUniqEstates.isEmpty
            ? [Effect(value: .notifyAboutNewEstates(Array(newUniqEstates)))]
            : []

    case .exploreFailed(provider: let provider, region: let region, error: let error):
        return [
            sendNotification((title: "Failed to explore \(provider) for \(region)", content: error.localizedDescription), state.shared.slackUrl!)
                .map(success: CLIAction.notificationSent, error: CLIAction.failedToSendNotification)

        ]

    case .notifyAboutNewEstates(let estates):
        //estates.forEach {
        //    print("\($0.title), \($0.url)")
        //}
        //return []
        return estates.map {
            sendNotification((title: $0.title, content: $0.url), state.shared.slackUrl!)
                .map(success: CLIAction.notificationSent, error: CLIAction.failedToSendNotification)
        }

    case .failedToSendNotification:
        return []

    case .notificationSent:
        return []

    case .finishedRun:
        return []
    }
}
