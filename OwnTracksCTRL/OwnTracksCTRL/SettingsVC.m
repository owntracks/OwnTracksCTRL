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
@property (strong, nonatomic) NSURLConnection *urlConnection;
@property (strong, nonatomic) NSMutableData *receivedData;

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
- (IBAction)lookup:(UIButton *)sender {
    [self updateValues];
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSString *post = [NSString stringWithFormat:@"username=%@&password=%@",
                      delegate.broker.user,
                      delegate.broker.passwd];
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://roo.jpmens.net/ctrl/conf.php"]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    self.receivedData = [[NSMutableData alloc] init];
    self.urlConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"NSURLResponse %@", response);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Loading" message:@"failed" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSDictionary *dictionary = nil;
    if (self.receivedData.length) {
        NSError *error;
        dictionary = [NSJSONSerialization JSONObjectWithData:self.receivedData options:0 error:&error];
    }
    if (dictionary) {
        if ([dictionary[@"_type"] isEqualToString:@"configuration"]) {
            AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            
            delegate.broker.host = dictionary[@"host"];
            delegate.broker.port = dictionary[@"port"];
            delegate.broker.auth = dictionary[@"auth"];
            delegate.broker.tls = dictionary[@"tls"];
            delegate.broker.user = dictionary[@"username"];
            delegate.broker.passwd = dictionary[@"password"];
            delegate.broker.base = dictionary[@"subTopic"];
            delegate.broker.clientid = dictionary[@"clientid"];
            [self updated];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Settings" message:@"loaded" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Settings" message:@"no configuration" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            
        }
        
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Settings" message:@"invalid" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
}


- (IBAction)trash:(UIButton *)sender {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSArray *vehicles = [Vehicle allVehiclesInManagedObjectContext:delegate.managedObjectContext];
    for (Vehicle *vehicle in vehicles) {
        [delegate.managedObjectContext deleteObject:vehicle];
    }
    [delegate saveContext];
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
