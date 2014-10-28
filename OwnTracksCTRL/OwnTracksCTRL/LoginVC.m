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
@property (weak, nonatomic) IBOutlet UIButton *UILookup;

@property (strong, nonatomic) NSURLConnection *urlConnection;
@property (strong, nonatomic) NSMutableData *receivedData;

@property (nonatomic) BOOL firststart;

@end

@implementation LoginVC

- (void)loadView {
    [super loadView];
    self.firststart = true;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.firststart) {
        self.firststart = false;
        [self lookup:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self updateValues];
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate saveContext];
}

- (void)updateValues {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    if (self.UIuser) delegate.broker.user = self.UIuser.text;
    if (self.UIpassword) delegate.broker.passwd = self.UIpassword.text;
}

- (void)updated {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.UIuser.text = delegate.broker.user;
    self.UIpassword.text = delegate.broker.passwd;
}

- (IBAction)touchedOutsideText:(UITapGestureRecognizer *)sender {
    [self updateValues];
    [self.UIuser resignFirstResponder];
    [self.UIpassword resignFirstResponder];
}

- (IBAction)changedUser:(UITextField *)sender {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate trash];
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
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://demo.owntracks.de/ext/conf"]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    self.receivedData = [[NSMutableData alloc] init];
    self.urlConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = true;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"NSURLResponse %@", response);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Loading failed"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
    [alertView show];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
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
        [self performSegueWithIdentifier:@"Login" sender:nil];
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

- (IBAction)direct:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self performSegueWithIdentifier:@"Login" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate connect];
}

@end
