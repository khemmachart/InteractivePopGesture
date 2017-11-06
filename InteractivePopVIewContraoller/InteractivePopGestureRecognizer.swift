//
//  InteractivePopGesterRecognizer.swift
//  InteractivePopVIewContraoller
//
//  Created by Khemmachart Chutapetch on 11/2/2560 BE.
//  Copyright © 2560 Khemmachart Chutapetch. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

enum InteractivePanDirection {
    case up
    case left
    case down
    case right
}

class InteractivePopGestureRecognizer: UIPanGestureRecognizer {
    
    var direction: InteractivePanDirection = .up
    var dragging: Bool = false

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        guard state != .failed else { return }
        
        let velocity = self.velocity(in: view)
        
        // Check direction only on the first move
        if !dragging && !velocity.equalTo(CGPoint.zero) {
            let velocities: [InteractivePanDirection: CGFloat] = [
                .up :  -velocity.y,
                .left: -velocity.x,
                .down:  velocity.y,
                .right: velocity.x,
            ]
    
            // Finding the pan direction from highest velocity
            let maxValue = velocities.values.max()
            let keyStore = velocities.filter({ $0.value == maxValue }).first?.key

            // Fails the gesture if the highest velocity isn't in the same direction as `direction` property.
            if let direction = keyStore, direction != self.direction {
                state = .failed
            }

            dragging = true
        }
    }

    override func reset() {
        dragging = false
    }
}


/*
 
 @interface SSWDirectionalPanGestureRecognizer()
 @property (nonatomic) BOOL dragging;
 @end
 
 @implementation SSWDirectionalPanGestureRecognizer
 
 - (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
 {
 [super touchesMoved:touches withEvent:event];
 
 if (self.state == UIGestureRecognizerStateFailed) return;
 
 CGPoint velocity = [self velocityInView:self.view];
 
 // check direction only on the first move
 if (!self.dragging && !CGPointEqualToPoint(velocity, CGPointZero)) {
 NSDictionary *velocities = @{
 @(SSWPanDirectionRight) : @(velocity.x),
 @(SSWPanDirectionDown) : @(velocity.y),
 @(SSWPanDirectionLeft) : @(-velocity.x),
 @(SSWPanDirectionUp) : @(-velocity.y)
 };
 NSArray *keysSorted = [velocities keysSortedByValueUsingSelector:@selector(compare:)];
 
 // Fails the gesture if the highest velocity isn't in the same direction as `direction` property.
 if ([[keysSorted lastObject] integerValue] != self.direction) {
 self.state = UIGestureRecognizerStateFailed;
 }
 
 self.dragging = YES;
 }
 }
 
 - (void)reset
 {
 [super reset];
 
 self.dragging = NO;
 }
 
 @end

 
 */
