import SwiftUI
import ComposableArchitecture

enum Reservations {}

extension Reservations {

    enum Route: Equatable {
        case pushedDetail(Detail.State)
        case presentedDetail(Detail.State)
    }

    struct State: Equatable {
        var reservations: IdentifiedArrayOf<Reservation.State> = [
            .init(id: .init(), name: "Blue", color: .blue),
            .init(id: .init(), name: "Green", color: .green),
            .init(id: .init(), name: "Red", color: .red),
            .init(id: .init(), name: "Yellow", color: .yellow),
            .init(id: .init(), name: "Purple", color: .purple),
            .init(id: .init(), name: "Orange", color: .orange),
            .init(id: .init(), name: "Pink", color: .pink),
        ]

        var route: Route?
    }

    enum Action: Equatable {
        case pushedDetail(NavigationAction<Detail.Action>)
        case presentedDetail(NavigationAction<Detail.Action>)

        case reservation(UUID, Reservation.Action)

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
            environment: \Environment.detail
        ),

        // presented
        Detail.reducer._pullback(
            state: (\State.route).appending(path: /Route.presentedDetail),
            action: (/Action.presentedDetail).appending(path: /NavigationAction<Detail.Action>.action),
            environment: \Environment.detail
        ),

        .init { state, action, _ in
            switch action {
                // present detail
            case .presentedDetail(.onClose), .presentedDetail(.action(.closeButtonTapped)):
                state.route = nil
                return.none

            case let .reservation(id, .presentButtonTapped):
                guard let reservation = state.reservations[id: id] else { return .none }
                state.route = .presentedDetail(.init(name: reservation.name, color: reservation.color))
                return .none

                // push detail
            case let .reservation(id, .pushButtonTapped):
                guard let reservation = state.reservations[id: id] else { return .none }
                state.route = .pushedDetail(.init(name: reservation.name, color: reservation.color))
                return .none

            case .pushedDetail(.onClose), .pushedDetail(.action(.closeButtonTapped)):
                state.route = nil
                return.none

            case .reservation:
                // TODO: [Jakub] Implement navigation
                return .none

            case .closeButtonTapped, .pushedDetail, .presentedDetail:
                return .none
            }
        },
    ])

    struct Screen: View {

        let store: Store<State, Action>

        public init(store: Store<State, Action>) {
            self.store = store
        }

        var body: some View {
            WithViewStore(store.stateless) { viewStore in
                ScrollView {
                    VStack(spacing: 20) {
                        ForEachStore(store.scope(state: \.reservations, action: Reservations.Action.reservation)) {
                            Reservation.View(store: $0)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(15)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Reservations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close", action: { ViewStore(store).send(.closeButtonTapped) })
                }
            }
        }

    }
}

struct Reservations_Preview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Reservations.Screen(store: Store(
                initialState: Reservations.State(),
                reducer: Reservations.reducer,
                environment: Reservations.Environment()
            ))
        }
    }
}
