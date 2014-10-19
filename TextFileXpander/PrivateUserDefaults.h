//
//  PrivateUserDefaults.h
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PrivateUserDefaults : NSObject
{
    @public
    NSString *SAVE_PREFS_NAME_MAIN;
    NSArray *SAVE_KEYS_MAIN;
    NSString *SAVE_PREFS_NAME_STORAGE;
    NSArray *SAVE_KEYS_STORAGE;
    NSArray *SAVE_KEYS_DROPBOX;
    NSArray *SAVE_KEYS_GOOGLE;
}

- (id)init:(NSString *)name;
- (void)clearAllKeys;
- (NSArray *)getKeys:(NSArray *)keys;
- (void)storeKeys:(NSArray *)keys values:(NSArray *)vals;

@end
