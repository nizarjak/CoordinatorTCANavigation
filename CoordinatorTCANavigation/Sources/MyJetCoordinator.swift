import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

class MyJetCoordinator: Coordinator {

    struct State: Equatable {
        var route: Route? = nil
        var state: MyJet.State
    }

    enum Route: Equatable {
        case detail(DetailCoordinator.State)
        case settings

        static func isSameRoute(_ lhs: Route?, _ rhs: Route?) -> Bool {
            switch (lhs, rhs) {
            case (.detail, .detail):
                return true
            case (.settings, .settings):
                return true
            case (.none, .none):
                return true
            default:
                return false
            }
        }
    }

    enum Action: Equatable {
        case detail(DetailCoordinator.Action)
        case action(MyJet.Action)
        case routeDismissed
    }

    struct Environment {
        var environment: MyJet.Environment { .init() }
        var detail: DetailCoordinator.Environment { .init() }
    }

    static let reducer: Reducer<State, Action, Environment> = .combine([
        DetailCoordinator.reducer._pullback(
            state: OptionalPath(\State.route).appending(path: /Route.detail),
            action: /Action.detail,
            environment: \.detail
        ),

        .init { state, action, _ in
            switch action {
            case .action(.pushButtonTapped), .action(.presentButtonTapped):
                state.route = .detail(.init(state: .init()))

//            case .detail(.pushButtonTapped), .detail(.presentButtonTapped):
//                state.route = .detail(.init())

            case .detail(.action(.closeButtonTapped)):
                state.route = nil

            case .detail(.onClose):
                state.route = nil

            case .routeDismissed:
                state.route = nil
            }

            return .none
        },

        MyJet.reducer.pullback(
            state: \State.state,
            action: /Action.action,
            environment: \.environment
        ),
    ]).debug()

    let store: Store<State, Action>
    var rootViewController: UIViewController? { navigationController }

    private weak var detailCoordinator: DetailCoordinator?

    private weak var navigationController: UINavigationController?
    private var cancelables: Set<AnyCancellable> = []

    init(store: Store<State, Action>) {
        self.store = store

        let vc = HostingController(
            rootView: MyJet.View(store: store.scope(state: \.state, action: Action.action)),
            coordinator: self,
            onDeinit: nil // no need to clear state as the coordinator should deallocate
        )
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.navigationItem.largeTitleDisplayMode = .always
        self.navigationController = navigationController

        let detailPath = (\State.route).appending(path: /Route.detail)
        let detailStore = store.scope(state: detailPath.extract(from:), action: Action.detail)

        detailStore.ifLet { [weak self] honestDetailStore in
            let detailCoordinator = DetailCoordinator(store: honestDetailStore)
            detailCoordinator.start(presentedTo: vc)
            self?.detailCoordinator = detailCoordinator
        } else: { [weak self] in
            // dismiss programmatically -> inform UIKit
            self?.detailCoordinator?.stop(animated: true)
        }
        .store(in: &cancelables)
    }
}

extension Optional {
    static var cacheLastSome: (Self) -> Self {
        var lastWrapped: Wrapped?
        return {
            lastWrapped = $0 ?? lastWrapped
            return lastWrapped
        }
    }
}
