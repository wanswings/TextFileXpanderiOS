//
//  TextViewController.h
//  TextFileXpander
//
//  Created by wanswings on 2014/10/15.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionViewController.h"
#import "PickerViewController.h"

@interface TextViewController : UIViewController <ActionViewControllerDelegate, PickerViewControllerDelegate>

@property NSString *localFileName;

- (void)changeNotification:(NSNotification *)aNotification;

@end
