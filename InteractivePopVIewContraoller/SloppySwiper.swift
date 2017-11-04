//
//  SloppySwiper.swift
//  InteractivePopVIewContraoller
//
//  Created by Khemmachart Chutapetch on 11/2/2560 BE.
//  Copyright © 2560 Khemmachart Chutapetch. All rights reserved.
//

import UIKit

/**
 *  `SloppySwiper` is a class conforming to `UINavigationControllerDelegate` protocol that allows pan back gesture to be started from anywhere on the screen (not only from the left edge).
 */
class SloppySwiper: NSObject {
    
    @IBOutlet weak var navigationController: UINavigationController!
    
    lazy var panRecognizer: UIPanGestureRecognizer = {
        let panRecognizer = InteractivePopGestureRecognizer(target: self, action: #selector(pan))
        panRecognizer.direction = .right
        panRecognizer.maximumNumberOfTouches = 1
        panRecognizer.delegate = self
        return panRecognizer
    }()
    
    lazy var animator: SSWAnimator = {
        let animator = SSWAnimator()
        animator.delegate = self
        return animator
    }()
    
    var interactionController: UIPercentDrivenInteractiveTransition?
    
    // A Boolean value that indicates whether the navigation controller
    // is currently animating a push/pop operation.
    var duringAnimation: Bool = false

    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
        addGestureRecognizer()
    }

    override init() {
        super.init()
        addGestureRecognizer()
    }

    deinit {
        panRecognizer.removeTarget(self, action: #selector(pan))
        navigationController.view.removeGestureRecognizer(panRecognizer)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        addGestureRecognizer()
    }

    func addGestureRecognizer() {
        if navigationController != nil {
            navigationController.view.addGestureRecognizer(panRecognizer)
        }
    }
}

// MARK: - SSWAnimatorDelegate

extension SloppySwiper: SSWAnimatorDelegate {
    
    // Return false when you don't want the TabBar to animate during swiping.
    func animatorShouldAnimateTabBar(animator: SSWAnimator) -> Bool {
        return true
    }

    // 0.0 means no dimming, 1.0 means pure black. Default is 0.25
    func animatorTransitionDimAmount(animator: SSWAnimator) -> CGFloat {
        return 0.25
    }

    // MARK: - UIPanGestureRecognizer

    @objc func pan(recognizer: UIPanGestureRecognizer) {
        let view = navigationController.view
        switch recognizer.state {

        case .began:
            if navigationController.viewControllers.count > 1 && !duringAnimation {
                interactionController = UIPercentDrivenInteractiveTransition()
                interactionController?.completionCurve = .linear
                navigationController.popViewController(animated: true)
            }

        case .changed:
            let translation = recognizer.translation(in: view)
            // Cumulative translation.x can be less than zero
            // because user can pan slightly to the right and then back to the left.
            let d = translation.x > 0 ? translation.x / (view?.bounds.width ?? 0) : 0
            interactionController?.update(d)

        case .ended, .cancelled:
            let widthCondition = (interactionController?.percentComplete ?? 0) > 0.5
            // let positionCondition = recognizer.location(in: view).x > 120
            // let velocityCondition = recognizer.velocity(in: view).x > 0
            
            if widthCondition {
                interactionController?.finish()
            } else {
                // When the transition is cancelled, `navigationController:didShowViewController:animated:`
                // isn't called, so we have to maintain `duringAnimation`'s state here too.
                duringAnimation = false
                interactionController?.cancel()
            }
            interactionController = nil

        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension SloppySwiper: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationController.viewControllers.count > 1
    }
}

// MARK: - UINavigationControllerDelegate

extension SloppySwiper: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == UINavigationControllerOperation.pop {
            return animator 
        } else {
            return nil
        }
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if animated {
            duringAnimation = true
        }
     }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        duringAnimation = false
        
        if navigationController.viewControllers.count < 2 {
            panRecognizer.isEnabled = false
        } else {
            panRecognizer.isEnabled = true
        }
    }
}
