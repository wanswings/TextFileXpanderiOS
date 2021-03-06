//
//  PrivateUserDefaults.m
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "PrivateUserDefaults.h"

@implementation PrivateUserDefaults
{
    @private
    NSString *prefsName;
}

- (id)init:(NSString *)name
{
    if (self = [super init]) {
        prefsName = name;

        NSBundle *bundle = [NSBundle mainBundle];
        NSString *rPath = [bundle pathForResource:@"PrivateUserDefaults" ofType:@"plist"];
        NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:rPath];
        SAVE_PREFS_NAME_MAIN = [dic objectForKey:@"SAVE_PREFS_NAME_MAIN"];
        SAVE_KEYS_MAIN = [dic objectForKey:@"SAVE_KEYS_MAIN"];
        SAVE_PREFS_NAME_STORAGE = [dic objectForKey:@"SAVE_PREFS_NAME_STORAGE"];
        SAVE_KEYS_STORAGE = [dic objectForKey:@"SAVE_KEYS_STORAGE"];
        SAVE_KEYS_DROPBOX = [dic objectForKey:@"SAVE_KEYS_DROPBOX"];
        SAVE_KEYS_GOOGLE = [dic objectForKey:@"SAVE_KEYS_GOOGLE"];
        SAVE_PREFS_NAME_TEXTVIEW = [dic objectForKey:@"SAVE_PREFS_NAME_TEXTVIEW"];
        SAVE_KEYS_TEXTVIEW = [dic objectForKey:@"SAVE_KEYS_TEXTVIEW"];
    }
    return self;
}

- (void)clearAllKeys
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    for (id key in SAVE_KEYS_MAIN) {
        [prefs removeObjectForKey:key];
    }
    for (id key in SAVE_KEYS_STORAGE) {
        [prefs removeObjectForKey:key];
    }
    for (id key in SAVE_KEYS_DROPBOX) {
        [prefs removeObjectForKey:key];
    }
    for (id key in SAVE_KEYS_GOOGLE) {
        [prefs removeObjectForKey:key];
    }
    for (id key in SAVE_KEYS_TEXTVIEW) {
        [prefs removeObjectForKey:key];
    }

    [prefs synchronize];
}

- (NSArray *)getKeys:(NSArray *)keys
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSArray *result = [NSArray array];
    BOOL existValue = NO;

    for (id key in keys) {
        NSString *value = [prefs stringForKey:key];
        if (value == nil) {
            result = [result arrayByAddingObject:@""];
        }
        else {
            result = [result arrayByAddingObject:value];
            existValue = YES;
        }
    }
    if (existValue)
        return result;
    else
        return nil;
}

- (void)storeKeys:(NSArray *)keys values:(NSArray *)vals
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        if (![vals[idx] isEqualToString:@""]) {
            [prefs setObject:vals[idx] forKey:key];
        }
    }];

    [prefs synchronize];
}

- (void)clearKeys
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    if ([prefsName isEqualToString:SAVE_PREFS_NAME_MAIN]) {
        for (id key in SAVE_KEYS_MAIN) {
            [prefs removeObjectForKey:key];
        }
    }
    else if ([prefsName isEqualToString:SAVE_PREFS_NAME_STORAGE]) {
        for (id key in SAVE_KEYS_STORAGE) {
            [prefs removeObjectForKey:key];
        }
        for (id key in SAVE_KEYS_DROPBOX) {
            [prefs removeObjectForKey:key];
        }
        for (id key in SAVE_KEYS_GOOGLE) {
            [prefs removeObjectForKey:key];
        }
    }
    else if ([prefsName isEqualToString:SAVE_PREFS_NAME_TEXTVIEW]) {
        for (id key in SAVE_KEYS_TEXTVIEW) {
            [prefs removeObjectForKey:key];
        }
    }

    [prefs synchronize];
}

@end
