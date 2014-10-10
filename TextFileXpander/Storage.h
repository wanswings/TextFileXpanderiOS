//
//  Storage.h
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PrivateUserDefaults.h"
#import "PickerViewController.h"

@protocol StorageDelegate <NSObject>

@required
- (void)readyToReadPrivateFiles;
- (void)cancelSelectDirDialog;

@end

@interface Storage : NSObject <PickerViewControllerDelegate>
{
    @protected
    UIView *parentView;
    NSString *TEXT_FILE_EXTENSION;
    NSString *FILE_SEPARATOR;
    NSString *classNameForLog;
    PrivateUserDefaults *prefs;
    NSString *topPath;
}

@property (nonatomic, assign) id<StorageDelegate> delegateStorage;

- (id)initWithView:(id)parent refresh:(BOOL)refresh;
- (BOOL)isStorageAvailable;
- (void)close;
- (void)selectDir;
- (NSArray *)getEntriesAPI:(BOOL)isDir tPath:(NSString *)tPath;
- (BOOL)getFileAPI:(NSString *)tPath fname:(NSString *)fname;

+ (void)deleteLocalFiles;

@end
