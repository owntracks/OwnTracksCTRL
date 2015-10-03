//
//  OPStatusViewController.m
//  OwnPager
//
//  Created by Christoph Krey on 29.05.14.
//  Copyright (c) 2014 christophkrey. All rights reserved.
//

#import "SettingsVC.h"
#import "AppDelegate.h"
#import "Vehicle+Create.h"

@interface SettingsVC ()
@property (weak, nonatomic) IBOutlet UITextField *UIHost;
@property (weak, nonatomic) IBOutlet UITextField *UIPort;
#ifndef CTRLTV
@property (weak, nonatomic) IBOutlet UISwitch *UITLS;
@property (weak, nonatomic) IBOutlet UISwitch *UIAuth;
#else
@property (weak, nonatomic) IBOutlet UIButton *UITLS;
@property (weak, nonatomic) IBOutlet UIButton *UIAuth;
#endif
@property (weak, nonatomic) IBOutlet UITextField *UIUserID;
@property (weak, nonatomic) IBOutlet UITextField *UIPassword;
@property (weak, nonatomic) IBOutlet UITextField *UIClientID;
@property (weak, nonatomic) IBOutlet UITextField *UIVersion;
@property (weak, nonatomic) IBOutlet UITextField *UISubscription;
@property (weak, nonatomic) IBOutlet UITextField *UITrackURL;

@end

@implementation SettingsVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updated];
    [self.navigationController.navigationBar setHidden:false];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)updated
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.UIVersion.text =                           [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];
    
    self.UIHost.text =                              delegate.broker.host;
    self.UIPort.text =                              [delegate.broker.port stringValue];
#ifndef CTRLTV
    self.UITLS.on =                                 [delegate.broker.tls boolValue];
    self.UIAuth.on =                                [delegate.broker.auth boolValue];
#else
    self.UITLS.tintColor =                          [delegate.broker.tls boolValue] ? [UIColor redColor] : [UIColor whiteColor];
    self.UIAuth.tintColor =                         [delegate.broker.auth boolValue] ? [UIColor redColor] : [UIColor whiteColor];
#endif
    self.UIUserID.text =                            delegate.broker.user;
    self.UIPassword.text =                          delegate.broker.passwd;
    self.UIClientID.text =                          delegate.broker.clientid;
    self.UISubscription.text =                      delegate.broker.base;
    self.UITrackURL.text =                          delegate.broker.trackurl;
}

@end
