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

-(id)initWithContentViewController:(UIViewController *)aContentViewController {
    if ((self = [super init])) {
        [self setContentViewController:aContentViewController];
    }
    return self;
}

-(void)dealloc {
    [backgroundView release];
    backgroundView = nil;
    [closeButtonView release];
    closeButtonView = nil;
    
    [contentContainerView removeObserver:self forKeyPath:@"frame"];
    [contentContainerView release];
    contentContainerView = nil;

    [self setView:nil];
    [self setContentViewController:nil];
    [super dealloc];
}

@synthesize contentViewController;

-(void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)dismissModalViewControllerAnimated:(BOOL)animated {
    [self dismissPresenterAnimated:animated];
}

-(void)closeButtonPushed {
    [[NSNotificationCenter defaultCenter] postNotificationName:ReadmillUIPresenterWillDismissViewFromCloseButtonNotification 
                                                        object:self];
    [self dismissPresenterAnimated:YES];
}

#pragma mark -

#define kAnimationDuration 0.3
#define kBackgroundOpactity 0.4 

-(void)presentInViewController:(UIViewController *)theParentViewController animated:(BOOL)animated {
    
    [self retain];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentViewControllerShouldBeDismissed:)
                                                 name:ReadmillUIPresenterShouldDismissViewNotification
                                               object:[self contentViewController]];
    
    UIView *parentView = [theParentViewController view];
    
    [[self view] setFrame:[parentView bounds]];
    [parentView addSubview:[self view]];
    
    [self viewDidAppear:animated];
    
    if (animated) {
        // Set up animation!
        
        [UIView beginAnimations:@"animateIn" context:nil];
        [UIView setAnimationDuration:kAnimationDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    }
    
    [[self view] setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:kBackgroundOpactity]];
    
    [contentContainerView setCenter:[[self view] center]];
    
    [closeButtonView setCenter:CGPointMake(floor([contentContainerView frame].origin.x) + .5, 
                                           floor([contentContainerView frame].origin.y) + .5)];    
    if (animated) {
        // Commit animation
        [UIView commitAnimations];
    }
    
}

-(void)contentViewControllerShouldBeDismissed:(NSNotification *)aNotification {
    [self dismissPresenterAnimated:YES];
}

-(void)dismissPresenterAnimated:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ReadmillUIPresenterShouldDismissViewNotification
                                                  object:[self contentViewController]];
    
    if (animated) {
        
        [UIView beginAnimations:@"animateOut" context:nil];
        [UIView setAnimationDuration:kAnimationDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animateOut:finished:context:)];
        
        [[self view] setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.0]];
        
        [contentContainerView setCenter:CGPointMake(CGRectGetMidX([[self view] bounds]),
                                                    CGRectGetMaxY([[self view] bounds]) + (CGRectGetHeight([contentContainerView frame]) / 2))];
        
        [closeButtonView setCenter:CGPointMake(floor([contentContainerView frame].origin.x) + .5, 
                                               floor([contentContainerView frame].origin.y) + .5)];  
        
        [UIView commitAnimations];
        
        
    } else {
        [[self view] removeFromSuperview];
        [self release];
    }
    
}

-(void)animateOut:(NSString*)animationID finished:(BOOL)didFinish context:(void *)context {
    [[self view] removeFromSuperview];
    [self release];
}


#pragma mark - View lifecycle

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"frame"]) {
        [closeButtonView setCenter:CGPointMake(floor([contentContainerView frame].origin.x) + .5, 
                                               floor([contentContainerView frame].origin.y) + .5)];  
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
-(void)loadView {

    backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
    [backgroundView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.0]];
    [backgroundView setOpaque:NO];
    [backgroundView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    [self setView:backgroundView];

    contentContainerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
    [contentContainerView setBackgroundColor:[UIColor whiteColor]];
    [[contentContainerView layer] setShadowColor:[[UIColor blackColor] CGColor]];
    [[contentContainerView layer] setShadowRadius:15.0];
    [[contentContainerView layer] setShadowOpacity:0.8];
    [[contentContainerView layer] setShadowOffset:CGSizeMake(0.0, 10.0)];
    [contentContainerView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin];
    
    [contentContainerView addObserver:self forKeyPath:@"frame" options:0 context:nil];
    
    [backgroundView addSubview:contentContainerView];
    
    closeButtonView = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [(UIButton *)closeButtonView setImage:[UIImage imageNamed:@"button_close.png"] forState:UIControlStateNormal]; 
    [closeButtonView setFrame:CGRectMake(0.0, 0.0, 31.0, 31.0)];
    [(UIButton *)closeButtonView addTarget:self
                                    action:@selector(closeButtonPushed) 
                          forControlEvents:UIControlEventTouchUpInside];
    
    [backgroundView addSubview:closeButtonView];
    
}

-(void)viewDidAppear:(BOOL)animated {
    
    if ([self contentViewController] != nil) {
        [contentContainerView setFrame:[[[self contentViewController] view] bounds]];
        
        [contentContainerView addSubview:[[self contentViewController] view]];
    }
    
    [contentContainerView setCenter:CGPointMake(CGRectGetMidX([[self view] bounds]),
                                                CGRectGetMaxY([[self view] bounds]) + (CGRectGetHeight([contentContainerView frame]) / 2))];
    
    
    [closeButtonView setCenter:CGPointMake(floor([contentContainerView frame].origin.x) + .5, 
                                           floor([contentContainerView frame].origin.y) + .5)];  
    
}

-(void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [backgroundView release];
    backgroundView = nil;
    [closeButtonView release];
    closeButtonView = nil;
    
    [contentContainerView removeObserver:self forKeyPath:@"frame"];
    [contentContainerView release];
    contentContainerView = nil;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
}

@end