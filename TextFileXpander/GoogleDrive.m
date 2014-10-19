//
//  GoogleDrive.m
//  TextFileXpander
//
//  Created by wanswings on 2014/10/11.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "GoogleDrive.h"
#import "AppDelegate.h"
#import "Reachability.h"
#import "SimpleToast.h"

static NSString *const DRIVE_API_FILES = @"https://www.googleapis.com/drive/v2/files";
static NSString *const MIME_FOLDER = @"application/vnd.google-apps.folder";
static NSString *const MIME_TEXT_PLAIN = @"text/plain";

@implementation GoogleDrive
{
    @private
    AppDelegate *appDelegate;
    NSDictionary *mFileList;
    BOOL asyncIsDir;
    BOOL asyncFinished;
    NSMutableArray *asyncResultArray;
    BOOL asyncResultBool;
    NSString *asyncFname;
    SimpleToast *toast;
}
@synthesize delegateGoogleDrive;

- (id)initWithView:(id)parent refresh:(BOOL)refresh
{
    if (self = [super initWithView:parent refresh:refresh]) {
        classNameForLog = [NSStringFromClass(self.class) stringByAppendingString:@"..."];
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

        // for readyToReadPrivateFiles
        self.delegateStorage = parent;
        // for readyToStartGoogleAuthActivity
        self.delegateGoogleDrive = parent;

        if (appDelegate.gtmOAuth2 == nil) {
            if ([delegateGoogleDrive respondsToSelector:@selector(readyToStartGoogleAuthActivity)]) {
                [delegateGoogleDrive readyToStartGoogleAuthActivity];
            }
            else {
                NSLog(@"%@cannot delegate readyToStartGoogleAuthActivity", classNameForLog);
            }
        }
        else {
            [self selectDir];
        }
    }
    return self;
}

- (BOOL)isStorageAvailable
{
    BOOL result = NO;

    Reachability *reachablity = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reachablity currentReachabilityStatus];
    if (status != NotReachable) {
        // online
        result = true;
    }
    else {
        toast = [[SimpleToast alloc] initWithParams:parentView
                                            message:NSLocalizedString(@"error_internet_not_available", nil)
                                               time:2.0f];
    }

    return result;
}

- (void)close
{
    if (appDelegate.gtmOAuth2 != nil) {
        appDelegate.gtmOAuth2 = nil;
    }
    [super close];
}

- (NSArray *)getEntriesAPI:(BOOL)isDir tPath:(NSString *)tPath
{
    asyncResultArray = [NSMutableArray array];

    NSString *parent = nil;
    for (NSDictionary *f in mFileList) {
        if ([tPath hasSuffix:[f objectForKey:@"title"]]) {
            parent = [NSString stringWithFormat:@"'%@'", [f objectForKey:@"id"]];

            NSArray *values = [NSArray arrayWithObjects:parent, nil];
            [prefs storeKeys:prefs->SAVE_KEYS_GOOGLE values:values];
            break;
        }
    }
    if (parent == nil) {
        parent = @"'root'";
        if (isRefresh) {
            NSArray *keys = [prefs getKeys:prefs->SAVE_KEYS_GOOGLE];
            if (keys != nil) {
                parent = keys[0];
            }
        }
    }
    NSLog(@"%@getEntriesAPI...parent...%@", classNameForLog, parent);
    mFileList = nil;

    if ([self isStorageAvailable] && appDelegate.gtmOAuth2 != nil) {
        BOOL isSignedIn = [appDelegate.gtmOAuth2 canAuthorize];
        if (isSignedIn) {
            NSLog(@"%@getEntriesAPI...tPath...%@", classNameForLog, tPath);
            asyncIsDir = isDir;
            asyncFinished = NO;

            NSString *mime;
            if (isDir) {
                mime = MIME_FOLDER;
            }
            else {
                mime = MIME_TEXT_PLAIN;
            }
            NSString *params = [NSString stringWithFormat:@"q=%@ in parents and trashed=false and mimeType = '%@'", parent, mime];
            params = [params stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", DRIVE_API_FILES, params]];
            NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
            NSString *token = [NSString stringWithFormat:@"OAuth %@", appDelegate.gtmOAuth2.accessToken];
            [req addValue:token forHTTPHeaderField:@"Authorization"];
            [req setHTTPMethod:@"GET"];

            GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:req];
            [fetcher beginFetchWithCompletionHandler:^(NSData *retrievedData, NSError *error) {
                if (error == nil) {
                    NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:retrievedData options:NSJSONReadingAllowFragments error:&error];
                    NSDictionary *items = [jsonResponse objectForKey:@"items"];
                    for (NSDictionary *json in items) {
                        NSString *fname = [json objectForKey:@"title"];
                        if (asyncIsDir) {
                            NSLog(@"%@getEntriesAPI...dir...%@", classNameForLog, fname);
                            [asyncResultArray addObject:fname];
                        }
                        else {
                            if ([fname hasSuffix:TEXT_FILE_EXTENSION]) {
                                NSLog(@"%@getEntriesAPI...file...%@", classNameForLog, fname);
                                [asyncResultArray addObject:fname];
                            }
                        }
                    }

                    mFileList = [items copy];
                    asyncFinished = YES;
                }
                else {
                    toast = [[SimpleToast alloc] initWithParams:parentView
                                                        message:NSLocalizedString(@"error_drive", nil)
                                                           time:2.0f];
                    asyncFinished = YES;
                }
            }];

            NSDate *sDate = [NSDate date];
            while (!asyncFinished) {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                         beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
                // 120s
                if([[NSDate date] timeIntervalSinceDate:sDate] >= 120) {
                    NSLog(@"%@getEntriesAPI...timeout error", classNameForLog);
                    [asyncResultArray removeAllObjects];
                    asyncFinished = YES;
                    toast = [[SimpleToast alloc] initWithParams:parentView
                                                        message:NSLocalizedString(@"error_drive", nil)
                                                           time:2.0f];
                }
            }
            CFRunLoopStop(CFRunLoopGetCurrent());
        }
    }
    return asyncResultArray;
}

