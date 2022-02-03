import Foundation

enum NavigationAction<Action: Equatable>: Equatable {
    case action(Action)
    case onInteractiveClose
}

import ComposableArchitecture
extension Store {
    public func scope<LocalAction>(
        action fromLocalAction: @escaping (LocalAction) -> Action
    ) -> Store<State, LocalAction> {
        return self.scope(state: { $0 }, action: fromLocalAction)
    }
}
