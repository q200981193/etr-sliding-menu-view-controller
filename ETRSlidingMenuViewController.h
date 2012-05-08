//
//  ETRSlidingMenuViewController.h
//  SlidingMenu
//
//  Created by Matthew Brochstein on 5/7/12.
//  Copyright (c) 2012 . All rights reserved.
//

#import <UIKit/UIKit.h> 

extern CGFloat const ETRSlidingMenuAnimationSpeedFast;
extern CGFloat const ETRSlidingMenuAnimationSpeedSlow;
extern CGFloat const ETRSlidingMenuAnimationSpeedDefault;

typedef enum {
    ETRSlidingMenuStateClosed = 0,
    ETRSlidingMenuStateOpening,
    ETRSlidingMenuStateOpen,
    ETRSlidingMenuStateClosing
} ETRSlidingMenuState;

@class ETRSlidingMenuViewController;

@interface UIViewController (ETRSlidingMenuViewController)

@property (nonatomic, assign) ETRSlidingMenuViewController *slidingMenuViewController;

@end

@interface ETRSlidingMenuViewController : UIViewController
{
    CGFloat _menuOffsetWhenDragBegan;
}

@property (nonatomic, retain) UIViewController *contentViewController;
@property (nonatomic, retain) UIViewController *menuViewController;
@property (nonatomic, assign) CGFloat menuWidth;
@property (nonatomic, readonly) BOOL isMenuShowing;
@property (nonatomic, readonly) ETRSlidingMenuState state;
@property (nonatomic, assign) CGFloat animationSpeed;
@property (nonatomic, readonly) CGFloat currentContentOffset;

- (id)initWithContentViewController:(UIViewController *)contentViewController andMenuViewController:(UIViewController *)menuViewController;
- (void)showMenu;
- (void)hideMenu;
- (void)toggleMenu;
- (void)animateContentOffset:(CGFloat)offset withSpeed:(CGFloat)speed;
- (void)setContentOffset:(CGFloat)offset withVelocity:(CGFloat)velocity;
- (void)finishCurrentStateActionWithVelocity:(CGFloat)velocity;

@end
