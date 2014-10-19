//
//  Storage.m
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "Storage.h"

@implementation Storage
{
    @private
    UITableViewController *parentController;
    UIActivityIndicatorView *indicator;
    NSString *SAVE_PREFS_NAME_STORAGE;
    NSString *currentPath;
    NSString *selectedFname;
    PickerViewController *dialog;
}
@synthesize delegateStorage;

- (void)dealloc
{
    NSLog(@"%@dealloc", classNameForLog);
    [indicator removeFromSuperview];
    parentView.userInteractionEnabled = YES;
    parentController.navigationController.navigationBar.userInteractionEnabled = YES;
}

- (id)initWithView:(id)parent refresh:(BOOL)refresh
{
    if (self = [super init]) {
        classNameForLog = [NSStringFromClass(self.class) stringByAppendingString:@"..."];

        parentController = (UITableViewController *)parent;
        parentView = parentController.view;
        isRefresh = refresh;

        TEXT_FILE_EXTENSION = @".txt";
        FILE_SEPARATOR = @"/";

        NSBundle *bundle = [NSBundle mainBundle];
        NSString *rPath = [bundle pathForResource:@"PrivateUserDefaults" ofType:@"plist"];
        NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:rPath];
        SAVE_PREFS_NAME_STORAGE = [dic objectForKey:@"SAVE_PREFS_NAME_STORAGE"];

        topPath = FILE_SEPARATOR;	// Root
        prefs = [[PrivateUserDefaults alloc] init:SAVE_PREFS_NAME_STORAGE];
        NSArray *keys = [prefs getKeys:prefs->SAVE_KEYS_STORAGE];
        if (keys != nil) {
            currentPath = keys[0];
        }
        else {
            currentPath = @"";
        }

        indicator = [[UIActivityIndicatorView alloc]
                     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicator.color = [UIColor blackColor];
        indicator.center = parentView.center;
        indicator.autoresizingMask =
                    UIViewAutoresizingFlexibleTopMargin |
                    UIViewAutoresizingFlexibleRightMargin |
                    UIViewAutoresizingFlexibleBottomMargin |
                    UIViewAutoresizingFlexibleLeftMargin;
        [parentView addSubview:indicator];
    }
    return self;
}

- (BOOL)isStorageAvailable
{
    return true;
}

- (void)close
{
    NSLog(@"%@close", classNameForLog);
}

- (void)selectDir
{
    if (![self isStorageAvailable]) {
        return;
    }
    if (isRefresh) {
        [self getFiles];
        return;
    }

    [self GetEntriesBackground:true tPath:topPath];
}

- (void)finishBackgroundGetEntries4Dir:(id)param
{
    NSArray *result = (NSArray *)param;

    if ([result count] > 0) {
        // sort
        NSArray *dirs = [result sortedArrayUsingSelector:@selector(compare:)];
        selectedFname = [currentPath lastPathComponent];

        dialog = [[PickerViewController alloc]
                  initWithParent:parentController
                  delegate:self
                  pickerData:dirs
                  title:NSLocalizedString(@"dialog_title_select_dir", nil)
                  selected:selectedFname];
    }
    else {
        // no directory
        [self cancelPicker];
    }
}

- (void)selectedPickerData:(NSString *)selectedName
{
    NSLog(@"%@selectedPickerData...%@", classNameForLog, selectedName);

    selectedFname = selectedName;

    currentPath = [[topPath stringByAppendingString:FILE_SEPARATOR] stringByAppendingPathComponent:selectedFname];

    NSArray *values = [NSArray arrayWithObjects:currentPath, nil];
    [prefs storeKeys:prefs->SAVE_KEYS_STORAGE values:values];

    [self getFiles];
}

- (void)cancelPicker
{
    if ([delegateStorage respondsToSelector:@selector(cancelSelectDirDialog)]) {
        [delegateStorage cancelSelectDirDialog];
    }
    else {
        NSLog(@"%@cannot delegate cancelSelectDirDialog", classNameForLog);
    }
}

- (void)finishBackgroundGetEntries4File:(id)param
{
    NSArray *result = (NSArray *)param;

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *localDir = [paths objectAtIndex:0];
    if ([localDir isEqualToString:currentPath]) {
        // finish for local
        [self finishBackgroundGetFiles:[NSNumber numberWithBool:YES]];
    }
    else {
        [Storage deleteLocalFiles];
        [self GetFilesBackground:currentPath entries:result];
    }
}

- (void)getFiles
{
    if (![self isStorageAvailable] || [currentPath isEqualToString:@""]) {
        return;
    }

    [self GetEntriesBackground:false tPath:currentPath];
}

