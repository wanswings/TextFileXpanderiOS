//
//  SimpleToast.m
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "SimpleToast.h"
#import <QuartzCore/QuartzCore.h>

@implementation SimpleToast

- (id)initWithParams:(UIView *)view message:(NSString *)str time:(float)sec
{
    UIFont *font = [UIFont systemFontOfSize:16];
    CGSize textSize = [str sizeWithAttributes:@{NSFontAttributeName:font}];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, textSize.width + 4, textSize.height + 4)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = font;
    label.text = str;
    label.numberOfLines = 0;
    label.shadowColor = [UIColor darkGrayColor];
    label.shadowOffset = CGSizeMake(1, 1);

    self = [SimpleToast buttonWithType:UIButtonTypeCustom];
    self.frame = CGRectMake(0, 0, textSize.width + 20, textSize.height + 20);
    label.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [self addSubview:label];

    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    [[self layer] setCornerRadius:10.0f];
    [self setClipsToBounds:YES];

    CGPoint point = CGPointMake(view.frame.size.width / 2, view.frame.size.height - 100);
    self.center = point;

    [view addSubview:self];

    [NSTimer scheduledTimerWithTimeInterval:sec target:self selector:@selector(closeToast) userInfo:nil repeats:NO];

    return self;
}

- (void)closeToast
{
    NSLog(@"hidden toast");
    self.hidden = YES;
}

@end
