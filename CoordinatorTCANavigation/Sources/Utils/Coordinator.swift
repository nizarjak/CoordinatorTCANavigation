import Foundation
import UIKit

protocol CoordinatorType: AnyObject {}

extension CoordinatorType {

    func closeAll(inside navigationController: UINavigationController?, until rootViewController: UIViewController?) {
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
