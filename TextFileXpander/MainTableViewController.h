//
//  MainTableViewController.h
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubTableViewController.h"
#import "TextViewController.h"
#import "ActionViewController.h"
#import "Dropbox.h"
#import "DocumentsStorage.h"

@interface MainTableViewController : UITableViewController
                                        <ActionViewControllerDelegate,
                                        UIDocumentInteractionControllerDelegate,
                                        StorageDelegate>

@property (nonatomic, retain) NSMutableArray *groupArray;
@property UIDocumentInteractionController *interactionController;

- (void)fromSubTableViewClick:(NSString *)result;

@end
