/*
 Copyright (c) 2011 Readmill LTD
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "ReadmillUIPresenter.h"
#import <QuartzCore/QuartzCore.h>

@interface ReadmillUIPresenter ()

@property (nonatomic, readwrite, retain) UIViewController *contentViewController;

@end

@implementation ReadmillUIPresenter

- (id)initWithContentViewController:(UIViewController *)aContentViewController 
{
    if ((self = [super init])) {
        [self setContentViewController:aContentViewController];
    }
    return self;
}

- (void)dealloc 
{    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [contentContainerView removeObserver:self forKeyPath:@"frame"];
    [contentContainerView release];

    [contentViewController release];
        
    [backgroundView release];
    [self setView:nil];
    [super dealloc];
}

@synthesize contentViewController;

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated 
{
    [self dismissPresenterAnimated:animated];
}

#pragma mark -

#define kAnimationDuration 0.2
#define kBackgroundOpacity 0.5

- (void)willShowKeyboard:(NSNotification *)note 
{    
    CGFloat offset = 30.0;
    CGPoint position = [contentContainerView center];
    position.y -= offset;
    [UIView animateWithDuration:0.3
                          delay:0.0 
                        options:UIViewAnimationOptionCurveEaseInOut 
                     animations:^{
                        [contentContainerView setCenter:position];                        
                     }
                     completion:nil];
}
- (void)willHideKeyboard:(NSNotification *)note 
{
    CGFloat offset = 30.0;
    CGPoint position = [contentContainerView center];
    position.y += offset;
    [UIView animateWithDuration:0.3
                          delay:0.0 
                        options:UIViewAnimationOptionCurveEaseOut 
                     animations:^{
                         [contentContainerView setCenter:position];                        
                     }
                     completion:nil];
}
- (void)presentInViewController:(UIViewController *)theParentViewController animated:(BOOL)animated 
{
    [self retain];
    
    _isVisible = YES;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(contentViewControllerShouldBeDismissed:)
               name:ReadmillUIPresenterShouldDismissViewNotification
             object:[self contentViewController]];
    
    [nc addObserver:self
           selector:@selector(willShowKeyboard:) 
               name:UIKeyboardWillShowNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(willHideKeyboard:) 
               name:UIKeyboardWillHideNotification
             object:nil];
    
    UIView *parentView = [theParentViewController view];
    
    [[self view] setFrame:[parentView bounds]];
    [contentContainerView setCenter:CGPointMake(CGRectGetMidX(self.view.bounds), 
                                                CGRectGetMaxY(self.view.bounds) + CGRectGetMidY(contentContainerView.frame))];
    
    [parentView addSubview:[self view]];    
    
    if (animated) {
        // Set up animation!
        [UIView beginAnimations:ReadmillUIPresenterDidAnimateIn context:nil];
        [UIView setAnimationDuration:kAnimationDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animation:finished:context:)];
    }
    
    [contentContainerView setCenter:[self.view center]];
    [[self view] setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:kBackgroundOpacity]];                         
    
    if (animated) {
        // Commit animation
        [UIView commitAnimations];
    } else {
        ReadmillDismissingView *dismiss = [[ReadmillDismissingView alloc] initWithFrame:self.view.bounds
                                                                               delegate:self];
        [dismiss addToView:self.view];
        [dismiss release];
    }
}

- (void)presentInViewController:(UIViewController *)theParentViewController
{
    [self presentInViewController:theParentViewController animated:YES];
}

- (void)dismissView 
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ReadmillUIPresenterShouldDismissViewNotification 
                                                        object:[self contentViewController]];
}
- (void)contentViewControllerShouldBeDismissed:(NSNotification *)aNotification 
{
    [self dismissPresenterAnimated:YES];
}

- (void)dismissPresenterAnimated:(BOOL)animated 
{
    _isVisible = NO;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self
                  name:ReadmillUIPresenterShouldDismissViewNotification
                object:[self contentViewController]];
    
    [nc removeObserver:self 
                  name:UIKeyboardWillShowNotification 
                object:nil];
    
    [nc removeObserver:self 
                  name:UIKeyboardWillHideNotification
                object:nil];
        
    if (animated) {
        
        [UIView beginAnimations:ReadmillUIPresenterDidAnimateOut context:nil];
        [UIView setAnimationDuration:kAnimationDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animation:finished:context:)];
        
        [[self view] setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.0]];
        
        [contentContainerView setCenter:CGPointMake(CGRectGetMidX([[self view] bounds]),
                                                    CGRectGetMaxY([[self view] bounds]) + 
                                                        CGRectGetMidY([contentContainerView frame]))];
        
        [UIView commitAnimations];
        
    } else {
        [[self view] removeFromSuperview];
        [self release];
    }
}

- (void)dismissPresenter
{
    [self dismissPresenterAnimated:YES];
}

- (void)animation:(NSString*)animationID finished:(BOOL)didFinish context:(void *)context 
{
    if ([animationID isEqualToString:ReadmillUIPresenterDidAnimateOut]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ReadmillUIPresenterDidAnimateOut object:nil]; 
        [[self view] removeFromSuperview];
        [self release];
    }
    else if ([animationID isEqualToString:ReadmillUIPresenterDidAnimateIn]) {
        ReadmillDismissingView *dismiss = [[ReadmillDismissingView alloc] initWithFrame:self.view.frame
                                                                               delegate:self];
        [dismiss addToView:self.view];
        [dismiss release];
        [[NSNotificationCenter defaultCenter] postNotificationName:ReadmillUIPresenterDidAnimateIn object:nil]; 
    }
}

- (void)displayContentViewController 
{
    if (self.contentViewController) {
        [contentContainerView setFrame:self.contentViewController.view.bounds];
        [contentContainerView setCenter:self.view.center];
        CALayer *shadowLayer = contentContainerView.layer;
        [shadowLayer setShadowPath:[UIBezierPath bezierPathWithRect:contentContainerView.bounds].CGPath];
        [shadowLayer setShadowColor:[[UIColor blackColor] CGColor]];
        [shadowLayer setShadowRadius:8.0];
        [shadowLayer setShadowOpacity:0.5];
        [shadowLayer setShadowOffset:CGSizeMake(0.0, 5.0)];
        [shadowLayer setCornerRadius:3];
        
        [self.contentViewController.view.layer setCornerRadius:3];
        [self.contentViewController.view setClipsToBounds:YES];
        [contentContainerView addSubview:self.contentViewController.view];
    }
}
- (void)setAndDisplayContentViewController:(UIViewController *)aContentViewController 
{
    [self setContentViewController:aContentViewController];
    [self displayContentViewController];
}

#pragma mark - View lifecycle

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
    if ([keyPath isEqualToString:@"frame"]) {
        [[contentContainerView layer] setShadowPath:[UIBezierPath bezierPathWithRect:contentContainerView.bounds].CGPath];  
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
    backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    [backgroundView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.0]];
    [backgroundView setOpaque:NO];
    [backgroundView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self setView:backgroundView];

    contentContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 648.0, 440.0)];
    [contentContainerView setBackgroundColor:[UIColor clearColor]];
    [contentContainerView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin];
    [contentContainerView addObserver:self forKeyPath:@"frame" options:0 context:nil];
    [backgroundView addSubview:contentContainerView];
    
    [self displayContentViewController];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [contentContainerView removeObserver:self forKeyPath:@"frame"];
    [contentContainerView release];
    contentContainerView = nil;
    
    [backgroundView release];
    backgroundView = nil;
    
    [contentViewController release];
    contentViewController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations

	return NO;
}

@end
