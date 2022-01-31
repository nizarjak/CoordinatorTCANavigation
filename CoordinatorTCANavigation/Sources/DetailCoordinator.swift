import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

class DetailCoordinator: Coordinator {

    struct State: Equatable {
        var route: Route? = nil
        var state: Detail.State
    }

    enum Route: Equatable {}

    enum Action: Equatable {
        case action(Detail.Action)
        case onClose
    }

    struct Environment {
        var environment: Detail.Environment { .init() }
    }

    static let reducer: Reducer<State, Action, Environment> = .combine([
        // current screen
        Detail.reducer._pullback(
            state: \State.state,
            action: /Action.action,
            environment: \.environment
        ),
    ])

    let store: Store<State, Action>
    var rootViewController: UIViewController? { navigationController }

    private weak var navigationController: UINavigationController?
    private weak var viewController: UIViewController?
    private var cancelables: Set<AnyCancellable> = []

    init(store: Store<State, Action>) {
        self.store = store
    }

    func start(pushedTo navigationController: UINavigationController, animated: Bool = true) {
        let vc = makeDetailVC()
        navigationController.pushViewController(vc, animated: animated)
        self.navigationController = navigationController
    }

    func start(presentedTo viewController: UIViewController, animated: Bool = true) {
        let vc = makeDetailVC()
        viewController.present(vc, animated: animated)
        self.viewController = viewController
    }

    func stop(animated: Bool = true) {
        // TODO: [Jakub] Handle pushed
        self.viewController?.dismiss(animated: animated)
    }

    deinit {
        ViewStore(store).send(.onClose)
    }

    func makeDetailVC() -> UIViewController {
        return HostingController(
            rootView: Detail.Screen(store: store.scope(state: \.state, action: Action.action)),
            coordinator: self,
            onDeinit: nil // no need to clear state as the coordinator should deallocate
        )
    }
}
