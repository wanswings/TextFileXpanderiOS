//
//  GoogleAuthViewController.m
//  TextFileXpander
//
//  Created by wanswings on 2014/10/11.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "GoogleAuthViewController.h"
#import "AppDelegate.h"
#import "PrivateUserDefaults.h"
#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2ViewControllerTouch.h"

static NSString *const kKeychainItemName = @"TextFileXpander";
static NSString *const kGTLAuthScopeDriveReadonly = @"https://www.googleapis.com/auth/drive.readonly";

@implementation GoogleAuthViewController
{
    @private
    NSString *SAVE_PREFS_NAME_STORAGE;
    NSString *classNameForLog;
    NSString *clientId;
    NSString *clientSecret;
    UIViewController *parentController;
    PrivateUserDefaults *prefs;
    AppDelegate *appDelegate;
    GTMOAuth2ViewControllerTouch *gvc;
    BOOL isClose;
    BOOL isReady;
}

- (id)initWithParent:(id)parent
{
    if (self = [super init]) {
        classNameForLog = [NSStringFromClass(self.class) stringByAppendingString:@"..."];
        NSLog(@"%@initWithParent", classNameForLog);

        parentController = parent;
        isClose = false;

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
    }
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    classNameForLog = [NSStringFromClass(self.class) stringByAppendingString:@"..."];
    NSLog(@"%@viewDidLoad", classNameForLog);

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *rPath = [bundle pathForResource:@"PrivateUserDefaults" ofType:@"plist"];
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:rPath];
    SAVE_PREFS_NAME_STORAGE = [dic objectForKey:@"SAVE_PREFS_NAME_STORAGE"];

    prefs = [[PrivateUserDefaults alloc] init:SAVE_PREFS_NAME_STORAGE];
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    clientId = NSLocalizedStringFromTable(@"GOOGLE_CLIENT_ID", @"Authentication", nil);
    clientSecret = NSLocalizedStringFromTable(@"GOOGLE_CLIENT_SECRET", @"Authentication", nil);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSLog(@"%@viewDidAppear", classNameForLog);

    if (isClose) {
        [parentController dismissViewControllerAnimated:NO completion:nil];
        return;
    }

    NSArray *keys = [prefs getKeys:prefs->SAVE_KEYS_GOOGLE];
    if (keys != nil) {
        appDelegate.gtmOAuth2 = [GTMOAuth2ViewControllerTouch
                        authForGoogleFromKeychainForName:kKeychainItemName
                                                clientID:clientId
                                            clientSecret:clientSecret];

        BOOL isSignedIn = [appDelegate.gtmOAuth2 canAuthorize];
        NSLog(@"%@isSignedIn...%d", classNameForLog, isSignedIn);
        if (isSignedIn) {
            [self authorizeRequest];
            return;
        }
    }

    gvc = [[GTMOAuth2ViewControllerTouch alloc]
                initWithScope:kGTLAuthScopeDriveReadonly
                     clientID:clientId
                 clientSecret:clientSecret
             keychainItemName:kKeychainItemName
                     delegate:self
             finishedSelector:@selector(viewController:finishedWithAuth:error:)];

    [self presentViewController:gvc animated:YES completion:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    NSLog(@"%@viewDidDisappear...isClose...%d...isReady...%d", classNameForLog, isClose, isReady);

    if (isClose) {
        isClose = NO;
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"finishGoogleAuthentication"
         object:[NSNumber numberWithBool:isReady]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth2 error:(NSError *)error
{
    if (error != nil) {
        // error
        NSLog(@"%@viewController...error", classNameForLog);
        isClose = true;
        isReady = false;
    }
    else {
        appDelegate.gtmOAuth2 = auth2;
        [self authorizeRequest];
    }
}

- (void)authorizeRequest
{
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:appDelegate.gtmOAuth2.tokenURL];
    [appDelegate.gtmOAuth2 authorizeRequest:req
                                   delegate:self
                          didFinishSelector:@selector(authentication:request:finishedWithError:)];
}

- (void)authentication:(GTMOAuth2Authentication *)auth
               request:(NSMutableURLRequest *)req
     finishedWithError:(NSError *)error
{
    if (error != nil) {
        // Authorization failed
        NSLog(@"%@Authorization...failed", classNameForLog);
        gvc = [[GTMOAuth2ViewControllerTouch alloc]
               initWithScope:kGTLAuthScopeDriveReadonly
               clientID:clientId
               clientSecret:clientSecret
               keychainItemName:kKeychainItemName
               delegate:self
               finishedSelector:@selector(viewController:finishedWithAuth:error:)];

        [self presentViewController:gvc animated:YES completion:nil];
    }
    else {
        // Authorization succeeded
        isClose = true;
        isReady = true;

        if (gvc != nil) {
            [gvc dismissViewControllerAnimated:NO completion:nil];
        }
        else {
            [parentController dismissViewControllerAnimated:NO completion:nil];
        }
    }
}

@end
