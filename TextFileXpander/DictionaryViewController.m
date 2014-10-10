//
//  DictionaryViewController.m
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "DictionaryViewController.h"

static CGFloat const angle90[4] = {0.0f, 180.0f, 90.0f, 270.0f};

@implementation DictionaryViewController
{
@private
    NSString *classNameForLog;
}

- (id)initWithTerm:(NSString *)item
{
    if (self = [super initWithTerm:item]) {
        classNameForLog = [NSStringFromClass(self.class) stringByAppendingString:@"..."];
        NSLog(@"%@initWithParent", classNameForLog);
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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    NSLog(@"%@viewWillDisappear", classNameForLog);

    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [super dismissViewControllerAnimated:flag completion:completion];

    NSLog(@"%@dismissViewControllerAnimated", classNameForLog);

    [self.view removeFromSuperview];
}

@end
