//
//  PickerViewController.h
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PickerViewControllerDelegate <NSObject>

@required
- (void)selectedPickerData:(NSString *)selectedName;
@optional
- (void)cancelPicker;

@end

@interface PickerViewController : UIViewController
                    <UIPickerViewDelegate, UIPickerViewDataSource, UIPopoverControllerDelegate>

@property (nonatomic, assign) id<PickerViewControllerDelegate> delegatePicker;

- (id)initWithParent:(id)parent
            delegate:(id)called
          pickerData:(NSArray *)array
               title:(NSString *)title
            selected:(NSString *)selected;
- (void)changeNotification:(NSNotification *)aNotification;

@end
