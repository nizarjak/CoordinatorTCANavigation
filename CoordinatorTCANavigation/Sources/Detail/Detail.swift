import SwiftUI
import ComposableArchitecture

enum Detail {}

extension Detail {
    enum Action: Equatable {
        case closeButtonTapped
        case closeAllButtonTapped
    }

    struct State: Equatable {}

    struct Environment {}

    static let reducer: Reducer<State, Action, Environment> = .empty

    struct Screen: View {

        let store: Store<State, Action>

        public init(store: Store<State, Action>) {
            self.store = store
        }

        var body: some View {
            WithViewStore(store.stateless) { viewStore in
                VStack(spacing: 20) {
                    Button("Close") {
                        viewStore.send(.closeButtonTapped)
                    }

                    Button("Close all") {
                        viewStore.send(.closeAllButtonTapped)
                    }
                }
            }
            .navigationTitle("Detail")
        }
    }
}