- (void)finishBackgroundGetFiles:(id)result
{
    if ([delegateStorage respondsToSelector:@selector(readyToReadPrivateFiles)]) {
        [delegateStorage readyToReadPrivateFiles];
    }
    else {
        NSLog(@"%@cannot delegate readyToReadPrivateFiles", classNameForLog);
    }
}

// for local storage
- (NSArray *)getEntriesAPI:(BOOL)isDir tPath:(NSString *)tPath
{
    NSMutableArray *result = [NSMutableArray array];

    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDirectory;
    for (NSString *fname in [fileManager contentsOfDirectoryAtPath:tPath error:&error]) {
        NSString *fPath = [tPath stringByAppendingPathComponent:fname];

        if ([fileManager fileExistsAtPath:fPath isDirectory: &isDirectory] && isDirectory) {
            // dir
            if (isDir) {
                [result addObject:fname];
            }
        }
        else if (!isDir) {
            // file
            NSDictionary *attrs = [fileManager attributesOfItemAtPath:fPath error:&error];
            if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeRegular] &&
                                        [fname hasSuffix:TEXT_FILE_EXTENSION]) {
                // Only text file
                [result addObject:fname];
            }
        }
    }

    return result;
}

// for local storage
- (BOOL)getFileAPI:(NSString *)tPath fname:(NSString *)fname
{
    BOOL result = NO;

    NSError *error = nil;
    NSString *fPath = [tPath stringByAppendingPathComponent:fname];
    NSString *fdata = [NSString stringWithContentsOfFile:fPath
                                encoding:NSUTF8StringEncoding error:&error];
    if (error == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *dstDir = [paths objectAtIndex:0];
        NSString *dstPath = [dstDir stringByAppendingPathComponent:fname];
        [fdata writeToFile:dstPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        if (error == nil) {
            result = YES;
        }
    }

    return result;
}

+ (void)deleteLocalFiles
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dstDir = [paths objectAtIndex:0];
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDirectory;
    for (NSString *fname in [fileManager contentsOfDirectoryAtPath:dstDir error:&error]) {
        NSString *fPath = [dstDir stringByAppendingPathComponent:fname];
        if ([fileManager fileExistsAtPath:fPath isDirectory: &isDirectory] && isDirectory) {
        }
        else {
            BOOL deleted = [fileManager removeItemAtPath:fPath error:&error];
            if (deleted != YES || error != nil) {
                // error
                NSLog(@"deleteLocalFiles error...%@", error);
            }
        }
    }
}

- (void)GetEntriesBackground:(BOOL)isDir tPath:(NSString *)tPath
{
    NSDictionary *param = @{
        @"isDir": [NSNumber numberWithBool:isDir],
        @"tPath": tPath,
    };
    [self performSelectorInBackground:@selector(backgroundGetEntries:) withObject:param];
    [indicator startAnimating];
    parentView.userInteractionEnabled = NO;
    parentController.navigationController.navigationBar.userInteractionEnabled = NO;
}

- (void)backgroundGetEntries:(id)param
{
    @autoreleasepool {
        BOOL isDir = [(NSNumber *)param[@"isDir"] boolValue];
        NSString *tPath = param[@"tPath"];

        NSArray *result = [self getEntriesAPI:isDir tPath:tPath];

        [indicator stopAnimating];
        parentView.userInteractionEnabled = YES;
        parentController.navigationController.navigationBar.userInteractionEnabled = YES;
        if (isDir) {
            [self performSelectorOnMainThread:@selector(finishBackgroundGetEntries4Dir:)
                                   withObject:result waitUntilDone:NO];
        }
        else {
            [self performSelectorOnMainThread:@selector(finishBackgroundGetEntries4File:)
                                   withObject:result waitUntilDone:NO];
        }
    }
}

- (void)GetFilesBackground:(NSString *)fpath entries:(NSArray *)entries
{
    NSDictionary *param = @{
        @"fpath": fpath,
        @"entries": entries,
    };
    [self performSelectorInBackground:@selector(backgroundGetFiles:) withObject:param];
    [indicator startAnimating];
    parentView.userInteractionEnabled = NO;
    parentController.navigationController.navigationBar.userInteractionEnabled = NO;
}

- (void)backgroundGetFiles:(id)param
{
    @autoreleasepool {
        NSString *fpath = param[@"fpath"];
        NSArray *entries = param[@"entries"];
        BOOL result = NO;

        for (NSString *fname in entries) {
            result = [self getFileAPI:fpath fname:fname];
            if (!result) {
                break;
            }
        }

        [indicator stopAnimating];
        parentView.userInteractionEnabled = YES;
        parentController.navigationController.navigationBar.userInteractionEnabled = YES;
        [self performSelectorOnMainThread:@selector(finishBackgroundGetFiles:)
                               withObject:[NSNumber numberWithBool:result] waitUntilDone:NO];
    }
}

@end
