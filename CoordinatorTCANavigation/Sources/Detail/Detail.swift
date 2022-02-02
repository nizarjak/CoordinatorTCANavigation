import SwiftUI
import ComposableArchitecture

enum Detail {}

extension Detail {
    enum Action: Equatable {
        case closeButtonTapped
        case closeAllButtonTapped
        case likeButtonTapped

        case onAppear
        case timerTicked

        case editSwiftUIButtonTapped
        case editCoordinatorButtonTapped
        case editSwiftUI(Edit.Action)
        case editCoordinator(NavigationAction<Edit.Action>)
        case editClosed
    }

    enum Route: Equatable {
        case edit(Edit.State)
    }

    struct State: Equatable {
        let id: String
        var name: String
        let color: Color
        var isLiked: Bool
        var openedDuration = 0

        var edit: Edit.State?

        var route: Route?
    }

    struct Environment {}

    struct Effects: Hashable {}

    static let reducer: Reducer<State, Action, Environment> = .combine([
        Edit.reducer.optional().pullback(state: \.edit, action: /Action.editSwiftUI, environment: { _ in () }),

        Edit.reducer._pullback(
            state: (\State.route).appending(path: /Route.edit),
            action: (/Action.editCoordinator).appending(path: /NavigationAction<Edit.Action>.action),
            environment: { _ in () }
        ),

        .init { state, action, _ in
            switch action {
            case .onAppear:
                return Effect
                    .timer(
                        id: "timer",
                        every: 1,
                        on: DispatchQueue.main.eraseToAnyScheduler()
                    )
                    .map { _ in .timerTicked }

            case .timerTicked:
                state.openedDuration += 1

            case .editSwiftUIButtonTapped:
                state.edit = .init(name: state.name)

            case .editCoordinatorButtonTapped:
                state.route = .edit(.init(name: state.name))

            case .editClosed:
                if let name = state.edit?.name {
                    state.name = name
                }
                state.edit = nil

            case .editSwiftUI(.closeAllTapped):
                break

            case .likeButtonTapped:
                state.isLiked.toggle()

            case .closeButtonTapped, .closeAllButtonTapped, .editSwiftUI, .editCoordinator:
                break
            }
            return .none
        },
    ]).cancellable(id: Effects())

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

                    Button("Edit SwiftUI") {
                        viewStore.send(.editSwiftUIButtonTapped)
                    }

                    Button("Edit Coordinator") {
                        viewStore.send(.editCoordinatorButtonTapped)
                    }

                    Button("Close") {
                        viewStore.send(.closeButtonTapped)
                    }

                    Button("Close all") {
                        viewStore.send(.closeAllButtonTapped)
                    }
                }
                .sheet(item: viewStore.binding(get: \.edit, send: Action.editClosed), onDismiss: nil) { _ in
                    IfLetStore(store.scope(state: \.edit, action: Action.editSwiftUI), then: Edit.Screen.init(store:))
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }
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
