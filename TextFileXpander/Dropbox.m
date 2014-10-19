//
//  Dropbox.m
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "Dropbox.h"
#import "Reachability.h"
#import "SimpleToast.h"

@implementation Dropbox
{
    @private
    BOOL asyncIsDir;
    BOOL asyncFinished;
    NSMutableArray *asyncResultArray;
    BOOL asyncResultBool;
    SimpleToast *toast;
}
@synthesize delegateDropbox;
@synthesize restClient;

- (id)initWithView:(id)parent refresh:(BOOL)refresh
{
    if (self = [super initWithView:parent refresh:refresh]) {
        classNameForLog = [NSStringFromClass(self.class) stringByAppendingString:@"..."];

        // for readyToReadPrivateFiles
        self.delegateStorage = parent;
        // for readyToStartDropboxAuthActivity
        self.delegateDropbox = parent;

        if (![[DBSession sharedSession] isLinked]) {
            if ([delegateDropbox respondsToSelector:@selector(readyToStartDropboxAuthActivity)]) {
                [delegateDropbox readyToStartDropboxAuthActivity];
            }
            else {
                NSLog(@"%@cannot delegate readyToStartDropboxAuthActivity", classNameForLog);
            }
        }
        else {
            [self selectDir];
        }
    }
    return self;
}

- (DBRestClient *)restClient
{
    NSLog(@"%@restClient", classNameForLog);
    if (!restClient) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = (id)self;
    }
    return restClient;
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
    if (restClient != nil) {
        restClient = nil;
    }
    [super close];
}

- (NSArray *)getEntriesAPI:(BOOL)isDir tPath:(NSString *)tPath
{
    asyncResultArray = [NSMutableArray array];

    if ([self isStorageAvailable] && [[DBSession sharedSession] isLinked]) {

        NSLog(@"%@getEntriesAPI...tPath...%@", classNameForLog, tPath);
        asyncIsDir = isDir;
        asyncFinished = NO;
        [self.restClient loadMetadata:tPath];

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
                                                    message:NSLocalizedString(@"error_dropbox", nil)
                                                       time:2.0f];
            }
        }
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
    return asyncResultArray;
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    if (metadata.isDirectory) {
        for (DBMetadata *file in metadata.contents) {
            if (asyncIsDir && file.isDirectory) {
                // dir
                NSLog(@"%@loadedMetadata...%@", classNameForLog, file.filename);
                [asyncResultArray addObject:file.filename];
            }
            else if (!asyncIsDir && !file.isDirectory) {
                // file
                if ([file.filename hasSuffix:TEXT_FILE_EXTENSION]) {
                    // Only text file
                    NSLog(@"%@loadedMetadata...%@", classNameForLog, file.filename);
                    [asyncResultArray addObject:file.filename];
                }
            }
        }
    }
    asyncFinished = YES;
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    NSLog(@"%@Error loading metadata...%@", classNameForLog, error);
    [asyncResultArray removeAllObjects];
    asyncFinished = YES;
    toast = [[SimpleToast alloc] initWithParams:parentView
                                        message:NSLocalizedString(@"error_dropbox", nil)
                                           time:2.0f];
}

- (BOOL)getFileAPI:(NSString *)tPath fname:(NSString *)fname
{
    asyncResultBool = NO;

    if ([self isStorageAvailable] && [[DBSession sharedSession] isLinked]) {

        asyncFinished = NO;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *dstDir = [paths objectAtIndex:0];
        NSString *dstPath = [dstDir stringByAppendingPathComponent:fname];
        [self.restClient loadFile:[tPath stringByAppendingPathComponent:fname] intoPath:dstPath];

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
                                                    message:NSLocalizedString(@"error_dropbox", nil)
                                                       time:2.0f];
            }
        }
        CFRunLoopStop(CFRunLoopGetCurrent());
    }

    return asyncResultBool;
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath
            contentType:(NSString *)contentType metadata:(DBMetadata *)metadata
{
    NSLog(@"%@loadedFile...%@", classNameForLog, localPath);
    asyncResultBool = YES;
    asyncFinished = YES;
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
    NSLog(@"%@Error loading a file...%@", classNameForLog, error);
    asyncResultBool = NO;
    asyncFinished = YES;
    toast = [[SimpleToast alloc] initWithParams:parentView
                                        message:NSLocalizedString(@"error_dropbox", nil)
                                           time:2.0f];
}

@end
