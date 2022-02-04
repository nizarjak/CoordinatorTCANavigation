import Foundation
import UIKit
import ComposableArchitecture
import Combine

public protocol PushableCoordinator: BaseCoordinatorType {
    var cancelEffects: ([AnyHashable]) -> Void { get set }
    func start(pushedTo navigationController: UINavigationController, animated: Bool)
}

public protocol PresentableCoordinator: BaseCoordinatorType {
    var cancelEffects: ([AnyHashable]) -> Void { get set }
    func start(presentedTo viewController: UIViewController, animated: Bool)
}

public protocol BaseCoordinatorType: AnyObject {
    var childCoordinator: BaseCoordinatorType? { get set }
    func recursiveCleanup()
}

extension BaseCoordinatorType {
    /// Handles proper animation and childCoordinator cleanup.
    /// This should be called from the first coordinator that will survive the navigation - the one who clears the state.
    func closeAll(inside navigationController: UINavigationController?, until rootViewController: UIViewController?) {
        // cleaning only childs as this coordinator should not be cleaned.
        childCoordinator?.recursiveCleanup()
        childCoordinator = nil // so we don't clean childCoordinator multiple times

        // No need to handle navigation if it already happened
        guard let navigationController = navigationController else { return }

        let isPresenting = navigationController.presentedViewController != nil
        if isPresenting {
            // if something is presenting, we can hide poping below the modal screen's animation
            navigationController.dismiss(animated: true)
        }
        // pop with animation only when we're not animating any modal screen down.
        if let rootViewController = rootViewController {
            navigationController.popToViewController(rootViewController, animated: !isPresenting)
        }
    }
}

open class BaseCoordinator<State, Action>: BaseCoordinatorType where State: Equatable, Action: Equatable {

    public let store: Store<State, NavigationAction<Action>>

    public weak var childCoordinator: BaseCoordinatorType?

    /// We're getting closed by the parent. The state was already niled and we're reacting to that.
    private var isClosedByStateChange: Bool = false
    private var cancelables: Set<AnyCancellable> = []
    public var cancelEffects: ([AnyHashable]) -> Void

    init(store: Store<State, NavigationAction<Action>>) {
        self.store = store
        self.cancelEffects = { _ in }
    }

    deinit {
        guard !isClosedByStateChange else { return }
        // Getting interactively closed by user

        // Do the cleanup of self and the childs
        recursiveCleanup()

        // Update the state
        ViewStore(store).send(.onSystemClose)
    }

    func cleanup() {
        // nothing to cleanup
    }

    public func recursiveCleanup() {
        // childs will clean itself first
        self.childCoordinator?.recursiveCleanup()
        self.isClosedByStateChange = true
        self.cleanup()
    }

    func bindToState<LocalState: Equatable, LocalAction: Equatable>(
        state toLocalState: OptionalPath<State, LocalState>,
        action toLocalAction: CasePath<NavigationAction<Action>, NavigationAction<LocalAction>>,
        openCoordinator: @escaping (
            Store<LocalState, NavigationAction<LocalAction>>,
            @escaping ([AnyHashable]) -> Void
        ) -> BaseCoordinator<LocalState, LocalAction>,
        onClose: @escaping () -> Void
    ) {
        store.scope(
            state: toLocalState.extract(from:),
            action: toLocalAction.embed
        )
        .ifLet(
            then: { [weak self] honestLocalStore in
                guard let self = self else { return }
                let coordinator = openCoordinator(honestLocalStore, { [weak self] in self?.cancelEffects($0) })
                self.childCoordinator = coordinator
            },
            else: onClose
        )
        .store(in: &cancelables)
    }

    func present<LocalState: Equatable, LocalAction: Equatable>(
        state toLocalState: OptionalPath<State, LocalState>,
        action toLocalAction: CasePath<NavigationAction<Action>, NavigationAction<LocalAction>>,
        into viewController: UIViewController,
        coordinator makeCoordinator: @escaping (
            Store<LocalState, NavigationAction<LocalAction>>
        ) -> PresentableCoordinator
    ) {
        // if we've already presented something
        var presented = false

        store.scope(
            state: toLocalState.extract(from:),
            action: toLocalAction.embed
        )
        .ifLet(
            then: { [weak self, weak viewController] honestLocalStore in
                guard let self = self, let viewController = viewController else { return }
                let coordinator = makeCoordinator(honestLocalStore)
                coordinator.cancelEffects = self.cancelEffects
                coordinator.start(presentedTo: viewController, animated: true)
                self.childCoordinator = coordinator
                presented = true
            },
            else: { [weak self, weak viewController] in
                guard presented else { return } // we didn't present anything yet
                guard let self = self else { return }
                // cleaning only childs as this coordinator should not be cleaned.
                self.childCoordinator?.recursiveCleanup()
                self.childCoordinator = nil // so we don't clean childCoordinator multiple times

                viewController?.dismiss(animated: true)
            }
        )
        .store(in: &cancelables)
    }

    func push<LocalState: Equatable, LocalAction: Equatable>(
        state toLocalState: OptionalPath<State, LocalState>,
        action toLocalAction: CasePath<NavigationAction<Action>, NavigationAction<LocalAction>>,
        into navigationController: UINavigationController,
        coordinator makeCoordinator: @escaping (
            Store<LocalState, NavigationAction<LocalAction>>
        ) -> PushableCoordinator
    ) {
        // if we've already pushed something
        var pushed = false
        // weakly referencing top controller before pushing so we know where to return
        let startViewController = Box<UIViewController>()

        store.scope(
            state: toLocalState.extract(from:),
            action: toLocalAction.embed
        )
        .ifLet(
            then: { [weak self, weak navigationController] honestLocalStore in
                guard let self = self, let navigationController = navigationController else { return }

                let coordinator = makeCoordinator(honestLocalStore)
                coordinator.cancelEffects = self.cancelEffects
                startViewController.value = navigationController.topViewController
                coordinator.start(pushedTo: navigationController, animated: true)
                self.childCoordinator = coordinator
                pushed = true
            },
            else: { [weak self, weak navigationController] in
                guard pushed else { return } // we didn't push anything yet
                guard let self = self else { return }
                // cleaning only childs as this coordinator should not be cleaned.
                self.childCoordinator?.recursiveCleanup()
                self.childCoordinator = nil // so we don't clean childCoordinator multiple times

                guard let navigationController = navigationController else { return }

                // some child could be presenting
                let isPresenting = navigationController.presentedViewController != nil
                if isPresenting {
                    navigationController.dismiss(animated: true)
                }

                guard let startViewController = startViewController.value else { return }
                // animate only if we're not doing dismiss
                navigationController.popToViewController(startViewController, animated: !isPresenting)
            }
        )
        .store(in: &cancelables)
    }
}

fileprivate class Box<T: AnyObject> {
    weak var value: T?

    init() {
        self.value = nil
    }

    init(_ value: T) {
        self.value = value
    }
}
