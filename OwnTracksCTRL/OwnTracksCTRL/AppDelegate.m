//
//  OPAppDelegate.m
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 29.05.14.
//  Copyright © 2014-2016  christophkrey. All rights reserved.
//

#import "AppDelegate.h"
#import "StatefullThread.h"
#import "Vehicle+Create.h"
#import "LoginVC.h"

#import <CocoaLumberjack/CocoaLumberjack.h>

@interface AppDelegate()

@property (strong, nonatomic) StatefullThread *mqttPlusThread;
@property (strong, nonatomic) StatelessThread *mqttThread;
@property (strong, nonatomic) UIAlertController *alertController;

@property (strong, nonatomic) NSManagedObjectContext *queueManagedObjectContext;
@property (readwrite, strong, nonatomic) NSString *connectedTo;
@property (nonatomic) BOOL registered;

@end

#define RECONNECT_TIMER 1.0
#define RECONNECT_TIMER_MAX 64.0

@implementation AppDelegate

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.kiosk = @(false);
    return YES;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{    
    
#ifdef DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelVerbose];
#endif
    [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelWarning];
    
    NSDictionary *appDefaults = [NSDictionary
                                 dictionaryWithObject:@"https://mqtt-b.owntracks.de/ctrld/conf" forKey:@"ctrldurl"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.confD = [ConfD confDInManagedObjectContext:self.managedObjectContext];
    self.broker = [Broker brokerInManagedObjectContext:self.managedObjectContext];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self saveContext];
    [self disconnect];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if ([self.window.rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        //[navigationController popToRootViewControllerAnimated:false];
        if ([navigationController.topViewController respondsToSelector:@selector(automaticStart)]) {
            //[navigationController.topViewController performSelector:@selector(automaticStart) withObject:nil];
        }
    }
    [self connect];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveContext];
    [self disconnect];
}

- (void)connect {
    [self disconnect];
    
    self.mqttThread = [[StatelessThread alloc] init];
    self.mqttThread.host = self.broker.host;
    self.mqttThread.port = [self.broker.port intValue];
    self.mqttThread.tls = [self.broker.tls boolValue];
    
    if ([self.broker.auth boolValue]) {
        if (self.broker.user && self.broker.user.length > 0) {
            self.mqttThread.user = self.broker.user;
            if (self.broker.passwd && self.broker.passwd.length > 0) {
                self.mqttThread.passwd = self.broker.passwd;
            }
        } else {
            self.broker.user = nil;
            self.broker.passwd = nil;
        }
    } else {
        self.mqttThread.user = nil;
        self.mqttThread.passwd = nil;
    }
    
    self.mqttThread.base = self.broker.base;
    self.mqttThread.clientid = self.broker.clientid;
    
    [self.mqttThread addObserver:self forKeyPath:@"connectedTo"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:nil];
    self.registered = true;
    [self.mqttThread start];
    
    self.mqttPlusThread = [[StatefullThread alloc] init];
    self.mqttPlusThread.host = self.broker.host;
    self.mqttPlusThread.port = [self.broker.port intValue];
    self.mqttPlusThread.tls = [self.broker.tls boolValue];
    
    if ([self.broker.auth boolValue]) {
        if (self.broker.user && self.broker.user.length > 0) {
            self.mqttPlusThread.user = self.broker.user;
            if (self.broker.passwd && self.broker.passwd.length > 0) {
                self.mqttPlusThread.passwd = self.broker.passwd;
            }
        } else {
            self.broker.user = nil;
            self.broker.passwd = nil;
        }
    } else {
        self.mqttPlusThread.user = nil;
        self.mqttPlusThread.passwd = nil;
    }
    
    self.mqttPlusThread.base = self.broker.base;
    self.mqttPlusThread.clientid = self.broker.clientid;
    [self.mqttPlusThread start];
}

- (void)disconnect {
    if (self.registered) {
        [self.mqttThread removeObserver:self forKeyPath:@"connectedTo" context:nil];
        self.registered = false;
    }
    [self.mqttThread setTerminate:TRUE];
    [self.mqttPlusThread setTerminate:TRUE];
    self.connectedTo = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"connectedTo"]) {
        self.connectedTo = (NSString *)[object valueForKey:keyPath];
    }
}

- (NSManagedObjectContext *)queueManagedObjectContext
{
    if (!_queueManagedObjectContext) {
        _queueManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_queueManagedObjectContext setParentContext:self.managedObjectContext];
    }
    return _queueManagedObjectContext;
}

