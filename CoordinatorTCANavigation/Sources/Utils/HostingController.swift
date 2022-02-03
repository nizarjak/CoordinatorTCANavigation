import SwiftUI

class HostingController<Content>: UIHostingController<Content> where Content : View {

    // strong reference
    let strongReference: AnyObject
    let onDeinit: (() -> Void)?

    init(rootView: Content, strongReference: AnyObject, onDeinit: (() -> Void)? = nil) {
        self.strongReference = strongReference
        self.onDeinit = onDeinit
        super.init(rootView: rootView)
    }

    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        onDeinit?()
    }
}
