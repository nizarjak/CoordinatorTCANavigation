import SwiftUI
import ComposableArchitecture

enum Detail {}

extension Detail {
    enum Action: Equatable {
//        case pushButtonTapped
//        case presentButtonTapped
        case closeButtonTapped
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
                VStack {
//                    Button("Push") {
//                        viewStore.send(.pushButtonTapped)
//                    }
//
//                    Button("Present") {
//                        viewStore.send(.presentButtonTapped)
//                    }

                    Button("Close") {
                        viewStore.send(.closeButtonTapped)
                    }
                }
            }
        }

    }
}
