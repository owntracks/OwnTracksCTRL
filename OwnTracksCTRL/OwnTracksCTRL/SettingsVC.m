//
//  OPStatusViewController.m
//  OwnPager
//
//  Created by Christoph Krey on 29.05.14.
//  Copyright (c) 2014 christophkrey. All rights reserved.
//

#import "SettingsVC.h"
#import "AppDelegate.h"

@interface SettingsVC ()
@property (weak, nonatomic) IBOutlet UITextField *UIHost;
@property (weak, nonatomic) IBOutlet UITextField *UIPort;
@property (weak, nonatomic) IBOutlet UISwitch *UITLS;
@property (weak, nonatomic) IBOutlet UISwitch *UIAuth;
@property (weak, nonatomic) IBOutlet UITextField *UIUserID;
@property (weak, nonatomic) IBOutlet UITextField *UIPassword;
@property (weak, nonatomic) IBOutlet UITextField *UIClientID;
@property (weak, nonatomic) IBOutlet UITextField *UIVersion;
@property (weak, nonatomic) IBOutlet UITextField *UISubscription;

@end

@implementation SettingsVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self updateValues];
}

- (void)updateValues
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

    if (self.UIHost) delegate.broker.host = self.UIHost.text;
    if (self.UIPort) delegate.broker.port = @([self.UIPort.text intValue]);
    if (self.UITLS) delegate.broker.tls = @(self.UITLS.on);
    if (self.UIAuth) delegate.broker.auth = @(self.UIAuth.on);
    if (self.UIUserID) delegate.broker.user = self.UIUserID.text;
    if (self.UIPassword) delegate.broker.passwd = self.UIPassword.text;
    if (self.UIClientID) delegate.broker.clientid = self.UIClientID.text;
    if (self.UISubscription) delegate.broker.base = self.UISubscription.text;
}

- (void)updated
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

    self.UIVersion.text =                           [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];
    
    self.UIHost.text =                              delegate.broker.host;
    self.UIPort.text =                              [delegate.broker.port stringValue];
    self.UITLS.on =                                 [delegate.broker.tls boolValue];
    self.UIAuth.on =                                [delegate.broker.auth boolValue];
    self.UIUserID.text =                            delegate.broker.user;
    self.UIPassword.text =                          delegate.broker.passwd;
    self.UIClientID.text =                          delegate.broker.clientid;
    self.UISubscription.text =                      delegate.broker.base;
}


- (IBAction)touchedOutsideText:(UITapGestureRecognizer *)sender {
    [self.UIHost resignFirstResponder];
    [self.UIPort resignFirstResponder];
    [self.UIUserID resignFirstResponder];
    [self.UIPassword resignFirstResponder];
    [self.UIClientID resignFirstResponder];
    [self.UISubscription resignFirstResponder];
}

@end
