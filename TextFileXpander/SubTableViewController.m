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
#import "Reachability.h"

static NSInteger const ATTR_SEPARATOR = 1;
static NSInteger const ATTR_NORMAL = 2;
static NSInteger const ATTR_MARKER_NORMAL = 3;
static NSInteger const ATTR_MARKER_STRONG = 4;
static NSInteger const ATTR_MARKER_WEAK = 5;
static NSInteger const ATTR_CURRENCY = 6;

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

- (BOOL)prefersStatusBarHidden {
    return NO;
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
    NSError *error0 = nil;
    NSString *fdata = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&error0];
    if (!error0) {
        NSString *pattern1 = @"^(-{2}-+)\\s*(.*)";
        NSString *pattern2 = @"^([a-z]+):(.+)";

        [childArray removeAllObjects];
        [childAttrArray removeAllObjects];

        __block int idxSub = 0;
        [fdata enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            if (line.length > 0) {
                @autoreleasepool {
                    NSError *error1 = nil;
                    NSRegularExpression *regexp1 = [NSRegularExpression
                                                    regularExpressionWithPattern:pattern1
                                                    options:NSRegularExpressionCaseInsensitive
                                                    error:&error1];
                    NSTextCheckingResult *match1 =
                            [regexp1 firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
                    if (match1) {
                        NSString *matchStr = [line substringWithRange:[match1 rangeAtIndex:2]];
                        [childArray addObject:matchStr];
                        [childAttrArray addObject:[NSNumber numberWithInt:ATTR_SEPARATOR]];
                    }
                    else {
                        int attr = ATTR_NORMAL;

                        NSError *error2 = nil;
                        NSRegularExpression *regexp2 = [NSRegularExpression
                                                        regularExpressionWithPattern:pattern2
                                                        options:NSRegularExpressionCaseInsensitive
                                                        error:&error2];
                        NSTextCheckingResult *match2 =
                                [regexp2 firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
                        if (match2) {
                            NSString *matchCmd = [line substringWithRange:[match2 rangeAtIndex:1]];
                            NSString *matchStr = [line substringWithRange:[match2 rangeAtIndex:2]];

                            if ([matchCmd isEqual:@"currency"]) {
                                // currency
                                [self getCurrencyStart:matchStr idxSub:idxSub];
                            }
                            else if ([matchCmd isEqual:@"marker"]) {
                                // marker
                                attr = [self getMarkerColor:matchStr line:&line];
                            }
                        }
                        [childArray addObject:line];
                        [childAttrArray addObject:[NSNumber numberWithInt:attr]];
                    }
                    idxSub++;
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

    NSString *pattern1 = @"^([a-z]+):\\s*(.+)";
    NSError *error1 = nil;
    NSRegularExpression *regexp1 = [NSRegularExpression
                                    regularExpressionWithPattern:pattern1
                                    options:NSRegularExpressionCaseInsensitive
                                    error:&error1];
    NSTextCheckingResult *match1 = [regexp1 firstMatchInString:str
                                                     options:0 range:NSMakeRange(0, str.length)];
    if (match1) {
        NSString *matchCmd = [str substringWithRange:[match1 rangeAtIndex:1]];
        NSLog(@"%@pushData...matchCmd...%@", classNameForLog, matchCmd);
        NSString *matchStr = [str substringWithRange:[match1 rangeAtIndex:2]];
        NSLog(@"%@pushData...matchStr...%@", classNameForLog, matchStr);

        NSString *sendStr = nil;

        if ([matchCmd isEqual:@"currency"]) {
            // currency
            NSString *pattern2 = @"^\\s*from:\\s*(.+)\\s+to:\\s*(\\S+)";
            NSError *error2 = nil;
            NSRegularExpression *regexp2 = [NSRegularExpression
                                            regularExpressionWithPattern:pattern2
                                            options:NSRegularExpressionCaseInsensitive
                                            error:&error2];
            NSTextCheckingResult *match2 = [regexp2 firstMatchInString:matchStr
                                                               options:0 range:NSMakeRange(0, matchStr.length)];
            if (match2) {
                NSString *matchfrom = [matchStr substringWithRange:[match2 rangeAtIndex:1]];
                NSString *matchto = [matchStr substringWithRange:[match2 rangeAtIndex:2]];
                
                NSMutableString *wk = [NSMutableString string];
                [wk setString:@"http://www.google.com/finance/?q="];
                [wk appendString:[matchfrom stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [wk appendString:[matchto stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                sendStr = wk;
            }
        }
        else if ([matchCmd isEqual:@"dict"]) {
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
            sendStr = [@"http://flightaware.com/live/flight/" stringByAppendingString:
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
        else if ([matchCmd isEqual:@"recipe"]) {
            // recipe
            sendStr = [@"http://www.epicurious.com/tools/searchresults?search=" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"route"]) {
            // route
            NSString *pattern2 = @"^\\s*from:\\s*(.+)\\s+to:\\s*(.+)";
            NSError *error2 = nil;
            NSRegularExpression *regexp2 = [NSRegularExpression
                                            regularExpressionWithPattern:pattern2
                                            options:NSRegularExpressionCaseInsensitive
                                            error:&error2];
            NSTextCheckingResult *match2 = [regexp2 firstMatchInString:matchStr
                                                               options:0 range:NSMakeRange(0, matchStr.length)];
            if (match2) {
                NSString *matchfrom = [matchStr substringWithRange:[match2 rangeAtIndex:1]];
                NSString *matchto = [matchStr substringWithRange:[match2 rangeAtIndex:2]];
                
                NSMutableString *wk = [NSMutableString string];
                [wk setString:@"http://maps.google.com/maps?saddr="];
                if (![matchfrom isEqual:@"here"]) {
                    [wk appendString:[matchfrom stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                }
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
            sendStr = [@"http://www.google.com/search?q=weather%20" stringByAppendingString:
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

- (int)getMarkerColor:(NSString *)param line:(NSString **)line
{
    int attr = ATTR_NORMAL;

    NSString *pattern = @"^\\s*(strong:|weak:)?\\s*(.+)";
    NSError *error = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern
                                        options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *match = [regexp firstMatchInString:param
                                        options:0 range:NSMakeRange(0, param.length)];
    if (match) {
        if ([match rangeAtIndex:1].length == 0) {
            attr = ATTR_MARKER_NORMAL;
        }
        else {
            NSString *matchCmd = [param substringWithRange:[match rangeAtIndex:1]];
            if ([matchCmd isEqual:@"strong:"]) {
                attr = ATTR_MARKER_STRONG;
            }
            else if ([matchCmd isEqual:@"weak:"]) {
                attr = ATTR_MARKER_WEAK;
            }
            else {
                attr = ATTR_MARKER_NORMAL;
            }
        }
        *line = [param substringWithRange:[match rangeAtIndex:2]];
    }

    return attr;
}

- (void)getCurrencyStart:(NSString *)param idxSub:(int)idxSub
{
    Reachability *reachablity = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reachablity currentReachabilityStatus];
    if (status == NotReachable) {
        // offline
        return;
    }

    NSString *pattern1 = @"^\\s*from:\\s*(.+)\\s+to:\\s*(.+)";
    NSError *error1 = nil;
    NSRegularExpression *regexp1 = [NSRegularExpression regularExpressionWithPattern:pattern1
                                        options:NSRegularExpressionCaseInsensitive error:&error1];
    NSTextCheckingResult *match1 = [regexp1 firstMatchInString:param
                                        options:0 range:NSMakeRange(0, param.length)];
    if (!match1) {
        return;
    }

    NSString *matchfrom = [param substringWithRange:[match1 rangeAtIndex:1]];
    NSString *matchto = [param substringWithRange:[match1 rangeAtIndex:2]];

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        NSMutableString *wk = [NSMutableString string];
        [wk setString:@"http://www.google.com/finance/converter?a=1&from="];
        [wk appendString:[matchfrom stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [wk appendString:@"&to="];
        [wk appendString:[matchto stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURL *url = [NSURL URLWithString:wk];

        NSURLRequest *req = [[NSURLRequest alloc] initWithURL:url
                                                  cachePolicy:NSURLRequestReloadIgnoringCacheData
                                              timeoutInterval:10.0];
        NSURLResponse *res = nil;
        NSError *error = nil;
        NSData *returnData = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&error];
        NSString *estr = [error localizedDescription];
        if ([estr length] > 0) {
            NSLog(@"Error: %@", estr);
            return;
        }
        NSString *str = [[NSString alloc] initWithData:returnData encoding:NSISOLatin1StringEncoding];

        NSString *pattern2 = @"<span class=bld>([0-9\\.]+).+</span>";
        NSError *error2 = nil;
        NSRegularExpression *regexp2 = [NSRegularExpression regularExpressionWithPattern:pattern2
                                            options:NSRegularExpressionCaseInsensitive error:&error2];
        NSTextCheckingResult *match2 = [regexp2 firstMatchInString:str
                                            options:0 range:NSMakeRange(0, str.length)];
        if (match2) {
            NSString *matchValue = [str substringWithRange:[match2 rangeAtIndex:1]];

            NSString *line = [childArray objectAtIndex:idxSub];
            NSString *newLine = [NSString stringWithFormat:@"%@ %@", line, matchValue];
            [childArray replaceObjectAtIndex:idxSub withObject:newLine];
            [childAttrArray replaceObjectAtIndex:idxSub withObject:[NSNumber numberWithInt:ATTR_CURRENCY]];
            NSLog(@"Response: %@", newLine);

            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idxSub inSection:0];
            dispatch_async(
                dispatch_get_main_queue(),
                ^{
                    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                          withRowAnimation:UITableViewRowAnimationNone];
                }
            );
        }
    }];
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
    int attr = [[childAttrArray objectAtIndex:indexPath.row] intValue];

    if (attr == ATTR_SEPARATOR) {
        cell.backgroundColor = [UIColor lightGrayColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [UIColor blackColor];
    }
    else {
        cell.backgroundColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;

        if (attr == ATTR_MARKER_NORMAL) {
            cell.textLabel.textColor = [UIColor blueColor];
        }
        else if (attr == ATTR_MARKER_STRONG) {
            cell.textLabel.textColor = [UIColor redColor];
        }
        else if (attr == ATTR_MARKER_WEAK) {
            cell.textLabel.textColor = [UIColor lightGrayColor];
        }
        else if (attr == ATTR_CURRENCY) {
            cell.textLabel.textColor = [UIColor brownColor];
        }
        else {
            cell.textLabel.textColor = [UIColor blackColor];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[childAttrArray objectAtIndex:indexPath.row] intValue] != ATTR_SEPARATOR) {
        [self childItemClick:indexPath isLongTap:NO];
    }
}

@end
