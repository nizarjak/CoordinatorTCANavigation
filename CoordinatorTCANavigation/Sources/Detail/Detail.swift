import SwiftUI
import ComposableArchitecture

enum Detail {}

extension Detail {
    enum Action: Equatable {
        case closeButtonTapped
        case closeAllButtonTapped
    }

    struct State: Equatable {
        let name: String
        let color: Color
    }

    struct Environment {}

    static let reducer: Reducer<State, Action, Environment> = .empty

    struct Screen: View {

        let store: Store<State, Action>

        public init(store: Store<State, Action>) {
            self.store = store
        }

        var body: some View {
            WithViewStore(store) { viewStore in
                VStack(spacing: 20) {
                    HStack {
                        Text(viewStore.name)

                        Circle()
                            .fill(viewStore.color)
                            .frame(width: 20, height: 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

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

struct Detail_Preview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Detail.Screen(store: Store(
                initialState: Detail.State(name: "Blue", color: .blue),
                reducer: Detail.reducer,
                environment: Detail.Environment()
            ))
        }
    }
}
