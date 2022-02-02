import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

extension Detail {
    class Coordinator: CoordinatorType {

        let store: Store<State, NavigationAction<Action>>

        private weak var navigationController: UINavigationController?
        private weak var rootViewController: UIViewController?

        private var cancelables: Set<AnyCancellable> = []
        private var cancelEffects: ([AnyHashable]) -> Void

        init(store: Store<State, NavigationAction<Action>>, cancelEffects: @escaping ([AnyHashable]) -> Void) {
            Log.debug()
            self.store = store
            self.cancelEffects = cancelEffects
        }

        deinit {
            Log.debug()
            let viewStore = ViewStore(store)
            cancelEffects([Detail.Effects()])
            viewStore.send(.onClose)
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
                coordinator: self
            )
            vc.title = "Detail"

            return vc
        }

        private func bindPresentedEdit(to vc: UIViewController) {
            let editPath = (\State.route).appending(path: /Route.edit)
            let editStore = store.scope(
                state: editPath.extract(from:),
                action: (/NavigationAction<Action>.action).appending(path: /Action.editCoordinator).embed
            )

            editStore.ifLet { [weak self, weak vc] honestEditStore in
                guard let vc = vc, let self = self else { return }

                let editVC = HostingController(
                    rootView: Edit.Screen(store: honestEditStore.scope(action: NavigationAction.action)),
                    coordinator: self,
                    onDeinit: nil
                )
                vc.present(editVC, animated: true)
            } else: { [weak self] in
                // state was cleared
                self?.closeAll(inside: self?.navigationController, until: self?.rootViewController)
            }
            .store(in: &cancelables)
        }
    }
}
