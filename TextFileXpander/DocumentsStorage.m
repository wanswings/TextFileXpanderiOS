//
//  DocumentsStorage.m
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "DocumentsStorage.h"

@implementation DocumentsStorage

- (id)initWithView:(id)parent refresh:(BOOL)refresh
{
    if (self = [super initWithView:parent refresh:refresh]) {
        classNameForLog = [NSStringFromClass(self.class) stringByAppendingString:@"..."];

        // for readyToReadPrivateFiles
        self.delegateStorage = parent;

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        topPath = [paths objectAtIndex:0];
        NSLog(@"%@initWithView...topPath...%@", classNameForLog, topPath);

        [self selectDir];
    }
    return self;
}

@end
