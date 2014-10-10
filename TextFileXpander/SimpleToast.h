//
//  SimpleToast.h
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SimpleToast : UIButton

- (id)initWithParams:(UIView *)view message:(NSString *)str time:(float)sec;

@end
