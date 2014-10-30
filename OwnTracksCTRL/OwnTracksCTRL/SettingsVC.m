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
@property (weak, nonatomic) IBOutlet UISwitch *UITLS;
@property (weak, nonatomic) IBOutlet UISwitch *UIAuth;
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
    
    [self updateValues];
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate saveContext];
}

- (IBAction)trash:(UIBarButtonItem *)sender {    
    [Vehicle trash];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Trash" message:@"successfull" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
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
    if (self.UITrackURL) delegate.broker.trackurl = self.UITrackURL.text;
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
    self.UITrackURL.text =                          delegate.broker.trackurl;
}

- (IBAction)versionChanged:(UITextField *)sender {
    if ([sender.text isEqualToString:[NSBundle mainBundle].infoDictionary[@"CFBundleVersion"]]) {
        self.UIHost.enabled = false;
        self.UIPort.enabled = false;
        self.UIUserID.enabled = false;
        self.UIPassword.enabled = false;
        self.UIClientID.enabled = false;
        self.UISubscription.enabled = false;
        self.UITrackURL.enabled = false;
        self.UITLS.enabled = false;
        self.UIAuth.enabled = false;
    } else {
        self.UIHost.enabled = true;
        self.UIPort.enabled = true;
        self.UIUserID.enabled = true;
        self.UIPassword.enabled = true;
        self.UIClientID.enabled = true;
        self.UISubscription.enabled = true;
        self.UITrackURL.enabled = true;
        self.UITLS.enabled = true;
        self.UIAuth.enabled = true;
    }
}

- (IBAction)touchedOutsideText:(UITapGestureRecognizer *)sender {
    [self.UIHost resignFirstResponder];
    [self.UIPort resignFirstResponder];
    [self.UIUserID resignFirstResponder];
    [self.UIPassword resignFirstResponder];
    [self.UIClientID resignFirstResponder];
    [self.UISubscription resignFirstResponder];
    [self.UITrackURL resignFirstResponder];
}

- (IBAction)clientIDChanged:(UITextField *)sender {
    
    if (sender.text.length < 1 || sender.text.length > 23) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"ClientID invalid"
                                  message:@"ClientID may not be empty and can be up to 23 characters long"
                                  delegate:self
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"OK", nil];
        [alertView show];
    } else {
        for (int i = 0; i < sender.text.length; i++) {
            if (![[NSCharacterSet alphanumericCharacterSet] characterIsMember:[sender.text characterAtIndex:i]]) {
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"ClientID invalid"
                                          message:@"ClientID may contain alphanumeric characters only"
                                          delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
                [alertView show];
                return;
            }
        }
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        delegate.broker.clientid = self.UIClientID.text;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.UIClientID.text = delegate.broker.clientid;
}


@end
