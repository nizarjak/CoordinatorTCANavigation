import Foundation
import SwiftUI
import ComposableArchitecture

enum Reservation {}

extension Reservation {

    enum Route: Equatable {
        case pushedDetail(Detail.State)
        case presentedDetail(Detail.State)
    }

    struct State: Equatable, Identifiable {
        let id: String
        let name: String
        let color: Color
        var isLiked: Bool

        var route: Route?
    }

    enum Action: Equatable {
        case pushedDetail(NavigationAction<Detail.Action>)
        case presentedDetail(NavigationAction<Detail.Action>)

        case pushButtonTapped
        case presentButtonTapped
        case likeButtonTapped
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
           case .likeButtonTapped:
               state.isLiked.toggle()

           // present detail
           case .presentedDetail(.onSystemClose), .presentedDetail(.action(.closeButtonTapped)):
               state.route = nil
               return .none

           case .presentButtonTapped:
               state.route = .presentedDetail(.init(id: state.id, name: state.name, color: state.color, isLiked: state.isLiked))
               return .none

               // push detail
           case .pushButtonTapped:
               state.route = .pushedDetail(.init(id: state.id, name: state.name, color: state.color, isLiked: state.isLiked))
               return .none

           case .pushedDetail(.onSystemClose), .pushedDetail(.action(.closeButtonTapped)):
               state.route = nil
               return.none

           case .pushedDetail(.action(.editSwiftUI(.closeToReservationsTapped))),
                   .pushedDetail(.action(.editCoordinator(.action(.closeToReservationsTapped)))),
                   .presentedDetail(.action(.editSwiftUI(.closeToReservationsTapped))),
                   .presentedDetail(.action(.editCoordinator(.action(.closeToReservationsTapped)))):
               state.route = nil
               return .none

           case .pushButtonTapped, .presentButtonTapped, .pushedDetail, .presentedDetail:
               break
           }
           return .none
       },


    ])

    struct View: SwiftUI.View {

        let store: Store<State, Action>

        var body: some SwiftUI.View {
            WithViewStore(store) { viewStore in
                VStack {
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

                    HStack {
                        Button("Push", action: { viewStore.send(.pushButtonTapped) })
                            .frame(maxWidth: .infinity)


                        Button("Present", action: { viewStore.send(.presentButtonTapped) })
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .frame(height: 100)
            }
        }
    }
}

//struct Reservation_Preview: PreviewProvider {
//    static var previews: some View {
//        Reservation.View(store: Store(
//            initialState: .init(id: .init(), name: "Green", color: .green, isLiked: true),
//            reducer: Reservation.reducer,
//            environment: ()
//        ))
//    }
//}
