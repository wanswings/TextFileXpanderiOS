//
//  ActionViewController.m
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "ActionViewController.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const angle90[4] = {0.0f, 180.0f, 90.0f, 270.0f};

@implementation ActionViewController
{
    @private
    NSString *classNameForLog;
    UIViewController *parentController;
    UIView *parentView;
    UIView *childView;
    NSArray *buttonData;
    NSString *labelText;
    NSString *selectedItem;
    int returnTag;
    BOOL isiPad;
    UIPopoverController *popoverController;
    BOOL isSelected;
    long titleHeight;
    long buttonHeight;
    long cancelHeight;
    long totalHeight;
    long totalWidth;
}
@synthesize delegateAction;

- (id)initWithParent:(id)parent
            delegate:(id)called
          buttonData:(NSArray *)array
               title:(NSString *)title
            selected:(NSString *)selected
                 tag:(int)tag
{
    if (self = [super init]) {
        classNameForLog = [NSStringFromClass(self.class) stringByAppendingString:@"..."];
        NSLog(@"%@initWithParent", classNameForLog);

        parentController = parent;
        parentView = parentController.view;
        buttonData = array;
        labelText = title;
        selectedItem = selected;
        returnTag = tag;
        if ([[[UIDevice currentDevice] model] hasPrefix:@"iPad"]) {
            isiPad = YES;
        }
        else {
            isiPad = NO;
        }
        titleHeight = 50;
        buttonHeight = 50;
        cancelHeight = 50;
        if (isiPad) {
            cancelHeight = 0;
        }
        totalHeight = [buttonData count] * buttonHeight + titleHeight + cancelHeight + 5;
        totalWidth = 320;

        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];

        CGRect screen = [[UIScreen mainScreen] bounds];
        self.view.frame = CGRectMake(0, 0, screen.size.width, screen.size.height);
        UIColor *color = [UIColor darkGrayColor];
        UIColor *alphaColor = [color colorWithAlphaComponent:0.5];
        self.view.backgroundColor = alphaColor;
        parentController.modalPresentationStyle = UIModalPresentationCurrentContext;

        // for iOS8
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.view.autoresizingMask =
                    UIViewAutoresizingFlexibleTopMargin |
                    UIViewAutoresizingFlexibleRightMargin |
                    UIViewAutoresizingFlexibleBottomMargin |
                    UIViewAutoresizingFlexibleLeftMargin;

        [parentController presentViewController:self animated:NO completion:nil];

        self.delegateAction = called;
    }
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)changeNotification:(NSNotification *)aNotification
{
    NSLog(@"%@changeNotification", classNameForLog);

    CGRect screen = [[UIScreen mainScreen] bounds];
    self.view.frame = CGRectMake(0, 0, screen.size.width, screen.size.height);

    if ( [[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        CGAffineTransform rotation = CGAffineTransformMakeRotation(angle90[orientation - 1] * M_PI / 180.0f);
        self.presentingViewController.view.transform = rotation;
        self.presentingViewController.view.frame = self.view.frame;
    }

    CGSize viewSize = [self getViewSize];
    if (isiPad) {
        [popoverController dismissPopoverAnimated:NO];
        [popoverController presentPopoverFromRect:CGRectMake(viewSize.width - 52, 30, 30, 30)
                                           inView:self.view
                         permittedArrowDirections:UIPopoverArrowDirectionUp
                                         animated:NO];
    }
    else {
        childView.frame = CGRectMake(0, viewSize.height - totalHeight, totalWidth, totalHeight);
    }
}

- (CGSize)getViewSize
{
    long viewHeight = self.view.frame.size.height;
    long viewWidth = self.view.frame.size.width;

    if ( [[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            viewHeight = self.view.frame.size.width;
            viewWidth = self.view.frame.size.height;
        }
    }
    return CGSizeMake(viewWidth, viewHeight);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSLog(@"%@viewDidLoad", classNameForLog);

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    NSLog(@"%@viewWillDisappear", classNameForLog);

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    NSLog(@"%@viewDidDisappear...isSelected...%d", classNameForLog, isSelected);

    if (isSelected) {
        if ([delegateAction respondsToSelector:@selector(selectedActionData: tag:)]) {
            [delegateAction selectedActionData:selectedItem tag:returnTag];
        }
        else {
            NSLog(@"%@cannot delegate selectedActionData", classNameForLog);
        }
    }
    else {
        if ([delegateAction respondsToSelector:@selector(cancelAction)]) {
            [delegateAction cancelAction];
        }
        else {
            NSLog(@"%@cannot delegate cancelAction", classNameForLog);
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSLog(@"%@viewWillAppear", classNameForLog);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSLog(@"%@viewDidAppear", classNameForLog);

    CGSize viewSize = [self getViewSize];

    if (isiPad) {
        childView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, totalWidth, totalHeight)];
    }
    else {
        childView = [[UIView alloc] initWithFrame:CGRectMake(0, viewSize.height, totalWidth, totalHeight)];
    }
    childView.backgroundColor = [UIColor whiteColor];
    childView.tag = 1;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, totalWidth - 10, titleHeight - 10)];
    label.backgroundColor = [UIColor whiteColor];
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.borderColor = [UIColor lightGrayColor].CGColor;
    label.layer.borderWidth = 1.0f;
    label.text = labelText;
    [childView addSubview:label];

    int idx;
    for (idx = 0; idx < [buttonData count]; idx++) {
        UIButton *button =[UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button setTitle:buttonData[idx] forState:UIControlStateNormal];
        button.titleLabel.font = [ UIFont systemFontOfSize:18];
        button.frame = CGRectMake(10, buttonHeight * idx + titleHeight + 5, totalWidth - 20, buttonHeight - 10);
        button.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.8];
        [[button layer] setCornerRadius:8.0f];
        button.tag = idx + 1;
        [button addTarget:self action:@selector(selectorButton:) forControlEvents:UIControlEventTouchDown];
        [childView addSubview:button];
    }

    if (isiPad) {
        UIViewController *vc = [[UIViewController alloc] init];
        vc.preferredContentSize = CGSizeMake(totalWidth, totalHeight);
        [vc setView:childView];

        popoverController = [[UIPopoverController alloc] initWithContentViewController:vc];
        popoverController.popoverContentSize = CGSizeMake(totalWidth, totalHeight);
        popoverController.delegate = self;

        [popoverController presentPopoverFromRect:CGRectMake(viewSize.width - 52, 30, 30, 30)
                                           inView:self.view
                         permittedArrowDirections:UIPopoverArrowDirectionUp
                                         animated:NO];
    }
    else {
        UIButton *cancelButton =[UIButton buttonWithType:UIButtonTypeRoundedRect];
        [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        cancelButton.frame = CGRectMake(10, buttonHeight * idx + titleHeight + 5, totalWidth - 20, buttonHeight - 10);
        cancelButton.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.8];
        [[cancelButton layer] setCornerRadius:8.0f];
        cancelButton.tag = 99;
        [cancelButton addTarget:self action:@selector(selectorCancelButton) forControlEvents:UIControlEventTouchDown];
        [childView addSubview:cancelButton];

        [self.view addSubview:childView];

        [UIView animateWithDuration:0.5f animations:^ {
            childView.frame = CGRectMake(0, viewSize.height - totalHeight, totalWidth, totalHeight);
        }];
    }

    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@touchesBegan", classNameForLog);
    UITouch *touch = [touches anyObject];
    if (touch.view.tag == 0) {
        [self selectorCancelButton];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    NSLog(@"%@popoverControllerDidDismissPopover", classNameForLog);
    [self selectorCancelButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)selectorButton:(id)sender
{
    isSelected = YES;
    selectedItem = buttonData[[sender tag] - 1];

    if (popoverController) {
        if (popoverController.popoverVisible) {
            [popoverController dismissPopoverAnimated:NO];
            popoverController = nil;
        }
    }
    [parentController dismissViewControllerAnimated:NO completion:nil];
}

- (void)selectorCancelButton
{
    isSelected = NO;

    if (popoverController) {
        if (popoverController.popoverVisible) {
            [popoverController dismissPopoverAnimated:NO];
            popoverController = nil;
        }
    }
    [parentController dismissViewControllerAnimated:NO completion:nil];
}

@end
