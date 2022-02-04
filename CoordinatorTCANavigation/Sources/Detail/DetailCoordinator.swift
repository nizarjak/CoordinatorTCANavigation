import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

extension Detail {
    class Coordinator: BaseCoordinator<State, Action>, PushableCoordinator, PresentableCoordinator {

        private weak var navigationController: UINavigationController?
        private weak var rootViewController: UIViewController?

        private var cancelables: Set<AnyCancellable> = []

        override init(store: Store<Detail.State, NavigationAction<Detail.Action>>) {
            super.init(store: store)
            Log.debug()
        }

        deinit {
            Log.debug()
        }

        override func cleanup() {
            // nothing to clean
            cancelEffects([Detail.Effects()])
        }

        func start(pushedTo navigationController: UINavigationController, animated: Bool = true) {
            let vc = makeDetailVC()
            navigationController.pushViewController(vc, animated: animated)
            self.navigationController = navigationController
            self.rootViewController = vc

            self.bindPresentedEdit(to: vc)
        }

        func start(presentedTo viewController: UIViewController, animated: Bool = true) {
            let vc = makeDetailVC()
            let nc = UINavigationController(rootViewController: vc)
            nc.navigationBar.prefersLargeTitles = true
            viewController.present(nc, animated: animated)
            self.navigationController = nc
            self.rootViewController = vc

            self.bindPresentedEdit(to: vc)
        }

        private func makeDetailVC() -> UIViewController {
            let vc = HostingController(
                rootView: Detail.Screen(store: store.scope(action: NavigationAction.action)),
                strongReference: self
            )
            vc.title = "Detail"

            return vc
        }

        private func bindPresentedEdit(to vc: UIViewController) {
            present(
                state: (\State.route).appending(path: /Route.edit),
                action: (/NavigationAction<Action>.action).appending(path: /Action.editCoordinator),
                into: vc,
                coordinator: Edit.Coordinator.init(store:)
            )
        }
    }
}
