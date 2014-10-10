//
//  ActionViewController.h
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ActionViewControllerDelegate <NSObject>

@required
- (void)selectedActionData:(NSString *)selectedName tag:(int)tag;
@optional
- (void)cancelAction;

@end

@interface ActionViewController : UIViewController <UIPopoverControllerDelegate>

@property (nonatomic, assign) id<ActionViewControllerDelegate> delegateAction;

- (id)initWithParent:(id)parent
            delegate:(id)called
          buttonData:(NSArray *)array
               title:(NSString *)title
            selected:(NSString *)selected
                 tag:(int)tag;
- (void)changeNotification:(NSNotification *)aNotification;

@end
