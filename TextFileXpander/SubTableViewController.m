//
//  SubTableViewController.m
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "SubTableViewController.h"
#import "MainTableViewController.h"
#import "DictionaryViewController.h"

static NSInteger const ATTR_SEPARATOR = 1;
static NSInteger const ATTR_DATA = 2;

@implementation SubTableViewController
{
    @private
    NSString *classNameForLog;
}
@synthesize localFileName;
@synthesize childArray;
@synthesize childAttrArray;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    classNameForLog = [NSStringFromClass(self.class) stringByAppendingString:@"..."];
    // for iOS7
    self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;

    childArray = [NSMutableArray array];
    childAttrArray = [NSMutableArray array];

    UILongPressGestureRecognizer *longPressGesture =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(childItemLongClick:)];
    longPressGesture.minimumPressDuration = 1.0;
    [self.view addGestureRecognizer:longPressGesture];

    if (localFileName == nil) {
        self.title = NSLocalizedString(@"title_activity_sub", nil);
    }
    else {
        NSLog(@"%@viewDidLoad...localFileName...%@", classNameForLog, localFileName);
        self.title = localFileName;
        [self refreshLocalData:localFileName];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)refreshLocalData:(NSString *)fname
{
    NSLog(@"%@refreshLocalData", classNameForLog);

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dstDir = [paths objectAtIndex:0];
    NSString *fullPath = [dstDir stringByAppendingPathComponent:fname];
    NSError *error = nil;
    NSString *fdata = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        NSString *pattern = @"^(-{2}-+)\\s*(.*)";
        NSRegularExpression *regexp = [NSRegularExpression
                                       regularExpressionWithPattern:pattern
                                       options:NSRegularExpressionCaseInsensitive
                                       error:&error];

        [childArray removeAllObjects];
        [childAttrArray removeAllObjects];

        [fdata enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            if (line.length > 0) {
                @autoreleasepool {
                    NSTextCheckingResult *match =
                            [regexp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
                    if (match) {
                        NSString *matchStr = [line substringWithRange:[match rangeAtIndex:2]];
                        [childArray addObject:matchStr];
                        [childAttrArray addObject:[NSNumber numberWithInt:ATTR_SEPARATOR]];
                    }
                    else {
                        [childArray addObject:line];
                        [childAttrArray addObject:[NSNumber numberWithInt:ATTR_DATA]];
                    }
                }
            }
        }];

        [self.tableView reloadData];
     }
}

- (void)childItemLongClick:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint p = [sender locationInView:self.tableView];
        NSIndexPath *idx = [self.tableView indexPathForRowAtPoint:p];
        [self childItemClick:idx isLongTap:YES];
    }
}

