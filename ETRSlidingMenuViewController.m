//
//  ETRSlidingMenuViewController.m
//  SlidingMenu
//
//  Created by Matthew Brochstein on 5/7/12.
//  Copyright (c) 2012 . All rights reserved.
//
#import <objc/runtime.h>
#import "ETRSlidingMenuViewController.h"

CGFloat const ETRSlidingMenuAnimationSpeedSlow = 0.3;
CGFloat const ETRSlidingMenuAnimationSpeedFast = 0.7;
CGFloat const ETRSlidingMenuAnimationSpeedDefault = NSUIntegerMax;

@interface ETRSlidingMenuViewController ()

@property (nonatomic, retain) UIView *contentViewContainer;
@property (nonatomic, assign) ETRSlidingMenuState state;
@property (nonatomic, retain) UIButton *contentDismissButton;

- (void)updateContentView;
- (void)layoutViews;
- (void)updateContentDismissButtonForOffset:(CGFloat)offset;
- (ETRSlidingMenuState)stateForOffset:(CGFloat)offset andVelocity:(CGFloat)velocity;
- (void)setContentOffset:(CGFloat)offset withVelocity:(CGFloat)velocity updateState:(BOOL)updateState;
- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer;

@end

@implementation ETRSlidingMenuViewController

@synthesize contentViewController = _contentViewController;
@synthesize menuViewController = _menuViewController;
@synthesize menuWidth = _menuWidth;
@synthesize contentViewContainer = _contentViewContainer;
@synthesize state = _state;
@synthesize animationSpeed = _animationSpeed;
@synthesize contentDismissButton = _contentDismissButton;

#pragma mark - Object Lifecycle Methods

- (id)initWithContentViewController:(UIViewController *)contentViewController andMenuViewController:(UIViewController *)menuViewController
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
        // Content View Controller
        self.contentViewController = contentViewController;
        self.contentViewController.slidingMenuViewController = self;
        
        // Menu View Controller
        self.menuViewController = menuViewController;
        self.menuViewController.slidingMenuViewController = self;
        
        // Set the default state
        self.state = ETRSlidingMenuStateClosed;
        
        // Set the default animation speed
        self.animationSpeed = ETRSlidingMenuAnimationSpeedFast;
        
        // Add an observer on the contentViewController property so we can react to changes
        [self addObserver:self forKeyPath:@"contentViewController" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
        
    }
    return self;
}

- (void)dealloc
{
    
    // Remove the observer
    [self removeObserver:self forKeyPath:@"contentViewController"];
    
    // Set properties to nil
    self.contentViewContainer = nil;
    self.contentViewController = nil;
    self.menuViewController = nil;
    self.contentDismissButton = nil;
    
    [super dealloc];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"contentViewController"]) {

        // Remove the old view
        [[[change objectForKey:@"old"] view] removeFromSuperview];
        
        // Update the content view
        [self updateContentView];
        
        // Update the frames of the components
        [self layoutViews];
        
    }
}

#pragma mark - View Lifecycle Methods

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // Create the content dismiss button
    self.contentDismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.contentDismissButton addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.contentDismissButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.7]];
    [self.contentDismissButton setAlpha:0.0];
    
    // Add a pan gesture recognizer to the content dismiss button
    UIPanGestureRecognizer *panGestureRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)] autorelease];
    [self.contentDismissButton addGestureRecognizer:panGestureRecognizer];

    // Create the content view container
    self.contentViewContainer = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
    [self.contentViewContainer setBackgroundColor:[UIColor redColor]];
    
    // Add a pan gesture recognizer to the contentViewContainer
    // This allows screens that dont alternatively handle panning to use that gesture for menu activation
    panGestureRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)] autorelease];
    [self.contentViewContainer addGestureRecognizer:panGestureRecognizer];
    
    // Add the content container to the main view
    [self.view addSubview:self.contentViewContainer];
    
    // Add the content view to the content container
    [self updateContentView];
    
    // Add the menu view
    [self.view insertSubview:self.menuViewController.view belowSubview:self.contentViewContainer];
    
    // Add the content dismiss button
    [self.contentViewContainer addSubview:self.contentDismissButton];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];  
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.contentViewContainer setFrame:self.view.bounds];
    [self layoutViews];
}

