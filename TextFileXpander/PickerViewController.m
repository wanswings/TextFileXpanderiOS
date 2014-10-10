//
//  PickerViewController.m
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "PickerViewController.h"

static CGFloat const angle90[4] = {0.0f, 180.0f, 90.0f, 270.0f};

@implementation PickerViewController
{
    @private
    NSString *classNameForLog;
    UIViewController *parentController;
    UIView *parentView;
    UIView *childView;
    UIPickerView *pickerView;
    NSArray *pickerData;
    NSString *labelText;
    UIToolbar *toolbar;
    NSString *selectedItem;
    BOOL isiPad;
    UIPopoverController *popoverController;
    BOOL isSelected;
    long totalHeight;
    long totalWidth;
}
@synthesize delegatePicker;

- (id)initWithParent:(id)parent
            delegate:(id)called
          pickerData:(NSArray *)array
               title:(NSString *)title
            selected:(NSString *)selected
{
    if (self = [super init]) {
        classNameForLog = [NSStringFromClass(self.class) stringByAppendingString:@"..."];
        NSLog(@"%@initWithParent", classNameForLog);

        parentController = parent;
        parentView = parentController.view;
        pickerData = array;
        labelText = title;
        selectedItem = selected;
        if ([[[UIDevice currentDevice] model] hasPrefix:@"iPad"]) {
            isiPad = YES;
        }
        else {
            isiPad = NO;
        }
        totalHeight = 300;
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

        [parentController presentViewController:self animated:NO completion:nil];

        self.delegatePicker = called;
    }
    return self;
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
        if ([delegatePicker respondsToSelector:@selector(selectedPickerData:)]) {
            [delegatePicker selectedPickerData:selectedItem];
        }
        else {
            NSLog(@"%@cannot delegate selectedPickerData", classNameForLog);
        }
    }
    else {
        if ([delegatePicker respondsToSelector:@selector(cancelPicker)]) {
            [delegatePicker cancelPicker];
        }
        else {
            NSLog(@"%@cannot delegate cancelPicker", classNameForLog);
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

    CGRect pickerFrame = CGRectMake(0, 40, totalWidth, totalHeight - 40 - 44);
    pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerView.dataSource = self;
    pickerView.delegate = self;
    pickerView.showsSelectionIndicator = YES;
    pickerView.tag = 1;

    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, totalWidth, 44)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 180, 34)];
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
//    label.layer.borderWidth = 1.0f;
    label.text = labelText;
    UIBarButtonItem *titleLabel = [[UIBarButtonItem alloc] initWithCustomView:label];
    UIBarButtonItem *doneButton =[[UIBarButtonItem alloc]
                                  initWithTitle:@"Done"
                                  style:UIBarButtonItemStyleBordered
                                  target:self
                                  action:@selector(selectorDoneButton)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                  target:nil
                                  action:nil];
    if (!isiPad) {
        UIBarButtonItem *cancelButton =[[UIBarButtonItem alloc]
                                        initWithTitle:@"Cancel"
                                        style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(selectorCancelButton)];
        toolbar.items = [NSArray arrayWithObjects:cancelButton, flexSpace, titleLabel, flexSpace, doneButton, nil];
    }
    else {
        toolbar.items = [NSArray arrayWithObjects:flexSpace, titleLabel, flexSpace, doneButton, nil];
    }
    toolbar.tag = 2;

    if (isiPad) {
        childView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, totalWidth, totalHeight)];
    }
    else {
        childView = [[UIView alloc] initWithFrame:CGRectMake(0, viewSize.height, totalWidth, totalHeight)];
    }
    childView.backgroundColor = [UIColor whiteColor];
    childView.tag = 3;
    [childView addSubview:pickerView];
    [childView addSubview:toolbar];

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)selectorDoneButton
{
    isSelected = YES;
    selectedItem = pickerData[[pickerView selectedRowInComponent:0]];

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

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerData == nil)
        return 0;
    else
        return pickerData.count;
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view
{
    UITableViewCell *cell = (UITableViewCell *)view;

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        [cell setBackgroundColor:[UIColor clearColor]];
        if ([[pickerData objectAtIndex:row] isEqualToString:selectedItem]) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
        cell.textLabel.text = pickerData[row];
    }

    return cell;
}

@end
