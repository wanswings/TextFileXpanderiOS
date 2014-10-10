//
//  SubTableViewController.h
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SubTableViewController : UITableViewController

@property NSString *localFileName;
@property (nonatomic, retain) NSMutableArray *childArray;
@property (nonatomic, retain) NSMutableArray *childAttrArray;

@end
