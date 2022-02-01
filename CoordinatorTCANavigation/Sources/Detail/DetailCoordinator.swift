import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

extension Detail {
    class Coordinator: CoordinatorType {

        let store: Store<State, NavigationAction<Action>>
        var rootViewController: UIViewController? { navigationController }

        private weak var navigationController: UINavigationController?
        private weak var viewController: UIViewController?
        private var cancelables: Set<AnyCancellable> = []

        init(store: Store<State, NavigationAction<Action>>) {
            Log.debug()
            self.store = store
        }

        deinit {
            Log.debug()
            ViewStore(store).send(.onClose)
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
            self.navigationController?.popViewController(animated: animated)
        }

        func makeDetailVC(onDeinit: (() -> Void)? = nil) -> UIViewController {
            return HostingController(
                rootView: Detail.Screen(store: store.scope(state: { $0 }, action: NavigationAction.action)),
                coordinator: self,
                onDeinit: onDeinit
            )
        }
    }
}
