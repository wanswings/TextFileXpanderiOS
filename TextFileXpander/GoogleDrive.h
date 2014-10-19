//
//  GoogleDrive.h
//  TextFileXpander
//
//  Created by wanswings on 2014/10/11.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "Storage.h"

@protocol GoogleDriveDelegate <NSObject>

@required
- (void)readyToStartGoogleAuthActivity;

@end

@interface GoogleDrive : Storage

@property (nonatomic, assign) id<GoogleDriveDelegate> delegateGoogleDrive;

- (id)initWithView:(id)parent refresh:(BOOL)refresh;

@end