- (void)processMessage:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)object;
        NSData *data = dictionary[@"data"];
        NSString *topic = dictionary[@"topic"];
        
        NSArray *topicComponents = [topic componentsSeparatedByCharactersInSet:
                                    [NSCharacterSet characterSetWithCharactersInString:@"/"]];
        
        NSArray *topicFilters = [self.broker.base componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *baseComponents = [topicFilters[0] componentsSeparatedByCharactersInSet:
                                   [NSCharacterSet characterSetWithCharactersInString:@"/"]];
        
        if (topicComponents.count < baseComponents.count) {
            return;
        }
        
        NSString *baseTopic = @"";
        
        for (int i = 0; i < [baseComponents count]; i++) {
            if (baseTopic.length) {
                baseTopic = [baseTopic stringByAppendingString:@"/"];
            }
            baseTopic = [baseTopic stringByAppendingString:topicComponents[i]];
        }
        
        NSString *subTopic = @"";
        
        for (unsigned long i = [baseComponents count]; i < [topicComponents count]; i++) {
            if (subTopic.length) {
                subTopic = [subTopic stringByAppendingString:@"/"];
            }
            subTopic = [subTopic stringByAppendingString:topicComponents[i]];
        }
        
        [self.queueManagedObjectContext performBlock:^{
            
            Vehicle *vehicle = [Vehicle vehicleNamed:baseTopic
                              inManagedObjectContext:self.queueManagedObjectContext];
            if (!vehicle.tid) {
                vehicle.tid = [baseTopic substringFromIndex:MAX(0, baseTopic.length - 2)];
            }
            
            NSDictionary *dictionary = nil;
            if (data.length) {
                NSError *error;
                dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                
                if (!dictionary) {
                    NSString *payload = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSArray *values = [payload componentsSeparatedByString:@","];
                    if ([values count] == 10) {
                        dictionary = [[NSMutableDictionary alloc] initWithCapacity:9];
                        [dictionary setValue:values[0] forKey:@"tid"];
                        
                        NSScanner *scanner = [NSScanner scannerWithString:values[1]];
                        unsigned int tst = 0;
                        [scanner scanHexInt:&tst];
                        [dictionary setValue:[NSString stringWithFormat:@"%u", tst] forKey:@"tst"];
                        
                        [dictionary setValue:values[2] forKey:@"t"];
                        
                        double lat = [values[3] doubleValue] / 1000000.0;
                        [dictionary setValue:[NSString stringWithFormat:@"%.6f", lat] forKey:@"lat"];
                        
                        double lon = [values[4] doubleValue] / 1000000.0;
                        [dictionary setValue:[NSString stringWithFormat:@"%.6f", lon] forKey:@"lon"];
                        
                        int cog = [values[5] intValue] * 10;
                        [dictionary setValue:@(cog) forKey:@"cog"];
                        
                        int vel = [values[6] intValue];
                        [dictionary setValue:@(vel) forKey:@"vel"];
                        
                        int alt = [values[7] intValue] * 10;
                        [dictionary setValue:@(alt) forKey:@"alt"];
                        
                        int dist = [values[8] intValue];
                        [dictionary setValue:@(dist) forKey:@"dist"];
                        
                        int trip = [values[9] intValue] * 1000;
                        [dictionary setValue:@(trip) forKey:@"trip"];
                    }
                }
            }
            
            if ([topicComponents count] == [baseComponents count]) {
                if (dictionary) {
                    vehicle.acc = @([dictionary[@"acc"] doubleValue]);
                    vehicle.alt = dictionary[@"alt"];
                    vehicle.cog = dictionary[@"cog"];
                    vehicle.dist= dictionary[@"dist"];
                    vehicle.lat= @([dictionary[@"lat"] doubleValue]);
                    vehicle.lon= @([dictionary[@"lon"] doubleValue]);
                    
                    if (dictionary[@"tid"]) {
                        vehicle.tid = dictionary[@"tid"];
                    } else {
                        vehicle.tid = [baseTopic substringFromIndex:MAX(0, baseTopic.length - 2)];
                    }
                    
                    vehicle.trigger= dictionary[@"t"];
                    vehicle.trip=dictionary[@"trip"];
                    vehicle.tst=[NSDate dateWithTimeIntervalSince1970:[dictionary[@"tst"] doubleValue]];
                    vehicle.vacc=dictionary[@"vacc"];
                    vehicle.vel=dictionary[@"vel"];
                }
            } else {
                if ([subTopic isEqualToString:@"status"]) {
                    NSString *status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    vehicle.status = @([status intValue]);
                    
                } else if ([subTopic isEqualToString:@"info"]) {
                    NSString *info = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    vehicle.info= info;
                    
                } else if ([subTopic isEqualToString:@"start"]) {
                    NSString *start = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSArray *fields = [start componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if (fields.count == 3) {
                        NSDateFormatter * dateFormatter = [[NSDateFormatter alloc]init];
                        [dateFormatter setDateFormat:@"yyyyMMdd'T'HHmmss'Z'"];
                        [dateFormatter setTimeZone:[[NSTimeZone alloc] initWithName:@"UTC"]];
                        NSDate *startDate = [dateFormatter dateFromString:fields[2]];
                        vehicle.start = startDate;
                        vehicle.version = fields[1];
                        vehicle.imei = fields[0];
                    }
                    
                } else if ([subTopic isEqualToString:@"gpio/1"]) {
                    NSString *gpio = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    vehicle.gpio1= @([gpio intValue]);
                } else if ([subTopic isEqualToString:@"gpio/3"]) {
                    NSString *gpio = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    vehicle.gpio3= @([gpio intValue]);
                } else if ([subTopic isEqualToString:@"gpio/2"]) {
                    NSString *gpio = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    vehicle.gpio2= @([gpio intValue]);
                } else if ([subTopic isEqualToString:@"gpio/5"]) {
                    NSString *gpio = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    vehicle.gpio5= @([gpio intValue]);
                } else if ([subTopic isEqualToString:@"gpio/7"]) {
                    NSString *gpio = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    vehicle.gpio7= @([gpio intValue]);
                    
                } else if ([subTopic isEqualToString:@"voltage/batt"]) {
                    NSString *voltage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    vehicle.vbatt = @([voltage doubleValue]);
                } else if ([subTopic isEqualToString:@"voltage/ext"]) {
                    NSString *voltage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    vehicle.vext = @([voltage doubleValue]);
                    
                } else if ([subTopic isEqualToString:@"temperature/0"]) {
                    NSString *temperature = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    vehicle.temp0 = @([temperature doubleValue]);
                } else if ([subTopic isEqualToString:@"temperature/1"]) {
                    NSString *temperature = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    vehicle.temp1 = @([temperature doubleValue]);
                }
                
                NSError *error;
                if ([self.queueManagedObjectContext hasChanges] && ![self.queueManagedObjectContext save:&error]) {
                    NSLog(@"queueManagedObjectContext save:%@", error);
                }
                NSLog(@"processing %@ finished", topic);
            }
            
        }];
    }
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"managedObjectContext save: %@", error);
            abort();
        }
    }
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
#ifndef CTRLTV
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"OwnTracksGW.sqlite"];
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption: @YES};
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {
        NSLog(@"managedObjectContext save: %@", error);
        abort();
    }
