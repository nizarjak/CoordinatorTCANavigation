import SwiftUI
import ComposableArchitecture

enum MyJet {}

extension MyJet {

    enum Route: Equatable {
        case pushedReservations(Reservations.State)
        case presentedReservations(Reservations.State)
    }

    struct State: Equatable {
        var route: Route?
    }

    enum Action: Equatable {
        case pushedReservations(NavigationAction<Reservations.Action>)
        case presentedReservations(NavigationAction<Reservations.Action>)
        case cancelEffects([AnyHashable])

        case pushButtonTapped
        case presentButtonTapped
        case deeplinkButtonTapped
    }
    struct Environment {
        var reservations: Reservations.Environment {
            .init()
        }
    }

    static let reducer = Reducer<State, Action, Environment>.combine([
        // presented
        Reservations.reducer._pullback(
            state: (\State.route).appending(path: /Route.presentedReservations),
            action: (/Action.presentedReservations).appending(path: /NavigationAction<Reservations.Action>.action),
            environment: \Environment.reservations
        ),

        // pushed
        Reservations.reducer._pullback(
            state: (\State.route).appending(path: /Route.pushedReservations),
            action: (/Action.pushedReservations).appending(path: /NavigationAction<Reservations.Action>.action),
            environment: \Environment.reservations
        ),

        .init { state, action, environment in
            switch action {
            case .cancelEffects(let hashables):
                return Effect.cancel(ids: hashables)

            // present Reservations
            case .presentedReservations(.onClose), .presentedReservations(.action(.closeButtonTapped)):
                state.route = nil
                return .none

            case .presentButtonTapped:
                state.route = .presentedReservations(.init())
                return .none

            // push Reservations
            case .pushButtonTapped:
                state.route = .pushedReservations(.init())
                return .none

            case .pushedReservations(.onClose), .pushedReservations(.action(.closeButtonTapped)):
                state.route = nil
                return.none

            // deeplink
            case .deeplinkButtonTapped:
                state.route = .presentedReservations(.init(route: .presentedDetail(.init(id: "color-1", name: "Blue", color: .blue, isLiked: false))))
                return .none

            // close all
            case .pushedReservations(.action(.pushedDetail(.action(.closeAllButtonTapped)))),
                    .pushedReservations(.action(.presentedDetail(.action(.closeAllButtonTapped)))),
                    .presentedReservations(.action(.pushedDetail(.action(.closeAllButtonTapped)))),
                    .presentedReservations(.action(.presentedDetail(.action(.closeAllButtonTapped)))),

                    .pushedReservations(.action(.pushedDetail(.action(.editSwiftUI(.closeAllTapped))))),
                    .pushedReservations(.action(.presentedDetail(.action(.editSwiftUI(.closeAllTapped))))),
                    .presentedReservations(.action(.pushedDetail(.action(.editSwiftUI(.closeAllTapped))))),
                    .presentedReservations(.action(.presentedDetail(.action(.editSwiftUI(.closeAllTapped))))),

                    .pushedReservations(.action(.pushedDetail(.action(.editCoordinator(.action(.closeAllTapped)))))),
                    .pushedReservations(.action(.presentedDetail(.action(.editCoordinator(.action(.closeAllTapped)))))),
                    .presentedReservations(.action(.pushedDetail(.action(.editCoordinator(.action(.closeAllTapped)))))),
                    .presentedReservations(.action(.presentedDetail(.action(.editCoordinator(.action(.closeAllTapped)))))):
                state.route = nil
                return .none

            case .pushedReservations(.action(.pushedDetail(.onClose))),
                    .pushedReservations(.action(.presentedDetail(.onClose))),
                    .presentedReservations(.action(.pushedDetail(.onClose))),
                    .presentedReservations(.action(.presentedDetail(.onClose))):
                Log.debug("detail onClose called")
                return .none

            case .presentedReservations, .pushedReservations:
                return .none
            }
        },
    ])
    .debug()
}

extension MyJet {
    struct Screen: View {

        let store: Store<State, Action>
        @ObservedObject var viewStore: ViewStore<Void, Action>

        init(store: Store<State, Action>) {
            self.store = store
            self.viewStore = ViewStore(store.stateless)
        }

        var body: some View {
            VStack(spacing: 20) {
                Button("Push") { viewStore.send(.pushButtonTapped) }

                Button("Present") { viewStore.send(.presentButtonTapped) }

                Button("Deeplink") { viewStore.send(.deeplinkButtonTapped) }
            }
            .navigationTitle("MyJet")
        }
    }
}

struct MyJetView_Previews: PreviewProvider {
    static var previews: some View {
        MyJet.Screen(
            store: .init(
                initialState: .init(),
                reducer: MyJet.reducer,
                environment: MyJet.Environment()
            )
        )
    }
}
