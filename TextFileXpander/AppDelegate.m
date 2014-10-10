//
//  AppDelegate.m
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "AppDelegate.h"
#import "MainTableViewController.h"

@implementation AppDelegate
{
    @private
    NSString *classNameForLog;
    NSString *sbName;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    classNameForLog = [NSStringFromClass(self.class) stringByAppendingString:@"..."];

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"firstTime"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstTime"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        NSString *src = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"txt"];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *dstDir = [paths objectAtIndex:0];
        NSString *dst = [dstDir stringByAppendingPathComponent:@"sample.txt"];

        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error;
        BOOL result = [fm copyItemAtPath:src toPath:dst error:&error];
        if (!result) {
            NSLog(@"%@didFinishLaunchingWithOptions...sample.txt copy error", classNameForLog);
        }
    }

    NSString *modelname = [[UIDevice currentDevice] model];
    NSLog(@"%@device model...%@", classNameForLog, modelname);
    if ([modelname hasPrefix:@"iPad"]) {
        sbName = @"Main_iPad";
    }
    else {
        sbName = @"Main_iPhone";
    }
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:sbName bundle:nil];
    MainTableViewController *mainController = [storyboard instantiateInitialViewController];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = mainController;
    [self.window makeKeyAndVisible];

    DBSession *dbSession = [[DBSession alloc]
                            initWithAppKey:NSLocalizedStringFromTable(@"DROPBOX_APP_KEY", @"Authentication", nil)
                            appSecret:NSLocalizedStringFromTable(@"DROPBOX_APP_SECRET", @"Authentication", nil)
                            root:kDBRootDropbox];
    [DBSession setSharedSession:dbSession];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
                        sourceApplication:(NSString *)source annotation:(id)annotation
{
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        BOOL isReadyDropbox;
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"%@App linked successfully!", classNameForLog);
            isReadyDropbox = YES;
        }
        else {
            NSLog(@"%@not link!", classNameForLog);
            isReadyDropbox = NO;
        }
        [[NSNotificationCenter defaultCenter]
                        postNotificationName:@"finishDropboxAuthentication"
                                      object:[NSNumber numberWithBool:isReadyDropbox]];
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