#pragma mark - UIViewController Orientation Methods

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.menuViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.contentViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.menuViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.contentViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.contentViewContainer setFrame:self.view.bounds];
    [self layoutViews];
    [self.menuViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.contentViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Setters and Getters

- (BOOL)isMenuShowing
{
    return (self.contentViewContainer.frame.origin.x != 0);
}

- (CGFloat)currentContentOffset
{
    return self.contentViewContainer.frame.origin.x;
}

#pragma mark - Private Methods

- (void)layoutViews
{
    [self.contentViewController.view setFrame:self.view.bounds];
    [self.menuViewController.view setFrame:self.view.bounds];
    [self.contentDismissButton setFrame:self.view.bounds];
}

- (void)animateContentOffset:(CGFloat)offset withSpeed:(CGFloat)speed
{
    
    // If we're not asking to change the offset, don't do anything
    if (offset == self.currentContentOffset) return;
    
    // If the speed is infinity, don't do anything because it'll kill the animation
    if (speed == INFINITY) return;
    
    // Update the state to match what we're currently doing
    if (offset > self.currentContentOffset) {
        self.state = ETRSlidingMenuStateOpening;
    }
    else if (offset > self.currentContentOffset) {
        self.state = ETRSlidingMenuStateClosing;
    }
    
    // If we've specified the default speed, then use it
    if (speed == ETRSlidingMenuAnimationSpeedDefault) {
        speed = _animationSpeed;
    }
    
    [UIView animateWithDuration:speed delay:0.0 options:UIViewAnimationCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
       
        // Set the content offset
        [self setContentOffset:offset withVelocity:0.0 updateState:NO];
        
        // Update the dismiss button's frame/alpha/interaction
        [self updateContentDismissButtonForOffset:offset];
        
    } completion:^(BOOL finished) {
        
        // Update the state
        self.state = self.isMenuShowing ? ETRSlidingMenuStateOpen : ETRSlidingMenuStateClosed;
        
    }];
}

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer
{

    // Current velocity
    CGFloat xVelocity = [gestureRecognizer velocityInView:gestureRecognizer.view].x;
    
    // Current offset
    CGFloat xOffset = [gestureRecognizer translationInView:gestureRecognizer.view].x;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        
        // If the gesture has ended and we're not in either an open or closed state, finish the motion
        if (self.state != ETRSlidingMenuStateOpen && self.state != ETRSlidingMenuStateClosed) {
            [self finishCurrentStateActionWithVelocity:xVelocity];
        }
        
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        
        CGFloat translatedOffset = xOffset;
        
        // Simple condition for opening the menu
        if (_menuOffsetWhenDragBegan == 0.0) {
            
            [self setContentOffset:xOffset withVelocity:xVelocity];
            return;
            
        }
        
        // If we're doing something else, it's a little more complicated
        if (xVelocity > 0) {
            
            if (xOffset + _menuOffsetWhenDragBegan > self.menuWidth) {
                translatedOffset = self.menuWidth;
            }
            else {
                translatedOffset = self.menuWidth + xOffset;
            }
            
        }
        else {

            translatedOffset = _menuOffsetWhenDragBegan + xOffset;
            
        }
        
        // Move to the new offset
        [self setContentOffset:translatedOffset withVelocity:xVelocity];
        
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        
        // Mark where we started dragging so we can calculate the offset
        _menuOffsetWhenDragBegan = self.currentContentOffset;
        
    }
    
}
         
- (void)updateContentView
{
    if (!self.contentViewController.view.superview) {
        
        [self.contentViewContainer insertSubview:self.contentViewController.view belowSubview:self.contentDismissButton];
        [self.contentViewController.view setFrame:self.contentViewContainer.bounds];
        [self.contentViewContainer setAutoresizesSubviews:YES];
        [self.contentViewContainer bringSubviewToFront:self.contentDismissButton];
        [self.contentViewController setSlidingMenuViewController:self];
        
    }
}

