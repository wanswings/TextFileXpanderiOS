//
//  MainTableViewController.m
//  TextFileXpander
//
//  Created by wanswings on 2014/09/03.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "MainTableViewController.h"
#import "AppDelegate.h"
#import "GoogleAuthViewController.h"
#import "PrivateUserDefaults.h"
#import "SimpleToast.h"

static NSString *const EXTRA_FROM_MAIN = @"fromMain";
static NSString *const EXTRA_PARAM_MAIN = @"paramMain";

static NSString *const VIEW_TYPE_STD = @"Standard View";
static NSString *const VIEW_TYPE_EXP = @"Expandable View";
static NSString *const STORAGE_NAMES[] = {@"Dropbox", @"Google Drive", @"Local"};
static NSString *const STORAGE_CLASSES[] = {@"Dropbox", @"GoogleDrive", @"DocumentsStorage"};

static NSInteger const ACTIONSHEET_TAG_ACTION = 1;
static NSInteger const ACTIONSHEET_TAG_VIEWTYPE = 2;
static NSInteger const ACTIONSHEET_TAG_RESET = 3;
static NSInteger const ACTIONSHEET_TAG_STORAGE = 4;

@implementation MainTableViewController
{
    @private
    NSString *SAVE_PREFS_NAME_MAIN;
    NSString *classNameForLog;
    NSArray *actionMenuItems;
    NSArray *viewTypeMenuItems;
    NSArray *resetMenuItems;
    id storage;
	NSString *currentStorage;
	long selectedStorageIdx;
	NSString *currentViewType;
    NSString *ynNotification;
    PrivateUserDefaults *prefs;
    SimpleToast *toast;
    ActionViewController *dialog;
    BOOL firstTime;
    GoogleAuthViewController *controller;
}
@synthesize groupArray;
@synthesize interactionController;

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
    NSLog(@"%@viewDidLoad", classNameForLog);
    // for iOS7
    self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;

    actionMenuItems = @[
                        NSLocalizedString(@"action_load_data", nil),
                        NSLocalizedString(@"action_refresh", nil),
//                        NSLocalizedString(@"action_view_type", nil),
                        NSLocalizedString(@"action_reset", nil),
                        ];
    viewTypeMenuItems = @[
                          VIEW_TYPE_STD,
                          VIEW_TYPE_EXP,
                          ];
    resetMenuItems = @[
                       NSLocalizedString(@"dialog_title_reset", nil),
                       ];
    groupArray = [NSMutableArray array];

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *rPath = [bundle pathForResource:@"PrivateUserDefaults" ofType:@"plist"];
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:rPath];
    SAVE_PREFS_NAME_MAIN = [dic objectForKey:@"SAVE_PREFS_NAME_MAIN"];

    prefs = [[PrivateUserDefaults alloc] init:SAVE_PREFS_NAME_MAIN];

    [self loadKeys];
    NSString *title = NSLocalizedString(@"title_activity_main", nil);
    if ([currentStorage isEqualToString:@""]) {
        self.title = title;
    }
    else {
        self.title = [NSString stringWithFormat:@"%@ [%@]", title, currentStorage];
    }

    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"\u2699"
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                   action:@selector(selectActionMenu:)];
    UIFont *font = [UIFont systemFontOfSize:24.0f];
    [menuButton setTitleTextAttributes:@{NSFontAttributeName:font} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = menuButton;

    UILongPressGestureRecognizer *longPressGesture =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(groupItemLongClick:)];
    longPressGesture.minimumPressDuration = 1.0;
    [self.view addGestureRecognizer:longPressGesture];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dstDir = [paths objectAtIndex:0];
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirs = [fileManager contentsOfDirectoryAtPath:dstDir error:&error];

    firstTime = YES;
    if ([dirs count] > 0) {
        [self refreshLocalData];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSLog(@"%@viewDidAppear", classNameForLog);

    if (firstTime && groupArray.count == 0) {
        [self selectStorage];
    }
    firstTime = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)selectedActionData:(NSString *)selectedName tag:(int)tag
{
    NSLog(@"%@selectedActionData...%@", classNameForLog, selectedName);

    if (tag == ACTIONSHEET_TAG_ACTION) {
        // from selectActionMenu
        NSString *selected = selectedName;

        if ([selected isEqualToString:NSLocalizedString(@"action_load_data", nil)]) {
            [self selectStorage];
        }
        else if ([selected isEqualToString:NSLocalizedString(@"action_refresh", nil)]) {
            [self refresh];
        }
        else if ([selected isEqualToString:NSLocalizedString(@"action_view_type", nil)]) {
            [self selectViewType];
        }
        else if ([selected isEqualToString:NSLocalizedString(@"action_reset", nil)]) {
            [self reset];
        }
    }
    else if (tag == ACTIONSHEET_TAG_VIEWTYPE) {
        // from selectViewType
        currentViewType = selectedName;

        [self saveKeys:currentViewType notification:@"" storage:@""];

        if (groupArray.count > 0) {
            [self refreshLocalData];
        }
    }
    else if (tag == ACTIONSHEET_TAG_RESET) {
        // from reset
        NSLog(@"%@reset start", classNameForLog);
        // delete private files
        [Storage deleteLocalFiles];
        [prefs clearAllKeys];
        [self loadKeys];
        self.title = NSLocalizedString(@"title_activity_main", nil);
        [groupArray removeAllObjects];

        toast = [[SimpleToast alloc] initWithParams:self.view
                                            message:NSLocalizedString(@"toast_finished_reset", nil)
                                               time:2.0f];
        [self.tableView reloadData];
    }
    else if (tag == ACTIONSHEET_TAG_STORAGE) {
        // from selectStorage
        currentStorage = selectedName;

        for (int idx = 0; idx < sizeof(STORAGE_NAMES) / sizeof(STORAGE_NAMES[0]); idx++) {
            if ([currentStorage isEqualToString:STORAGE_NAMES[idx]]) {
                selectedStorageIdx = idx;
                break;
            }
        }

        Class storageClass = NSClassFromString(STORAGE_CLASSES[selectedStorageIdx]);
        if (storageClass == nil) {
            NSLog(@"%@selectStorage...%@ newInstance error", classNameForLog, STORAGE_CLASSES[selectedStorageIdx]);
        }
        else {
            storage = [[storageClass alloc] initWithView:self refresh:NO];
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

- (void)readyToStartDropboxAuthActivity
{
    NSLog(@"%@readyToStartDropboxAuthActivity", classNameForLog);
    if (![[DBSession sharedSession] isLinked]) {
        [[NSNotificationCenter defaultCenter]
                     addObserver:self
                     selector:@selector(finishDropboxAuthentication:)
                     name:@"finishDropboxAuthentication"
                     object:nil];

        [[DBSession sharedSession] linkFromController:self];
        return;
    }

    [self notRreadyToUseDropbox];
}

- (void)finishDropboxAuthentication:(NSNotification *)notification
{
    NSLog(@"%@finishDropboxAuthentication", classNameForLog);
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    BOOL isReady = [(NSNumber *)[notification object] boolValue];
    if (isReady) {
        [self readyToUseDropbox];
    }
    else {
        [self notRreadyToUseDropbox];
    }
}

- (void)readyToUseDropbox
{
    NSLog(@"%@readyToUseDropbox", classNameForLog);

    if (storage != nil) {
        NSString *mName = @"selectDir";

        SEL method = NSSelectorFromString(mName);
        if ([storage respondsToSelector:method]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [storage performSelector:method];
#pragma clang diagnostic pop
        }
        else {
            NSLog(@"%@readyToUseDropbox...%@ error", classNameForLog, mName);
        }
    }
}

- (void)notRreadyToUseDropbox
{
    NSLog(@"%@notRreadyToUseDropbox", classNameForLog);
    [self closeStorage];
    [self loadKeys];
}

- (void)readyToStartGoogleAuthActivity
{
    NSLog(@"%@readyToStartGoogleAuthActivity", classNameForLog);

    controller = [[GoogleAuthViewController alloc] initWithParent:self];

    [[NSNotificationCenter defaultCenter]
                 addObserver:self
                 selector:@selector(finishGoogleAuthentication:)
                 name:@"finishGoogleAuthentication"
                 object:nil];
}

- (void)finishGoogleAuthentication:(NSNotification *)notification
{
    NSLog(@"%@finishGoogleAuthentication", classNameForLog);
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    BOOL isReady = [(NSNumber *)[notification object] boolValue];
    if (isReady) {
        [self readyToUseGoogle];
    }
    else {
        [self notRreadyToUseGoogle];
    }
}

- (void)readyToUseGoogle
{
    NSLog(@"%@readyToUseGoogle", classNameForLog);

    if (storage != nil) {
        NSString *mName = @"selectDir";

        SEL method = NSSelectorFromString(mName);
        if ([storage respondsToSelector:method]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [storage performSelector:method];
#pragma clang diagnostic pop
        }
        else {
            NSLog(@"%@readyToUseGoogle...%@ error", classNameForLog, mName);
        }
    }
}

- (void)notRreadyToUseGoogle
{
    NSLog(@"%@notRreadyToUseGoogle", classNameForLog);
    [self closeStorage];
    [self loadKeys];
}

- (void)readyToReadPrivateFiles
{
    NSLog(@"%@readyToReadPrivateFiles...%@", classNameForLog, currentStorage);
    [self closeStorage];
    [self saveKeys:@"" notification:@"" storage:currentStorage];
    self.title = [NSString stringWithFormat:@"%@ [%@]", NSLocalizedString(@"title_activity_main", nil), currentStorage];
    [self refreshLocalData];
}

- (void)cancelSelectDirDialog
{
    NSLog(@"%@cancelSelectDirDialog", classNameForLog);
    [self closeStorage];
    [self loadKeys];
}

- (void)fromSubTableViewClick:(NSString *)result
{
    NSLog(@"%@fromSubTableViewClick...%@", classNameForLog, result);
    [self pushData:result];
}

- (void)loadKeys
{
    NSArray *keys = [prefs getKeys:prefs->SAVE_KEYS_MAIN];
    if (keys != nil) {
        currentViewType = keys[0];
        ynNotification = keys[1];
        currentStorage = keys[2];
        NSLog(@"%@loadKeys...%@ %@ %@", classNameForLog, currentViewType, ynNotification, currentStorage);
    }
    else {
        currentViewType = VIEW_TYPE_STD;
        ynNotification = @"NO";
        currentStorage = @"";
        [self saveKeys:currentViewType notification:ynNotification storage:currentStorage];
    }
}

- (void)saveKeys:strViewType notification:strNotification storage:strStorage
{
    NSArray *values = [NSArray arrayWithObjects:strViewType, strNotification, strStorage, nil];
    [prefs storeKeys:prefs->SAVE_KEYS_MAIN values:values];
}

- (void)selectViewType
{
    dialog = [[ActionViewController alloc]
              initWithParent:self
              delegate:self
              buttonData:viewTypeMenuItems
              title:NSLocalizedString(@"dialog_title_select_view_type", nil)
              selected:currentViewType
              tag:ACTIONSHEET_TAG_VIEWTYPE];
}

- (void)reset
{
    dialog = [[ActionViewController alloc]
              initWithParent:self
              delegate:self
              buttonData:resetMenuItems
              title:NSLocalizedString(@"dialog_message_reset", nil)
              selected:nil
              tag:ACTIONSHEET_TAG_RESET];
}

- (void)closeStorage
{
    NSLog(@"%@closeStorage", classNameForLog);

    if (storage != nil) {
        NSString *mName = @"close";

        SEL method = NSSelectorFromString(mName);
        if ([storage respondsToSelector:method]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [storage performSelector:method];
#pragma clang diagnostic pop
        }
        else {
            NSLog(@"%@closeStorage...%@ error", classNameForLog, mName);
        }
        storage = nil;
    }
}

- (void)refresh
{
    selectedStorageIdx = -1;

    for (int i = 0; i < sizeof(STORAGE_NAMES) / sizeof(STORAGE_NAMES[0]); i++) {
        if ([currentStorage isEqualToString:STORAGE_NAMES[i]]) {
            selectedStorageIdx = i;
            break;
        }
    }

    if (selectedStorageIdx == -1) {
        return;
    }

    Class storageClass = NSClassFromString(STORAGE_CLASSES[selectedStorageIdx]);
    if (storageClass == nil) {
        NSLog(@"%@refresh...%@ newInstance error", classNameForLog, STORAGE_CLASSES[selectedStorageIdx]);
        return;
    }

    storage = [[storageClass alloc] initWithView:self refresh:YES];
}

- (void)selectStorage
{
    NSMutableArray *storageMenuItems = [NSMutableArray array];
    for (int i = 0; i < sizeof(STORAGE_NAMES) / sizeof(STORAGE_NAMES[0]); i++) {
        [storageMenuItems addObject:STORAGE_NAMES[i]];
    }

    dialog = [[ActionViewController alloc]
              initWithParent:self
              delegate:self
              buttonData:storageMenuItems
              title:NSLocalizedString(@"dialog_title_select_storage", nil)
              selected:currentStorage
              tag:ACTIONSHEET_TAG_STORAGE];
}

- (void)pushData:(NSString *)str
{
    // To Pasteboard
    UIPasteboard *pboard = [UIPasteboard generalPasteboard];
    [pboard setValue:str forPasteboardType:@"public.text"];

    NSLog(@"%@pushData...To Pasteboard...%@", classNameForLog, str);
    toast = [[SimpleToast alloc] initWithParams:self.view
                                        message:NSLocalizedString(@"toast_copied_clipboard", nil)
                                           time:2.0f];
}

- (void)refreshLocalData
{
    if ([currentViewType isEqualToString:VIEW_TYPE_EXP]) {
        [self refreshLocalData4ExpandableListView];
    }
    else {
        [self refreshLocalData4ListView];
    }
}

- (void)refreshLocalData4ExpandableListView
{

}

- (void)refreshLocalData4ListView
{
    NSLog(@"%@refreshLocalData4ListView", classNameForLog);

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dstDir = [paths objectAtIndex:0];
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSArray *dirs = [[fileManager contentsOfDirectoryAtPath:dstDir error:&error]
                     sortedArrayUsingSelector:@selector(compare:)];

    [groupArray removeAllObjects];
    BOOL isDirectory;
    for (NSString *fname in dirs) {
        NSString *fPath = [dstDir stringByAppendingPathComponent:fname];
        if ([fileManager fileExistsAtPath:fPath isDirectory: &isDirectory] && isDirectory) {
        }
        else {
            [groupArray addObject:fname];
        }
    }

    [self.tableView reloadData];
}

- (void)groupItemLongClick:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint p = [sender locationInView:self.tableView];
        NSIndexPath *idx = [self.tableView indexPathForRowAtPoint:p];
        NSString *fname = [self.tableView cellForRowAtIndexPath:idx].textLabel.text;

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *dstDir = [paths objectAtIndex:0];
        NSString *fPath = [dstDir stringByAppendingPathComponent:fname];
        [self launchWithFile:fPath];
    }
}

- (void)launchWithFile:(NSString *)fullPath
{
    NSLog(@"%@launchWithFile...%@", classNameForLog, fullPath);

    interactionController = [UIDocumentInteractionController
                             interactionControllerWithURL:[NSURL fileURLWithPath:fullPath]];
    interactionController.delegate = self;
    BOOL isValid = [interactionController
                    presentOpenInMenuFromRect:self.view.frame
                    inView:self.view animated:YES];
    if (!isValid) {
        NSLog(@"%@launchWithFile...error", classNameForLog);
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSLog(@"%@tableView numberOfRowsInSection...%ld", classNameForLog, (unsigned long)groupArray.count);
    return groupArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GroupCell";
    UITableViewCell *cellView = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    // Configure the cell...
    if (cellView == nil) {
        cellView = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GroupCell"];
    }
    cellView.textLabel.text = [groupArray objectAtIndex:indexPath.row];

    return cellView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"toSub" sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"toSub"]) {
        SubTableViewController *nvc = (SubTableViewController *)[segue destinationViewController];
        nvc.localFileName = groupArray[[self.tableView indexPathForSelectedRow].row];
        NSLog(@"%@prepareForSegue...%@", classNameForLog, nvc.localFileName);
    }
}

@end
