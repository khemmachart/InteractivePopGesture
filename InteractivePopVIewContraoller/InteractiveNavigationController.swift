//
//  SloppySwiper.swift
//  InteractivePopVIewContraoller
//
//  Created by Khemmachart Chutapetch on 11/2/2560 BE.
//  Copyright © 2560 Khemmachart Chutapetch. All rights reserved.
//

import UIKit

/**
 * InteractiveNavigationController conforming to `UINavigationControllerDelegate` protocol that
 * allows pan back gesture to be started from anywhere on the screen (not only from the left edge).
 */
class InteractiveNavigationController: UINavigationController {
    
    override var interactivePopGestureRecognizer: UIGestureRecognizer? {
        return panRecognizer
    }

    private lazy var panRecognizer: UIPanGestureRecognizer = {
        let panRecognizer = InteractivePopGestureRecognizer(target: self, action: #selector(handleGesture))
        panRecognizer.direction = .right
        panRecognizer.maximumNumberOfTouches = 1
        panRecognizer.delegate = self
        return panRecognizer
    }()

    lazy var animator: InteractivePopViewControllerAnimator = {
        let animator = InteractivePopViewControllerAnimator()
        animator.delegate = self
        return animator
    }()

    fileprivate var interactionController: UIPercentDrivenInteractiveTransition?
    
    // MARK: - Initialization

    override func awakeFromNib() {
        super.awakeFromNib()
        addGestureRecognizer()
        addNavigationControllerDelegate()
    }

    deinit {
        panRecognizer.removeTarget(self, action: #selector(handleGesture(recognizer:)))
        view.removeGestureRecognizer(panRecognizer)
    }

    // MARK: - Utils
    
    func addGestureRecognizer() {
        view.addGestureRecognizer(panRecognizer)
    }

    func addNavigationControllerDelegate() {
        delegate = self
    }

    // Set gesture to be enabled only when it completed animation
    // To perform, just using the animator duration to make a delay
    private func turnPanRecognizerEnabled(afterDuration duration: InteractivePopViewControllerAnimator.duration) {
        let milliseconds = Int(duration.rawValue * 1000)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(milliseconds), execute: {
            self.panRecognizer.isEnabled = true
        })
    }

    // MARK: - UIPanGestureRecognizer

    @objc func handleGesture(recognizer: UIPanGestureRecognizer) {

        switch recognizer.state {
            
        case .began:
            if viewControllers.count > 1 {
                interactionController = UIPercentDrivenInteractiveTransition()
                interactionController?.completionCurve = .linear
                popViewController(animated: true)
            }
            
        case .changed:
            let translation = recognizer.translation(in: view)
            // Cumulative translation.x can be less than zero
            // because user can pan slightly to the right and then back to the left.
            let d = translation.x > 0 ? translation.x / view.bounds.width : 0
            interactionController?.update(d)
            
        case .ended, .cancelled:
            let widthCondition = (interactionController?.percentComplete ?? 0) > 0.5
            // let positionCondition = recognizer.location(in: view).x > 120
            // let velocityCondition = recognizer.velocity(in: view).x > 0
            
            if widthCondition {
                interactionController?.finish()
            } else {
                interactionController?.cancel()
                // When the transition is cancelled, 'navigationController:didShowViewController:animated:'
                // isn't called, so we have to maintain the gesture state here
                panRecognizer.isEnabled = false
                // If the the gesture turn to be enabled immediately,
                // it might be caused the navitation bar title's bug
                turnPanRecognizerEnabled(afterDuration: .interactive)
            }
            interactionController = nil
            
        default:
            break
        }
    }
}

// MARK: - InteractivePopViewControllerAnimatorDelegate

extension InteractiveNavigationController: InteractivePopViewControllerAnimatorDelegate {
    
    // Return false when you don't want the TabBar to animate during swiping.
    func animatorShouldAnimateTabBar(animator: InteractivePopViewControllerAnimator) -> Bool {
        return true
    }

    // 0.0 means no dimming, 1.0 means pure black.
    func animatorTransitionDimAmount(animator: InteractivePopViewControllerAnimator) -> CGFloat {
        return 0.25
    }
}

// MARK: - UIGestureRecognizerDelegate

extension InteractiveNavigationController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

// MARK: - UINavigationControllerDelegate

extension InteractiveNavigationController: UINavigationControllerDelegate {
    
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

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if navigationController.viewControllers.count < 2 {
            panRecognizer.isEnabled = false
        } else {
            panRecognizer.isEnabled = true
        }
    }
}