#else
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                   configuration:nil
                                                             URL:nil
                                                         options:nil
                                                           error:&error]) {
        NSLog(@"managedObjectContext save: %@", error);
        abort();
    }
#endif
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)connectError:(StatelessThread *)statelessThread {
    NSString *loadButtonTitle = nil;
    NSString *errorMessage = [NSString stringWithFormat:@"%@://%@@%@:%d as %@\n%@",
                              statelessThread.tls ? @"mqtts" : @"mqtt",
                              statelessThread.user,
                              statelessThread.host,
                              statelessThread.port,
                              statelessThread.clientid,
                              [statelessThread.error localizedDescription]];
    self.alertController = [UIAlertController alertControllerWithTitle:@"MQTT connection failed"
                                                               message:errorMessage
                                                        preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             [self.alertController dismissViewControllerAnimated:TRUE completion:nil];
                                                         }];
    [self.alertController addAction:cancelAction];
    
    
    if ([statelessThread.error.domain isEqualToString:NSOSStatusErrorDomain] &&
        statelessThread.error.code == errSSLXCertChainInvalid &&
        statelessThread.tls &&
        self.broker.certurl &&
        self.broker.certurl.length > 0) {
        loadButtonTitle = @"Load Certificate";
        errorMessage = @"OwnTracks uses a TLS encrypted server connection to protect your privacy. Please load, check and install the server's certificate";
        DDLogVerbose(@"certurl %@", self.broker.certurl);
        UIAlertAction* continueAction = [UIAlertAction actionWithTitle:@"Load Certificate"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.broker.certurl]];
                                                                   [self.alertController dismissViewControllerAnimated:TRUE completion:nil];
                                                               }];
        
        [self.alertController addAction:continueAction];
        [self performSelectorOnMainThread:@selector(showAlertController) withObject:nil waitUntilDone:NO];
    }
    //[self performSelectorOnMainThread:@selector(showAlertController) withObject:nil waitUntilDone:NO];
}

- (void)showAlertController {
    UIViewController *vc = self.window.rootViewController;
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nc = (UINavigationController *)vc;
        UIViewController *presentingVC = nc.topViewController;
        [presentingVC presentViewController:self.alertController animated:YES completion:nil];
    }
}


@end
