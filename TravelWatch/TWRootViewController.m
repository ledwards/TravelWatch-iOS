//
//  TWRootViewController.m
//  TravelWatch
//
//  Created by Lee Edwards on 1/25/15.
//  Copyright (c) 2015 Lee Edwards. All rights reserved.
//

#import "TWRootViewController.h"

@interface TWRootViewController () <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSOperationQueue *queue;
@property(nonatomic, strong) NSArray *items;

@end

@implementation TWRootViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
        [_queue setMaxConcurrentOperationCount:1];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    UIView *view = self.view;
    _tableView = [[UITableView alloc] init];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    view.backgroundColor = [UIColor whiteColor];
    [view addSubview: _tableView];
    
    UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(logoutButtonClicked:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = logoutButton;
    logoutButton.enabled=TRUE;
    logoutButton.style=UIBarButtonSystemItemRefresh;
    
    // should hide Back button so only Logout Button takes you back to Login controller
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *savedEmail = [prefs stringForKey:@"userEmail"];
    NSString *savedToken = [prefs stringForKey:@"userToken"];
    
    NSURL *url = [NSURL URLWithString:@"http://travelwatch-test.herokuapp.com/api/trips"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [mutableRequest addValue:savedEmail forHTTPHeaderField:@"X-User-Email"];
    [mutableRequest addValue:savedToken forHTTPHeaderField:@"X-User-Token"];
    request = [mutableRequest copy];
    
    __weak TWRootViewController *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError || data == nil) {
            return;
        }
        NSError *error = nil;
        NSArray *items = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.items = items;
            [weakSelf.tableView reloadData];
        });
    }];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _tableView.frame = CGRectMake(self.view.bounds.origin.x, 0.0, self.view.bounds.size.width, self.view.bounds.size.height);
}

#pragma mark- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = _items[indexPath.row][@"flight_plans"][0][@"start_at"];
    return cell;
}

#pragma mark- UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.title = @"Detail View";
    vc.view.backgroundColor = [UIColor redColor];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark- UIButtonHandler

- (void)logoutButtonClicked:(UIButton*)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs removeObjectForKey:@"userEmail"];
    [prefs removeObjectForKey:@"userToken"];
    [prefs synchronize];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end