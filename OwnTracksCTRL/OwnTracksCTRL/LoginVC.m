//
//  LoginViewController.m
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 24.10.14.
//  Copyright (c) 2014 OwnTracks. All rights reserved.
//

#import "LoginVC.h"
#import "AppDelegate.h"

@interface LoginVC ()
@property (weak, nonatomic) IBOutlet UITextField *UIuser;
@property (weak, nonatomic) IBOutlet UITextField *UIpassword;

@property (strong, nonatomic) NSURLConnection *urlConnection;
@property (strong, nonatomic) NSMutableData *receivedData;

@end

@implementation LoginVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self updateValues];
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate saveContext];
}

- (void)updateValues
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    if (self.UIuser) delegate.broker.user = self.UIuser.text;
    if (self.UIpassword) delegate.broker.passwd = self.UIpassword.text;
}

- (void)updated
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.UIuser.text = delegate.broker.user;
    self.UIpassword.text = delegate.broker.passwd;
}


- (IBAction)touchedOutsideText:(UITapGestureRecognizer *)sender {
    [self.UIuser resignFirstResponder];
    [self.UIpassword resignFirstResponder];
}



- (IBAction)lookup:(UIButton *)sender {
    [self updateValues];
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSString *post = [NSString stringWithFormat:@"username=%@&password=%@",
                      delegate.broker.user,
                      delegate.broker.passwd];
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld",(unsigned long)[postData length]];
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
    if (dictionary && [dictionary[@"_type"] isEqualToString:@"configuration"]) {
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        
        delegate.broker.host = dictionary[@"host"];
        delegate.broker.port = dictionary[@"port"];
        delegate.broker.auth = dictionary[@"auth"];
        delegate.broker.tls = dictionary[@"tls"];
        delegate.broker.user = dictionary[@"username"];
        delegate.broker.passwd = dictionary[@"password"];
        delegate.broker.trackurl = dictionary[@"trackurl"];
        
        NSString *base = @"";
        for (NSString *topic in dictionary[@"topicList"]) {
            if (base.length) {
                base = [base stringByAppendingString:@" "];
            }
            base = [base stringByAppendingString:topic];
        }
        delegate.broker.base = base;
        
        delegate.broker.clientid = dictionary[@"clientid"];
        [self updated];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Settings loaded"
                                                            message:[AppDelegate dataToString:self.receivedData]
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
        [alertView show];
    } else {
        NSString *message = [AppDelegate dataToString:self.receivedData];
        if (dictionary) {
            if ([dictionary[@"result"] isKindOfClass:[NSString class]]) {
                message = dictionary[@"result"];
            }
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Settings invalid"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
        [alertView show];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate connect];
}

@end
