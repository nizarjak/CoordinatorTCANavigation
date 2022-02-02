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

        var effectsToCancel: [AnyHashable] {
            [Detail.Effects()]
        }
        var cancelEffects: ([AnyHashable]) -> Void

        init(store: Store<State, NavigationAction<Action>>, cancelEffects: @escaping ([AnyHashable]) -> Void) {
            Log.debug()
            self.store = store
            self.cancelEffects = cancelEffects
        }

        deinit {
            Log.debug()
            let viewStore = ViewStore(store)
            cancelEffects(effectsToCancel)
            viewStore.send(.onClose)
        }

        func start(pushedTo navigationController: UINavigationController, animated: Bool = true) {
            let vc = makeDetailVC()
            navigationController.pushViewController(vc, animated: animated)
            self.navigationController = navigationController
            self.viewController = vc // required due to detail presenting screens by SwiftUI
        }

        func start(presentedTo viewController: UIViewController, animated: Bool = true) {
            let vc = makeDetailVC()
            let nc = UINavigationController(rootViewController: vc)
            nc.navigationBar.prefersLargeTitles = true
            viewController.present(nc, animated: animated)
            self.viewController = viewController
            self.navigationController = nc
        }

        func stop(animated: Bool = true) {
            // TODO: [Jakub] Handle pushed
            self.viewController?.dismiss(animated: animated)
            self.navigationController?.popViewController(animated: animated)
        }

        func makeDetailVC(onDeinit: (() -> Void)? = nil) -> UIViewController {
            let vc = HostingController(
                rootView: Detail.Screen(store: store.scope(state: { $0 }, action: NavigationAction.action)),
                coordinator: self,
                onDeinit: onDeinit
            )
            vc.title = "Detail"

            return vc
        }
    }
}
