//
//  TWLoginViewController.m
//  TravelWatch
//
//  Created by Lee Edwards on 1/27/15.
//  Copyright (c) 2015 Lee Edwards. All rights reserved.
//

#import "TWLoginViewController.h"
#import "TWRootViewController.h"

@interface TWLoginViewController () <UITextFieldDelegate>

@property(nonatomic, strong) NSOperationQueue *queue;
@property(nonatomic, strong) UITextField *emailField;
@property(nonatomic, strong) UITextField *passwordField;

@end

@implementation TWLoginViewController

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
    view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidLoad {
    _emailField = [[UITextField alloc] initWithFrame:CGRectMake(20.0, 100.0, 180.0, 20.0)];
    _emailField.borderStyle = UITextBorderStyleRoundedRect;
    _emailField.placeholder = @"Email";
    _emailField.delegate = self;

    _passwordField = [[UITextField alloc] initWithFrame:CGRectMake(20.0, 140.0, 180.0, 20.0)];
    _passwordField.borderStyle = UITextBorderStyleRoundedRect;
    _passwordField.placeholder = @"Password";
    _passwordField.delegate = self;
    
    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    loginButton.frame = CGRectMake(20.0, 180.0, 100.0, 20.0);
    [loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [loginButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_emailField];
    [self.view addSubview:_passwordField];
    [self.view addSubview:loginButton];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *savedEmail = [prefs stringForKey:@"userEmail"];
    NSString *savedToken = [prefs stringForKey:@"userToken"];
    TWRootViewController *rootController = [[TWRootViewController alloc] init];
    if (savedEmail && savedToken) {
        [self.navigationController pushViewController:rootController animated:YES];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

#pragma mark- UITextFieldDelegate

#pragma mark- UIButtonHandler

- (void) buttonClicked:(UIButton*)sender {
    [sender setTitle:@"Logging in..." forState:UIControlStateNormal];
    
    NSURL *url = [NSURL URLWithString:@"http://travelwatch-test.herokuapp.com/users/sign_in.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
//    NSString *postBody = @"{\"user\": {\"email\": \"leeredwards@gmail.com\", \"password\": \"password\"}}";
    NSArray *requestBodyComponents = @[@"{\"user\": {\"email\": \"", _emailField.text, @"\", \"password\": \"", _passwordField.text, @"\"}}" ];
    NSString *postBody = [requestBodyComponents componentsJoinedByString: @""];
    [request setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    __weak TWLoginViewController *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError || data == nil) {
            [sender setTitle:@"Error!" forState:UIControlStateNormal];
            return;
        }
        NSError *error = nil;
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [sender setTitle:@"Yay!" forState:UIControlStateNormal];
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject: responseObject[@"email"] forKey:@"userEmail"];
            [prefs setObject: responseObject[@"authentication_token"] forKey:@"userToken"];
            [prefs synchronize];
            
            TWRootViewController *rootController = [[TWRootViewController alloc] init];
            [weakSelf.navigationController pushViewController:rootController animated:YES];
        });
    }];
}

@end