- (void)updateContentDismissButtonForOffset:(CGFloat)offset
{
    [self.contentDismissButton setAlpha:(offset/self.menuWidth)];
    [self.contentDismissButton setHidden:(self.state == ETRSlidingMenuStateClosed)];
}

#pragma mark - Public Methods

- (void)showMenu
{
    [self animateContentOffset:self.menuWidth withSpeed:0.3];
}

- (void)hideMenu
{
    [self animateContentOffset:0.0 withSpeed:0.3];
}

- (void)toggleMenu
{
    if (_state == ETRSlidingMenuStateOpening || _state == ETRSlidingMenuStateOpen) [self hideMenu];
    else [self showMenu];
}

- (ETRSlidingMenuState)stateForOffset:(CGFloat)offset andVelocity:(CGFloat)velocity
{
    if (offset == 0) {
        self.state = ETRSlidingMenuStateClosed;
    }
    else if (offset == self.menuWidth) {
        self.state = ETRSlidingMenuStateOpen;
    }
    else if (velocity > 0) {
        self.state = ETRSlidingMenuStateOpening;
    }
    else if (velocity < 0) {
        self.state = ETRSlidingMenuStateClosing;
    }
    return self.state;
    
}

- (void)setContentOffset:(CGFloat)offset withVelocity:(CGFloat)velocity updateState:(BOOL)updateState
{
    
    // Make sure the offset falls within the appropriate bounds
    if (offset < 0) offset = 0;
    if (offset > self.menuWidth) offset = self.menuWidth;
    
    // Calculate the new frame for the content
    CGRect newFrame = self.contentViewContainer.frame;
    newFrame.origin.x = offset;
    [self.contentViewContainer setFrame:newFrame];
    
    // If we're supposed to update the state, then update it
    if (updateState) self.state = [self stateForOffset:offset andVelocity:velocity];

    // Update the dismiss button
    [self updateContentDismissButtonForOffset:offset];
    
}

- (void)setContentOffset:(CGFloat)offset withVelocity:(CGFloat)velocity
{
    [self setContentOffset:offset withVelocity:velocity updateState:YES];
}

- (void)finishCurrentStateActionWithVelocity:(CGFloat)velocity
{
    
    // Create the default speed, just in case
    CGFloat speed = 0;
    CGFloat distanceToFinish = 0;
    
    // Determine the speed from the velocity and the distance
    if (velocity > 0) {
        distanceToFinish = self.menuWidth - self.currentContentOffset;
    }
    else if (velocity < 0) {
        distanceToFinish = self.currentContentOffset;
    }
    
    
    speed = fabs(distanceToFinish / velocity);
    
    if (speed >= _animationSpeed) {
        speed = _animationSpeed;
    }
    
    // Prorate the speed by distance
    speed = speed * (distanceToFinish / self.menuWidth);
    
    // Set the minimum speed
    if (speed < _animationSpeed) {
        speed = _animationSpeed;
    }
    
    // Animate the change
    if (self.state == ETRSlidingMenuStateOpening) {
        [self animateContentOffset:self.menuWidth withSpeed:speed];
    }
    else if (self.state == ETRSlidingMenuStateClosing) {
        [self animateContentOffset:0 withSpeed:speed];
    }
    
}

@end

static char SLIDING_MENU_VC_KEY;

@implementation UIViewController (ETRSlidingMenuViewController)

- (void)setSlidingMenuViewController:(ETRSlidingMenuViewController *)slidingMenuViewController
{
    objc_setAssociatedObject(self, &SLIDING_MENU_VC_KEY, slidingMenuViewController, OBJC_ASSOCIATION_ASSIGN);
}

- (ETRSlidingMenuViewController *)slidingMenuViewController
{
    return (ETRSlidingMenuViewController *)objc_getAssociatedObject(self, &SLIDING_MENU_VC_KEY);
}

@end