- (BOOL)getFileAPI:(NSString *)tPath fname:(NSString *)fname
{
    asyncResultBool = NO;

    NSDictionary *file = nil;
    for (NSDictionary *f in mFileList) {
        if ([fname isEqualToString:[f objectForKey:@"title"]]) {
            file = f;
            break;
        }
    }

    if ([self isStorageAvailable] && appDelegate.gtmOAuth2 != nil && file != nil) {
        BOOL isSignedIn = [appDelegate.gtmOAuth2 canAuthorize];
        if (isSignedIn && [file objectForKey:@"downloadUrl"] != nil) {
            asyncFname = fname;
            asyncFinished = NO;

            NSURL *url = [NSURL URLWithString:[file objectForKey:@"downloadUrl"]];
            NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
            NSString *token = [NSString stringWithFormat:@"OAuth %@", appDelegate.gtmOAuth2.accessToken];
            [req addValue:token forHTTPHeaderField:@"Authorization"];
            [req setHTTPMethod:@"GET"];

            GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:req];
            [fetcher beginFetchWithCompletionHandler:^(NSData *retrievedData, NSError *error) {
                if (error == nil) {
                    NSString *fdata = [[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding];
                    NSLog(@"%@loadedFile...%@", classNameForLog, asyncFname);

                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *dstDir = [paths objectAtIndex:0];
                    NSString *dstPath = [dstDir stringByAppendingPathComponent:asyncFname];
                    [fdata writeToFile:dstPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                    asyncResultBool = YES;
                    asyncFinished = YES;
                }
                else {
                    toast = [[SimpleToast alloc] initWithParams:parentView
                                                        message:NSLocalizedString(@"error_drive", nil)
                                                           time:2.0f];
                    asyncFinished = YES;
                }
            }];

            NSDate *sDate = [NSDate date];
            while (!asyncFinished) {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                         beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
                // 120s
                if([[NSDate date] timeIntervalSinceDate:sDate] >= 120) {
                    NSLog(@"%@getFileAPI...timeout error", classNameForLog);
                    asyncResultBool = NO;
                    asyncFinished = YES;
                    toast = [[SimpleToast alloc] initWithParams:parentView
                                                        message:NSLocalizedString(@"error_drive", nil)
                                                           time:2.0f];
                }
            }
            CFRunLoopStop(CFRunLoopGetCurrent());
        }
    }
    
    return asyncResultBool;
}

@end
