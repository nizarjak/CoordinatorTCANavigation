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
            .init(id: "color-1", name: "Blue", color: .blue, isLiked: false),
            .init(id: "color-2", name: "Green", color: .green, isLiked: false),
            .init(id: "color-3", name: "Red", color: .red, isLiked: false),
            .init(id: "color-4", name: "Yellow", color: .yellow, isLiked: false),
            .init(id: "color-5", name: "Purple", color: .purple, isLiked: false),
            .init(id: "color-6", name: "Orange", color: .orange, isLiked: false),
            .init(id: "color-7", name: "Pink", color: .pink, isLiked: false),
        ]

        var route: Route?
    }

    enum Action: Equatable {
        case pushedDetail(NavigationAction<Detail.Action>)
        case presentedDetail(NavigationAction<Detail.Action>)

        case reservation(String, Reservation.Action)

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

        // reservations - items
        Reservation.reducer.forEach(
            state: \.reservations,
            action: /Action.reservation,
            environment: { _ in () }
        ),

        // navigation
        .init { state, action, _ in
            switch action {
                // present detail
            case .presentedDetail(.onClose), .presentedDetail(.action(.closeButtonTapped)):
                if let route = state.route,
                   case let Route.presentedDetail(detailState) = route {
                    state.reservations[id: detailState.id] = Reservation.State(detail: detailState)
                }
                state.route = nil
                return.none

            case let .reservation(id, .presentButtonTapped):
                guard let reservation = state.reservations[id: id] else { return .none }
                state.route = .presentedDetail(.init(reservation: reservation))
                return .none

                // push detail
            case let .reservation(id, .pushButtonTapped):
                guard let reservation = state.reservations[id: id] else { return .none }
                state.route = .pushedDetail(.init(reservation: reservation))
                return .none

            case .pushedDetail(.onClose), .pushedDetail(.action(.closeButtonTapped)):
                if let route = state.route,
                   case let Route.pushedDetail(detailState) = route {
                    state.reservations[id: detailState.id] = Reservation.State(detail: detailState)
                }
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

extension Detail.State {
    init(reservation: Reservation.State) {
        self.init(id: reservation.id, name: reservation.name, color: reservation.color, isLiked: reservation.isLiked)
    }
}

extension Reservation.State {
    init(detail: Detail.State) {
        self.init(id: detail.id, name: detail.name, color: detail.color, isLiked: detail.isLiked)
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
