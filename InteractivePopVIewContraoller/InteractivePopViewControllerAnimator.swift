//
//  SSWAnimation.swift
//  InteractivePopVIewContraoller
//
//  Created by Khemmachart Chutapetch on 11/2/2560 BE.
//  Copyright © 2560 Khemmachart Chutapetch. All rights reserved.
//

import UIKit

extension UIView {
    
    func addLeftSideShadow() {
        let shadowWidth: CGFloat = 4.0
        let shadowRect = CGRect(x: -shadowWidth, y: 0, width: shadowWidth, height: frame.height)
        let shadowPath = UIBezierPath(rect: shadowRect)
        layer.shadowPath = shadowPath.cgPath
        layer.shadowOpacity = 0.2
    }
}

protocol InteractivePopViewControllerAnimatorDelegate: class {
    func animatorShouldAnimateTabBar(animator: InteractivePopViewControllerAnimator) -> Bool
    func animatorTransitionDimAmount(animator: InteractivePopViewControllerAnimator) -> CGFloat
}

class InteractivePopViewControllerAnimator: NSObject {
    weak var delegate: InteractivePopViewControllerAnimatorDelegate?
    weak var toViewController: UIViewController?
}

extension InteractivePopViewControllerAnimator {
    enum duration: Double {
        case interactive = 0.3
        case noneInteractive = 0.25
    }
}

extension InteractivePopViewControllerAnimator: UIViewControllerAnimatedTransitioning {

    // Approximated lengths of the default animations.
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if let isInteractive = transitionContext?.isInteractive {
            return isInteractive
                ? InteractivePopViewControllerAnimator.duration.interactive.rawValue
                : InteractivePopViewControllerAnimator.duration.noneInteractive.rawValue
        }
        return 0
    }
    
    // Tries to animate a pop transition similarly to the default iOS' pop transition.
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else { return }
        guard let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else { return }

        // The tab bar conditions
        let isToViewControllerHidesTabBar = isTabBarHidden(at: toViewController)
        let isFromViewControllerHidesTabBar = isTabBarHidden(at: fromViewController)

        // Temporary tab bar
        var lineView: UIView?
        var tabBarImageView: UIImageView?

        // FIXED: The hidesBottomBarWhenPushed not animated properly.
        // This block gonna be executed only when the tabbat from present view controller is hidden
        // And the previous view controller (the view controller behide, toViewController) is shown
        if let toTabBarController = toViewController.tabBarController, !isToViewControllerHidesTabBar && isFromViewControllerHidesTabBar {

            // Temporary views
            let tabBarScreenshot = getScreenshot(from: toTabBarController.tabBar)
            let tabBarRect = toTabBarController.tabBar.frame
            
            // Frames
            let frame = toViewController.view.frame
            let lineViewFrame = CGRect(x: 0, y: frame.height - tabBarRect.size.height - 0.5, width: tabBarRect.width, height: 0.5)
            let tabBarFrame = CGRect(x: 0, y: frame.height - tabBarRect.size.height, width: tabBarRect.width, height: tabBarRect.height)

            // Declear the temporary view
            lineView = UIView(frame: lineViewFrame)
            lineView?.backgroundColor = UIColor(red: 194/255, green: 194/255, blue: 194/255, alpha: 1)
            tabBarImageView = UIImageView(frame: tabBarFrame)
            tabBarImageView?.image = tabBarScreenshot

            // Fix UITableViewController position issue
            if let toTableViewController = toViewController as? UITableViewController {
                let yPosition = toTableViewController.tableView.contentOffset.y + toTableViewController.view.frame.size.height - tabBarRect.size.height
                lineView?.frame = CGRect(x: 0, y: yPosition - 0.5, width: tabBarRect.size.width, height: 0.5)
                tabBarImageView?.frame = CGRect(x: 0, y: yPosition - tabBarRect.size.height, width: tabBarRect.size.width, height: tabBarRect.size.height)
            }

            // Add the temporary view as a subview
            if let lineView = lineView {
                toViewController.view.addSubview(lineView)
            }
            if let tabBarImageView = tabBarImageView {
                toViewController.view.addSubview(tabBarImageView)
            }
            // FIXED: We have to use alpha instead of hidden.
            // Hidden tabBar might effect to the main view frame and the tabBar background color
            toViewController.tabBarController?.tabBar.alpha = 0
        }
        
        transitionContext.containerView.insertSubview(toViewController.view, belowSubview: fromViewController.view)
        
        // Parallax effect the offset matches the one used in the pop animation in iOS 7.1
        let toViewControllerXTranslation = -transitionContext.containerView.bounds.width * 0.3
        toViewController.view.bounds = transitionContext.containerView.bounds
        toViewController.view.center = transitionContext.containerView.center
        toViewController.view.transform = CGAffineTransform(translationX: toViewControllerXTranslation, y: 0)
        
        // Add a shadow on the left side of the frontmost view controller
        let previousClipsToBounds = fromViewController.view.clipsToBounds
        fromViewController.view.addLeftSideShadow()
        fromViewController.view.clipsToBounds = false

        // In the default transition the view controller below is a little dimmer than the frontmost one
        let defaultDimAmount: CGFloat = 0.1
        let dimAmount = delegate?.animatorTransitionDimAmount(animator: self)
        let dimmingView = UIView(frame: toViewController.view.bounds)
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: dimAmount ?? defaultDimAmount)
        toViewController.view.addSubview(dimmingView)
        
        // Uses linear curve for an interactive transition, so the view follows the finger. Otherwise, uses a navigation transition curve.
        // UIViewAnimationOptions curveOption = [transitionContext isInteractive] ? UIViewAnimationOptionCurveLinear : SSWNavigationTransitionCurve
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveLinear], animations:{
            
            // Animate the previous and present views
            toViewController.view.transform = CGAffineTransform.identity
            fromViewController.view.transform = CGAffineTransform(translationX: toViewController.view.frame.width, y: 0)
            dimmingView.alpha = 0
            
        }, completion: { _ in
            
            // Remove the subviews and restore view to the normal state
            dimmingView.removeFromSuperview()
            lineView?.removeFromSuperview()
            tabBarImageView?.removeFromSuperview()
            
            fromViewController.view.transform = CGAffineTransform.identity
            fromViewController.view.clipsToBounds = previousClipsToBounds
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
            if !isToViewControllerHidesTabBar {
                toViewController.tabBarController?.tabBar.alpha = 1
            }
        })
        
        self.toViewController = toViewController
    }

    func animationEnded(_ transitionCompleted: Bool) {
        // Restore the toViewController's transform if the animation was cancelled
        if !transitionCompleted {
            toViewController?.view.transform = CGAffineTransform.identity
        }
    }

    // MARK: - Utils

    private func getScreenshot(from view: UIView) -> UIImage? {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func isTabBarHidden(at viewController: UIViewController) -> Bool {
        if let tabBarController = viewController.tabBarController {
            return tabBarController.tabBar.isHidden || viewController.hidesBottomBarWhenPushed
        }
        return false
    }
}
