import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

extension Reservations {
    class Coordinator: CoordinatorType {

        let store: Store<State, NavigationAction<Action>>
        var rootViewController: UIViewController? { navigationController }

        private weak var detailCoordinator: Detail.Coordinator?

        private weak var navigationController: UINavigationController?
        private weak var viewController: UIViewController?
        
        private var cancelables: Set<AnyCancellable> = []

        init(store: Store<State, NavigationAction<Action>>) {
            Log.debug()
            self.store = store
        }

        deinit {
            Log.debug()
            // closed by interaction?
            ViewStore(store).send(.onClose)
        }

        func start(pushedTo navigationController: UINavigationController, animated: Bool = true) {
            let vc = makeReservationsVC()
//            vc.title = "Reservations"
            navigationController.pushViewController(vc, animated: animated)
            self.navigationController = navigationController

            bindPresentedDetail(to: vc)
            bindPushedDetail(to: navigationController)
        }

        func start(presentedTo viewController: UIViewController, animated: Bool = true) {
            let vc = makeReservationsVC()
            let nc = UINavigationController(rootViewController: vc)
            viewController.present(nc, animated: animated)
            self.viewController = viewController
            self.navigationController = nc

            bindPresentedDetail(to: vc)
            bindPushedDetail(to: nc)
        }

        func stop(animated: Bool = true) {
            // close child before closing self
            detailCoordinator?.stop(animated: false)

            self.viewController?.dismiss(animated: animated)
            self.navigationController?.popViewController(animated: animated)
        }

        func makeReservationsVC(onDeinit: (() -> Void)? = nil) -> UIViewController {
            return HostingController(
                rootView: Reservations.Screen(store: store.scope(state: { $0 }, action: NavigationAction.action)),
                coordinator: self,
                onDeinit: onDeinit
            )
        }

        func bindPresentedDetail(to vc: UIViewController) {
            let detailPath = (\State.route).appending(path: /Route.presentedDetail)
            let detailStore = store.scope(
                state: detailPath.extract(from:),
                action: (/NavigationAction<Action>.action).appending(path: /Action.presentedDetail).embed
            )

            detailStore.ifLet { [weak self, weak vc] honestDetailStore in
                guard let vc = vc else { return }
                let detailCoordinator = Detail.Coordinator(store: honestDetailStore)
                detailCoordinator.start(presentedTo: vc)
                self?.detailCoordinator = detailCoordinator
            } else: { [weak self] in
                // dismiss programmatically -> inform UIKit
                self?.detailCoordinator?.stop(animated: true)
            }
            .store(in: &cancelables)
        }

        func bindPushedDetail(to vc: UINavigationController) {
            let detailPath = (\State.route).appending(path: /Route.pushedDetail)
            let detailStore = store.scope(
                state: detailPath.extract(from:),
                action: (/NavigationAction<Action>.action).appending(path: /Action.pushedDetail).embed
            )

            detailStore.ifLet { [weak self] honestDetailStore in
                guard let nc = self?.navigationController else { return }
                let detailCoordinator = Detail.Coordinator(store: honestDetailStore)
                detailCoordinator.start(pushedTo: nc)
                self?.detailCoordinator = detailCoordinator
            } else: { [weak self] in
                // dismiss programmatically -> inform UIKit
                self?.detailCoordinator?.stop(animated: true)
            }
            .store(in: &cancelables)
        }
    }
}
