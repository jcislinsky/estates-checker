import Foundation
import ComposableArchitecture
import CLI
import EstatesProvider
import Persistence

var store = Store(initialValue: AppState(initialEstatesHash: -1, estates: []), reducer: appReducer)

// Loads data from storage
store.send(.persistence(.loadEstatesFromStorage))

// MARK: - Start CLI

MainCLI.store = store.view(
    value: { $0.cli },
    action: { .cli($0) }
)
MainCLI.main()
