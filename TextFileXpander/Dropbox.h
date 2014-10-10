//
//  Dropbox.h
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "Storage.h"
#import <DropboxSDK/DropboxSDK.h>

@protocol DropboxDelegate <NSObject>

@required
- (void)readyToStartDropboxAuthActivity;

@end

@interface Dropbox : Storage

@property (nonatomic, assign) id<DropboxDelegate> delegateDropbox;
@property (nonatomic, strong) DBRestClient *restClient;

- (id)initWithView:(id)parent refresh:(BOOL)refresh;

@end
