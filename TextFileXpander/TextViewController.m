//
//  TextViewController.m
//  TextFileXpander
//
//  Created by wanswings on 2014/10/15.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "TextViewController.h"
#import "PrivateUserDefaults.h"

static NSString *const DEFAULT_FONTSIZE = @"14";
static NSString *const FONT_SIZES[] = {@"10", @"12", @"14", @"16", @"18", @"20", @"22", @"24", @"26", @"28"};

static NSInteger const ACTIONSHEET_TAG_ACTION = 1;

@implementation TextViewController
{
@private
    NSString *SAVE_PREFS_NAME_TEXTVIEW;
    NSString *classNameForLog;
    NSArray *actionMenuItems;
    NSString *currentFontSize;
    NSString *ynHideMarker;
    PrivateUserDefaults *prefs;
    ActionViewController *dialog;
    PickerViewController *picker;
    UITextView *tv;
    CGFloat lastProportion;
}
@synthesize localFileName;

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    classNameForLog = [NSStringFromClass(self.class) stringByAppendingString:@"..."];
    NSLog(@"%@viewDidLoad", classNameForLog);
    // for iOS7
    self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *rPath = [bundle pathForResource:@"PrivateUserDefaults" ofType:@"plist"];
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:rPath];
    SAVE_PREFS_NAME_TEXTVIEW = [dic objectForKey:@"SAVE_PREFS_NAME_TEXTVIEW"];

    prefs = [[PrivateUserDefaults alloc] init:SAVE_PREFS_NAME_TEXTVIEW];

    [self loadKeys];
    [self setActionMenuItems];

    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"\u2699"
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                   action:@selector(selectActionMenu:)];
    UIFont *font = [UIFont systemFontOfSize:24.0f];
    [menuButton setTitleTextAttributes:@{NSFontAttributeName:font} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = menuButton;

    tv = [[UITextView alloc] init];
    tv.editable = NO;
    tv.layoutManager.allowsNonContiguousLayout = NO;
    [self setFrameSize];
    [self.view addSubview:tv];

    if (localFileName == nil) {
        self.title = NSLocalizedString(@"title_activity_text", nil);
    }
    else {
        NSLog(@"%@viewDidLoad...localFileName...%@", classNameForLog, localFileName);
        self.title = localFileName;
        [self viewTextData:localFileName];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    NSLog(@"%@viewWillDisappear", classNameForLog);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"%@viewWillAppear", classNameForLog);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

- (void)changeNotification:(NSNotification *)aNotification
{
    NSLog(@"%@changeNotification", classNameForLog);
    lastProportion = tv.contentOffset.y / tv.contentSize.height;
    [self setFrameSize];
    [self setContentOffset];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setFrameSize
{
    CGRect screen = [[UIScreen mainScreen] bounds];
    CGFloat viewHeight = screen.size.height;
    CGFloat viewWidth = screen.size.width;
    CGFloat top = 44.0f + 20.0f;

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        if ( [[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
            viewHeight = screen.size.width;
            viewWidth = screen.size.height;
        }
        top = 32.0f + 20.0f;
    }

    if ( [[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
        tv.frame = CGRectMake(0, top, viewWidth, viewHeight - top);
    }
    else {
        tv.frame = CGRectMake(0, 0, viewWidth, viewHeight);
    }
}

- (void)setContentOffset
{
    CGRect screen = [[UIScreen mainScreen] bounds];
    CGFloat viewHeight = screen.size.height;
    CGFloat viewWidth = screen.size.width;

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        if ( [[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
            viewHeight = screen.size.width;
            viewWidth = screen.size.height;
        }
    }
    CGSize size = [tv sizeThatFits:CGSizeMake(viewWidth, FLT_MAX)];
    NSLog(@"%@setContentOffset...%f...%f...%f", classNameForLog, tv.contentOffset.y, tv.contentSize.height, size.height);
    tv.contentOffset = CGPointMake(0, lastProportion * size.height);
}

- (void)setActionMenuItems
{
    NSString *markerMenuName;
    if ([ynHideMarker isEqualToString:@"YES"]) {
        markerMenuName = NSLocalizedString(@"action_show_marker", nil);
    }
    else {
        markerMenuName = NSLocalizedString(@"action_hide_marker", nil);
    }
    actionMenuItems = @[
                        NSLocalizedString(@"action_font_size", nil),
                        markerMenuName,
                        ];
}

- (void)selectedActionData:(NSString *)selectedName tag:(int)tag
{
    NSLog(@"%@selectedActionData...%@", classNameForLog, selectedName);

    if (tag == ACTIONSHEET_TAG_ACTION) {
        // from selectActionMenu
        NSString *selected = selectedName;

        if ([selected isEqualToString:NSLocalizedString(@"action_font_size", nil)]) {
            [self selectFontSize];
        }
        else if ([selected isEqualToString:NSLocalizedString(@"action_hide_marker", nil)]) {
            ynHideMarker = @"YES";
            [self saveKeys:@"" marker:ynHideMarker];
            [self setActionMenuItems];
            [self viewTextData:localFileName];
        }
        else if ([selected isEqualToString:NSLocalizedString(@"action_show_marker", nil)]) {
            ynHideMarker = @"NO";
            [self saveKeys:@"" marker:ynHideMarker];
            [self setActionMenuItems];
            [self viewTextData:localFileName];
        }
    }
}

- (void)selectActionMenu:(UIBarButtonItem *)button
{
    dialog = [[ActionViewController alloc]
              initWithParent:self
              delegate:self
              buttonData:actionMenuItems
              title:NSLocalizedString(@"dialog_title_select_action", nil)
              selected:nil
              tag:ACTIONSHEET_TAG_ACTION];
}

- (void)selectFontSize
{
    NSMutableArray *fontMenuItems = [NSMutableArray array];
    for (int i = 0; i < sizeof(FONT_SIZES) / sizeof(FONT_SIZES[0]); i++) {
        [fontMenuItems addObject:FONT_SIZES[i]];
    }

    picker = [[PickerViewController alloc]
              initWithParent:self
              delegate:self
              pickerData:fontMenuItems
              title:NSLocalizedString(@"dialog_title_font_size", nil)
              selected:currentFontSize];
}

- (void)selectedPickerData:(NSString *)selectedName
{
    NSLog(@"%@selectedPickerData...%@", classNameForLog, selectedName);

    currentFontSize = selectedName;
    [self saveKeys:currentFontSize marker:@""];

    lastProportion = tv.contentOffset.y / tv.contentSize.height;
    [self viewTextData:localFileName];
    [self setContentOffset];
}

- (void)cancelPicker
{
    NSLog(@"%@cancelPicker", classNameForLog);
}

- (void)loadKeys
{
    NSArray *keys = [prefs getKeys:prefs->SAVE_KEYS_TEXTVIEW];
    if (keys != nil) {
        currentFontSize = keys[0];
        ynHideMarker = keys[1];
        NSLog(@"%@loadKeys...%@ %@", classNameForLog, currentFontSize, ynHideMarker);
    }
    else {
        currentFontSize = DEFAULT_FONTSIZE;
        ynHideMarker = @"NO";
        [self saveKeys:currentFontSize marker:ynHideMarker];
    }
}

- (void)saveKeys:strFontSize marker:strHideMarker
{
    NSArray *values = [NSArray arrayWithObjects:strFontSize, strHideMarker, nil];
    [prefs storeKeys:prefs->SAVE_KEYS_TEXTVIEW values:values];
}

- (void)viewTextData:(NSString *)fname
{
    NSLog(@"%@viewTextData", classNameForLog);

    if (fname == nil) {
        tv.text = @"No Data";
        return;
    }

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dstDir = [paths objectAtIndex:0];
    NSString *fullPath = [dstDir stringByAppendingPathComponent:fname];
    NSError *error = nil;
    NSString *fdata = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        NSMutableAttributedString *mAttrStr = [[NSMutableAttributedString alloc] init];

        NSString *pattern = @"^marker:(strong:|weak:)?\\s*(.+)";
        NSRegularExpression *regexp = [NSRegularExpression
                                       regularExpressionWithPattern:pattern
                                       options:NSRegularExpressionCaseInsensitive
                                       error:&error];

        [fdata enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            UIColor *fg = nil;
            UIColor *bg = nil;
            if (line.length > 0) {
                @autoreleasepool {
                    NSTextCheckingResult *match =
                            [regexp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
                    if (match) {
                        if ([ynHideMarker isEqualToString:@"YES"]) {
                            bg = [UIColor blackColor];
                        }
                        else if ([match rangeAtIndex:1].length == 0) {
                            fg = [UIColor blueColor];
                        }
                        else {
                            NSString *matchCmd = [line substringWithRange:[match rangeAtIndex:1]];
                            if ([matchCmd isEqual:@"strong:"]) {
                                fg = [UIColor redColor];
                            }
                            else if ([matchCmd isEqual:@"weak:"]) {
                                fg = [UIColor lightGrayColor];
                            }
                            else {
                                fg = [UIColor blueColor];
                            }
                        }
                        line = [line substringWithRange:[match rangeAtIndex:2]];
                    }
                }
            }
            if (fg == nil) {
                fg = [UIColor blackColor];
            }
            if (bg == nil) {
                bg = [UIColor whiteColor];
            }
            UIFont *font = [UIFont systemFontOfSize:[currentFontSize floatValue]];
            NSAttributedString *attrStr = [[NSAttributedString alloc]
                                           initWithString:[NSString stringWithFormat:@"%@\n", line]
                                               attributes:@{NSFontAttributeName:font,
                                                            NSBackgroundColorAttributeName:bg,
                                                            NSForegroundColorAttributeName:fg}];
            [mAttrStr appendAttributedString:attrStr];
        }];

        tv.attributedText = mAttrStr;
    }
}

@end
