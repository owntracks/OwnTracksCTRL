//
//  LoginViewController.m
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 24.10.14.
//  Copyright © 2014-2016 OwnTracks. All rights reserved.
//

#import "LoginVC.h"
#import "AppDelegate.h"
#import "Vehicle.h"

#import <CocoaLumberjack/CocoaLumberjack.h>

@interface LoginVC ()
@property (weak, nonatomic) IBOutlet UITextField *UIuser;
@property (weak, nonatomic) IBOutlet UITextField *UIpassword;
@property (weak, nonatomic) IBOutlet UIButton *UILookup;

@property (strong, nonatomic) NSURLSession *urlSession;
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;

@property (strong, nonatomic) UIAlertController *alertController;

@property (nonatomic) BOOL autostart;

@end

@implementation LoginVC

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

- (void)loadView {
    [super loadView];
    self.autostart = true;
}

- (void)automaticStart {
    self.autostart = true;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updated];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [self.navigationController.navigationBar setHidden:TRUE];
    [appDelegate disconnect];
    if (self.autostart) {
        [self lookup:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self updateValues];
}

- (void)updateValues {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    if (self.UIuser) {
        [[NSUserDefaults standardUserDefaults] setObject:self.UIuser.text forKey:@"ctrluser"];
    }
    if (self.UIpassword) {
        [[NSUserDefaults standardUserDefaults] setObject:self.UIpassword.text forKey:@"ctrlpass"];
    }
    [delegate saveContext];
}

- (void)updated {    
    self.UIuser.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"ctrluser"];
    self.UIpassword.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"ctrlpass"];
}

- (IBAction)touchedOutsideText:(UITapGestureRecognizer *)sender {
    [self updateValues];
    [self.UIuser resignFirstResponder];
    [self.UIpassword resignFirstResponder];
}

- (IBAction)changedUser:(UITextField *)sender {
    [Vehicle trash];
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate.managedObjectContext deleteObject:delegate.broker];
    delegate.broker = [Broker brokerInManagedObjectContext:delegate.managedObjectContext];
    [delegate saveContext];
}

