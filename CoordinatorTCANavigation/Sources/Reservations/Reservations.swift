import SwiftUI
import ComposableArchitecture

enum Reservations {}

extension Reservations {

    enum Route: Equatable {
        case pushedDetail(Detail.State)
        case presentedDetail(Detail.State)
    }

    struct State: Equatable {
        var route: Route?
    }

    enum Action: Equatable {
        case pushedDetail(NavigationAction<Detail.Action>)
        case presentedDetail(NavigationAction<Detail.Action>)

        case pushButtonTapped
        case presentButtonTapped
        case closeButtonTapped
    }

    struct Environment {
        var detail: Detail.Environment {
            .init()
        }
    }

    static let reducer: Reducer<State, Action, Environment> = .combine([
        // pushed
        Detail.reducer._pullback(
            state: (\State.route).appending(path: /Route.pushedDetail),
            action: (/Action.pushedDetail).appending(path: /NavigationAction<Detail.Action>.action),
            environment: \Environment.detail,
            breakpointOnNil: false
        ),

        // presented
        Detail.reducer._pullback(
            state: (\State.route).appending(path: /Route.presentedDetail),
            action: (/Action.presentedDetail).appending(path: /NavigationAction<Detail.Action>.action),
            environment: \Environment.detail,
            breakpointOnNil: false
        ),

        .init { state, action, _ in
            switch action {
                // present detail
            case .presentedDetail(.onClose), .presentedDetail(.action(.closeButtonTapped)):
                state.route = nil
                return.none

            case .presentButtonTapped:
                state.route = .presentedDetail(.init())
                return .none

                // push detail
            case .pushButtonTapped:
                state.route = .pushedDetail(.init())
                return .none

            case .pushedDetail(.onClose), .pushedDetail(.action(.closeButtonTapped)):
                state.route = nil
                return.none

            case .closeButtonTapped, .pushedDetail, .presentedDetail:
                break
            }
            return .none
        },
    ])

    struct Screen: View {

        let store: Store<State, Action>

        public init(store: Store<State, Action>) {
            self.store = store
        }

        var body: some View {
            WithViewStore(store.stateless) { viewStore in
                VStack(spacing: 20) {
                    Button("Push") {
                        viewStore.send(.pushButtonTapped)
                    }

                    Button("Present") {
                        viewStore.send(.presentButtonTapped)
                    }

                    Button("Close") {
                        viewStore.send(.closeButtonTapped)
                    }
                }
            }
            .navigationTitle("Reservations")
        }

    }
}
