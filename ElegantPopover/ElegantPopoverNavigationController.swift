//
//  ElegantPopoverNavigationController.swift
//  ElegantPopover
//
//  Created by HIEN PHAM on 02/02/2024.
//

import UIKit

public class ElegantPopoverNavigationController: ElegantPopoverController {
    public var contentNavigationController: UINavigationController {
        return self.contentViewController as! UINavigationController
    }
    
    public init(contentNavigationController: UINavigationController, design: PSDesign,
                arrow: PSArrow, shadow: PSShadow? = nil, sourceView: UIView? = nil,
                sourceRect: CGRect? = nil, barButtonItem: UIBarButtonItem? = nil) {
        super.init(contentViewController: contentNavigationController, design: design,
                   arrow: arrow, sourceView: sourceView, sourceRect: sourceRect,
                   barButtonItem: barButtonItem)
        navigationController?.pushViewController(contentNavigationController, animated: true)
        if let viewController = contentNavigationController.topViewController {
            self.updatePreferredContentSize(fromViewController: viewController)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func pushViewController(_ viewController: UIViewController, animated: Bool) {
        self.contentNavigationController.pushViewController(viewController, animated: animated)
        if let coordinator = viewController.transitionCoordinator {
            coordinator.animate {[weak self] _ in
                self?.updatePreferredContentSize(fromViewController: viewController)
            }
        } else {
            self.updatePreferredContentSize(fromViewController: viewController)
        }
    }
    
    
    public func popViewController(animated: Bool) -> UIViewController? {
        let poppedViewController = self.contentNavigationController.popViewController(animated: animated)
        guard let viewController = self.contentNavigationController.topViewController else { return poppedViewController }
        if let coordinator = viewController.transitionCoordinator {
            coordinator.animate {[weak self] _ in
                self?.updatePreferredContentSize(fromViewController: viewController)
            }
        } else {
            self.updatePreferredContentSize(fromViewController: viewController)
        }
        return poppedViewController
    }
    
    public func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let poppedViewController = self.contentNavigationController.popToViewController(viewController, animated: animated)
        guard let viewController = self.contentNavigationController.topViewController else { return poppedViewController }
        if let coordinator = viewController.transitionCoordinator {
            coordinator.animate {[weak self] _ in
                self?.updatePreferredContentSize(fromViewController: viewController)
            }
        } else {
            self.updatePreferredContentSize(fromViewController: viewController)
        }
        return poppedViewController
    }
    
    public func popToRootViewController(animated: Bool) -> [UIViewController]? {
        let poppedViewController = self.contentNavigationController.popToRootViewController(animated: animated)
        guard let viewController = self.contentNavigationController.topViewController else { return poppedViewController }
        if let coordinator = viewController.transitionCoordinator {
            coordinator.animate {[weak self] _ in
                self?.updatePreferredContentSize(fromViewController: viewController)
            }
        } else {
            self.updatePreferredContentSize(fromViewController: viewController)
        }
        return poppedViewController
    }
    
    func updatePreferredContentSize(fromViewController viewController: UIViewController) {
        let preferredContentSize = viewController.preferredContentSize
        if (preferredContentSize != .zero) {
            self.popoverContentSize = preferredContentSize
        }
    }
    
    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        guard let viewController = container as? UIViewController,
        viewController == self.contentNavigationController.topViewController else { return }
        self.updatePreferredContentSize(fromViewController: viewController)
    }
}