- (IBAction)lookup:(UIButton *)sender {
    self.autostart = false;
    if (self.downloadTask) {
        [self.downloadTask cancel];
    }

    [self updateValues];
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    NSString *tokenPost = @"";
    if (delegate.token && delegate.token.length > 0) {
        tokenPost = [NSString stringWithFormat:@"&token=%@", delegate.token];
    }
    
    NSUUID *uuid = [[UIDevice currentDevice] identifierForVendor];
    
    NSString *uuidString = [uuid.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    DDLogVerbose(@"uuidString=%@", uuidString);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *urlString = [[NSUserDefaults standardUserDefaults] stringForKey:@"ctrldurl"];
    DDLogVerbose(@"urlString=%@", urlString);
    
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    
    NSString *authStr = [NSString stringWithFormat:@"%@:%@",
                         [[NSUserDefaults standardUserDefaults] valueForKey:@"ctrluser"],
                         [[NSUserDefaults standardUserDefaults] valueForKey:@"ctrlpass"]];
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat: @"Basic %@",[authData base64EncodedStringWithOptions:0]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    DDLogVerbose(@"request=%@", request);

    self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    self.downloadTask =
    [self.urlSession downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {

        DDLogVerbose(@"downloadTaskWithRequest completionhandler %@ %@ %@", location, response, error);
        if (error) {
            self.alertController = [UIAlertController alertControllerWithTitle:@"Lookup failed"
                                                                           message:[error localizedDescription]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     [self.alertController dismissViewControllerAnimated:TRUE completion:nil];
                                                                 }];
            
            UIAlertAction* continueAction = [UIAlertAction actionWithTitle:@"Continue"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self performSelectorOnMainThread:@selector(login)
                                                                                             withObject:nil
                                                                                          waitUntilDone:NO];
                                                                      [self.alertController dismissViewControllerAnimated:TRUE completion:nil];
                                                                  }];
            
            [self.alertController addAction:cancelAction];
            [self.alertController addAction:continueAction];
            [self performSelectorOnMainThread:@selector(showAlertController) withObject:nil waitUntilDone:NO];
            
        } else {
            NSDictionary *dictionary = nil;
            NSData *data = nil;
            if (location) {
                data = [NSData dataWithContentsOfURL:location];
            }
            if (data) {
                NSError *error;
                dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            }
            if (dictionary && [dictionary[@"_type"] isEqualToString:@"configuration"]) {
                DDLogVerbose(@"configuration %@", dictionary);
                AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

                delegate.broker.host = [self stringFromJSON:dictionary key:@"host"];
                delegate.broker.port = [self numberFromJSON:dictionary key:@"port"];
                delegate.broker.auth = [self numberFromJSON:dictionary key:@"auth"];
                delegate.broker.tls = [self numberFromJSON:dictionary key:@"tls"];
                delegate.broker.user = [self stringFromJSON:dictionary key:@"username"];
                delegate.broker.passwd = [self stringFromJSON:dictionary key:@"password"];
                delegate.broker.trackurl = [self stringFromJSON:dictionary key:@"trackurl"];
                delegate.broker.certurl = [self stringFromJSON:dictionary key:@"certurl"];

                NSString *base = @"";
                for (NSString *topic in [self arrayFromJSON:dictionary key:@"topicList"]) {
                    if (base.length) {
                        base = [base stringByAppendingString:@" "];
                    }
                    base = [base stringByAppendingString:topic];
                }
                delegate.broker.base = base;

                NSUUID *uuid = [[UIDevice currentDevice] identifierForVendor];
                NSString *uuidString = [uuid.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""];
                
                delegate.broker.clientid = [NSString stringWithFormat:@"%@-%@",
                                            [self stringFromJSON:dictionary key:@"clientid"],
                                            uuidString
                                            ];
                [self updated];
                [delegate saveContext];
                [self performSelectorOnMainThread:@selector(login) withObject:nil waitUntilDone:NO];
            } else {
                NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (dictionary) {
                    if ([dictionary[@"message"] isKindOfClass:[NSString class]]) {
                        message = dictionary[@"message"];
                    }
                }
                self.alertController = [UIAlertController alertControllerWithTitle:@"Settings invalid"
                                                                           message:message                                                                    preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction * action) {
                                                                         [self.alertController dismissViewControllerAnimated:TRUE completion:nil];
                                                                     }];
                
                [self.alertController addAction:cancelAction];
                [self performSelectorOnMainThread:@selector(showAlertController) withObject:nil waitUntilDone:NO];
            }
        }

        self.downloadTask = nil;
        self.urlSession = nil;
    }];

    [self.downloadTask resume];
}

- (void)showAlertController {
    [self presentViewController:self.alertController animated:YES completion:nil];
}

- (void)login {
    [self performSegueWithIdentifier:@"Login" sender:nil];
}

- (IBAction)direct:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self performSegueWithIdentifier:@"Settings" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Login"]) {
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate connect];
    }
}

- (NSString *)stringFromJSON:(NSDictionary *)dictionary key:(NSString *)key {
    NSString *string = nil;
    
    id object = [dictionary objectForKey:key];
    if (object) {
        if ([object isKindOfClass:[NSString class]]) {
            string = (NSString *)object;
        }
    }
    return string;
}

- (NSNumber *)numberFromJSON:(NSDictionary *)dictionary key:(NSString *)key {
    NSNumber *number = nil;
    
    id object = [dictionary objectForKey:key];
    if (object) {
        if ([object isKindOfClass:[NSNumber class]]) {
            number = (NSNumber *)object;
        }
    }
    return number;
}

- (NSArray *)arrayFromJSON:(NSDictionary *)dictionary key:(NSString *)key {
    NSArray *array = nil;
    
    id object = [dictionary objectForKey:key];
    if (object) {
        if ([object isKindOfClass:[NSArray class]]) {
            array = (NSArray *)object;
        }
    }
    return array;
}

@end
