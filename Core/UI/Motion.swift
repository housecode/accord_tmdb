import UIKit

/// Native animations only; every effect degrades to a cross-fade or nothing under Reduce Motion.
enum Motion {
    static let duration: TimeInterval = 0.25

    static var isReduced: Bool { UIAccessibility.isReduceMotionEnabled }

    static func transition(_ view: UIView, changes: @escaping () -> Void) {
        if isReduced {
            changes()
            return
        }
        UIView.transition(with: view, duration: duration, options: [.transitionCrossDissolve, .allowUserInteraction], animations: changes)
    }

    static func press(_ view: UIView, pressed: Bool) {
        guard !isReduced else { return }
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            view.transform = pressed ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
        }
    }

    static func crossFade(_ view: UIView, changes: @escaping () -> Void) {
        UIView.transition(with: view, duration: isReduced ? 0 : duration,
                          options: [.transitionCrossDissolve, .allowUserInteraction], animations: changes)
    }
}