- (void)childItemClick:(NSIndexPath *)indexPath isLongTap:(BOOL)isLong
{
    NSString *str = [childArray objectAtIndex:indexPath.row];

    NSString *pattern = @"^([a-z]+):\\s*(.+)";
    NSError *error = nil;
    NSRegularExpression *regexp = [NSRegularExpression
                                   regularExpressionWithPattern:pattern
                                   options:NSRegularExpressionCaseInsensitive
                                   error:&error];
    NSTextCheckingResult *match = [regexp firstMatchInString:str
                                                     options:0 range:NSMakeRange(0, str.length)];
    if (match) {
        NSString *matchCmd = [str substringWithRange:[match rangeAtIndex:1]];
        NSLog(@"%@pushData...matchCmd...%@", classNameForLog, matchCmd);
        NSString *matchStr = [str substringWithRange:[match rangeAtIndex:2]];
        NSLog(@"%@pushData...matchStr...%@", classNameForLog, matchStr);

        NSString *sendStr = nil;

        if ([matchCmd isEqual:@"dict"]) {
            // dict
            if (isLong) {
                str = matchStr;
            }
            else {
                [self launchDict:matchStr];
                return;
            }
        }
        else if ([matchCmd isEqual:@"flight"]) {
            // flight
            sendStr = [@"http://www.google.com/search?q=flight%20" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"mailto"]) {
            // mailto
            sendStr = [NSString stringWithFormat:@"mailto:%@", matchStr];
        }
        else if ([matchCmd isEqual:@"map"]) {
            // map
            sendStr = [@"http://maps.google.com/maps?q=" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"near"]) {
            // near
            sendStr = [@"http://foursquare.com/explore?near=" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"people"]) {
            // people
            str = matchStr;
        }
        else if ([matchCmd isEqual:@"route"]) {
            // route
            NSString *pattern2 = @"^\\s*from:\\s*(.+)\\s+to:\\s*(.+)";
            NSRegularExpression *regexp2 = [NSRegularExpression
                                            regularExpressionWithPattern:pattern2
                                            options:NSRegularExpressionCaseInsensitive
                                            error:&error];
            NSTextCheckingResult *match2 = [regexp2 firstMatchInString:matchStr
                                                               options:0 range:NSMakeRange(0, matchStr.length)];
            if (match2) {
                NSString *matchfrom = [matchStr substringWithRange:[match2 rangeAtIndex:1]];
                NSLog(@"%@pushData...matchfrom...%@", classNameForLog, matchfrom);
                NSString *matchto = [matchStr substringWithRange:[match2 rangeAtIndex:2]];
                NSLog(@"%@pushData...matchto...%@", classNameForLog, matchto);
                
                NSMutableString *wk = [NSMutableString string];
                [wk setString:@"http://maps.google.com/maps?saddr="];
                [wk appendString:[matchfrom stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [wk appendString:@"&daddr="];
                [wk appendString:[matchto stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                sendStr = wk;
            }
        }
        else if ([matchCmd isEqual:@"tel"]) {
            // tel
            sendStr = [NSString stringWithFormat:@"tel:%@", matchStr];
        }
        else if ([matchCmd isEqual:@"twitter"]) {
            // twitter
            sendStr = [@"twitter://post?message=" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"url"]) {
            // url
            sendStr = matchStr;
        }
        else if ([matchCmd isEqual:@"weather"]) {
            // weather
            sendStr = [@"http://www.weather.com/search/enhancedlocalsearch?where=" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"youtube"]) {
            // youtube
            sendStr = [@"http://www.youtube.com/results?search_query=" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }

        if (sendStr != nil) {
            if (isLong) {
                str = matchStr;
            }
            else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:sendStr]]) {
                NSLog(@"%@pushData...%@: %@", classNameForLog, matchCmd, sendStr);
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:sendStr]];
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                return;
            }
            else {
                str = matchStr;
            }
        }
    }

    // back to main
    MainTableViewController *parent = [self.navigationController.viewControllers objectAtIndex:0];
    [parent fromSubTableViewClick:str];
    [self.navigationController popToViewController:parent animated:YES];
}

- (void)launchDict:(NSString *)item
{
    NSLog(@"%@launchDict...%@", classNameForLog, item);

    DictionaryViewController *controller = [[DictionaryViewController alloc] initWithTerm:item];
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSLog(@"%@tableView numberOfRowsInSection...%lu", classNameForLog, (unsigned long)childArray.count);
    return childArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[childAttrArray objectAtIndex:indexPath.row] intValue] == ATTR_SEPARATOR) {
        if (tableView.rowHeight < 0) {
            return 44.0f - 14.0f;
        }
        else {
            return tableView.rowHeight - 14.0f;
        }
    }
    else {
        return tableView.rowHeight;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ChildCell";
    UITableViewCell *cellView = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    // Configure the cell...
    if (cellView == nil) {
        cellView = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ChildCell"];
    }
    cellView.textLabel.text = [childArray objectAtIndex:indexPath.row];

    return cellView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell
                                                forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[childAttrArray objectAtIndex:indexPath.row] intValue] == ATTR_SEPARATOR) {
        cell.backgroundColor = [UIColor lightGrayColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else {
        cell.backgroundColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[childAttrArray objectAtIndex:indexPath.row] intValue] == ATTR_DATA) {
        [self childItemClick:indexPath isLongTap:NO];
    }
}

@end
