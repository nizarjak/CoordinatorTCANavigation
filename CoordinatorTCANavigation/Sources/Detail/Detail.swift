import SwiftUI
import ComposableArchitecture

enum Detail {}

extension Detail {
    enum Action: Equatable {
        case closeButtonTapped
        case closeAllButtonTapped
        case likeButtonTapped
    }

    struct State: Equatable {
        let id: String
        let name: String
        let color: Color
        var isLiked: Bool
    }

    struct Environment {}

    static let reducer = Reducer<State, Action, Environment> { state, action, _ in
        switch action {
        case .likeButtonTapped:
            state.isLiked.toggle()

        case .closeButtonTapped, .closeAllButtonTapped:
            break
        }
        return .none
    }

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

                        Button(action: { viewStore.send(.likeButtonTapped) }) {
                            Image(systemName: viewStore.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .foregroundColor(viewStore.color)
                        }
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
                initialState: Detail.State(id: "color-1", name: "Blue", color: .blue, isLiked: true),
                reducer: Detail.reducer,
                environment: Detail.Environment()
            ))
        }
    }
}
