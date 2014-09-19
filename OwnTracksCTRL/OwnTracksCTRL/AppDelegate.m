//
//  OPAppDelegate.m
//  OwnTracksGW
//
//  Created by Christoph Krey on 29.05.14.
//  Copyright (c) 2014 christophkrey. All rights reserved.
//

#import "AppDelegate.h"
#import "VehiclesVC.h"
#import "StatelessThread.h"
#import "StatefullThread.h"
#import "Vehicle+Create.h"

@interface AppDelegate()
@property (strong, nonatomic) NSTimer *disconnectTimer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (strong, nonatomic) void (^completionHandler)(UIBackgroundFetchResult);
@property (strong, nonatomic) StatelessThread *mqttThread;
@property (strong, nonatomic) StatefullThread *mqttPlusThread;
@property (strong, nonatomic) NSManagedObjectContext *queueManagedObjectContext;
@end


#define RECONNECT_TIMER 1.0
#define RECONNECT_TIMER_MAX 64.0
#define BACKGROUND_DISCONNECT_AFTER 8.0

size_t isutf8(unsigned char *str, size_t len);
/*
 Check if the given unsigned char * is a valid utf-8 sequence.
 
 Return value :
 If the string is valid utf-8, 0 is returned.
 Else the position, starting from 1, is returned.
 
 Valid utf-8 sequences look like this :
 0xxxxxxx
 110xxxxx 10xxxxxx
 1110xxxx 10xxxxxx 10xxxxxx
 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
 */

size_t isutf8(unsigned char *str, size_t len)
{
    size_t i = 0;
    size_t continuation_bytes = 0;
    
    while (i < len)
    {
        if (str[i] <= 0x7F)
            continuation_bytes = 0;
        else if (str[i] >= 0xC0 /*11000000*/ && str[i] <= 0xDF /*11011111*/)
            continuation_bytes = 1;
        else if (str[i] >= 0xE0 /*11100000*/ && str[i] <= 0xEF /*11101111*/)
            continuation_bytes = 2;
        else if (str[i] >= 0xF0 /*11110000*/ && str[i] <= 0xF4 /* Cause of RFC 3629 */)
            continuation_bytes = 3;
        else
            return i + 1;
        i += 1;
        while (i < len && continuation_bytes > 0
               && str[i] >= 0x80
               && str[i] <= 0xBF)
        {
            i += 1;
            continuation_bytes -= 1;
        }
        if (continuation_bytes != 0)
            return i + 1;
    }
    return 0;
}


@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.backgroundTask = UIBackgroundTaskInvalid;
    self.completionHandler = nil;
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    return YES;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.Broker = [Broker brokerInManagedObjectContext:self.managedObjectContext];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self saveContext];
    [self.mqttThread setTerminate:TRUE];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (self.backgroundTask) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
            self.backgroundTask = UIBackgroundTaskInvalid;
        }
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    self.mqttThread = [[StatelessThread alloc] init];
    self.mqttThread.host = self.broker.host;
    self.mqttThread.port = [self.broker.port intValue];
    self.mqttThread.tls = [self.broker.tls boolValue];
    self.mqttThread.user = (self.broker.user == nil || self.broker.user.length > 0) ? self.broker.user : nil;
    self.mqttThread.passwd = (self.broker.user != nil && self.broker.passwd.length > 0) ? self.broker.passwd : nil;
    self.mqttThread.base = self.broker.base;
    self.mqttThread.clientid = self.broker.clientid;
    [self.mqttThread start];
    
    self.mqttPlusThread = [[StatefullThread alloc] init];
    self.mqttPlusThread.host = self.broker.host;
    self.mqttPlusThread.port = [self.broker.port intValue];
    self.mqttPlusThread.tls = [self.broker.tls boolValue];
    self.mqttPlusThread.user = (self.broker.user == nil || self.broker.user.length > 0) ? self.broker.user : nil;
    self.mqttPlusThread.passwd = (self.broker.user != nil && self.broker.passwd.length > 0) ? self.broker.passwd : nil;
    self.mqttPlusThread.base = self.broker.base;
    self.mqttPlusThread.clientid = self.broker.clientid;
    [self.mqttPlusThread start];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveContext];
    [self.mqttThread setTerminate:TRUE];
    [self.mqttPlusThread setTerminate:TRUE];
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
    NSLog(@"processMessage %@", object);
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)object;
        NSData *data = dictionary[@"data"];
        NSString *topic = dictionary[@"topic"];
        
        NSArray *topicComponents = [topic componentsSeparatedByCharactersInSet:
                                    [NSCharacterSet characterSetWithCharactersInString:@"/"]];
        NSArray *baseComponents = [self.broker.base componentsSeparatedByCharactersInSet:
                                   [NSCharacterSet characterSetWithCharactersInString:@"/"]];
        
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
            NSLog(@"processing %@", topic);

            Vehicle *vehicle = [Vehicle vehicleNamed:baseTopic
                              inManagedObjectContext:self.queueManagedObjectContext];
            
            if ([topicComponents count] == [baseComponents count]) {
                NSDictionary *dictionary = nil;
                if (data.length) {
                    NSError *error;
                    dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                }
                
                vehicle.acc = @([dictionary[@"acc"] doubleValue]);
                vehicle.alt = dictionary[@"alt"];
                vehicle.cog = dictionary[@"cog"];
                vehicle.dist= dictionary[@"dist"];
                vehicle.event= @"event";
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
                
            } else {
                if ([subTopic isEqualToString:@"alarm"]) {
                    vehicle.alarm = @"Alarm";
                } else if ([subTopic isEqualToString:@"status"]) {
                    NSString *status = [AppDelegate dataToString:data];
                    vehicle.status = @([status intValue]);
                } else if ([subTopic isEqualToString:@"info"]) {
                    NSString *info = [AppDelegate dataToString:data];
                    vehicle.info= info;
                } else if ([subTopic isEqualToString:@"start"]) {
                    vehicle.start = [NSDate dateWithTimeIntervalSince1970:0];
                    vehicle.version = @"version";
                    vehicle.imei = @"imei";
                } else if ([subTopic isEqualToString:@"gpio"]) {
                    vehicle.gpio1= @(TRUE);
                    vehicle.gpio3= @(TRUE);
                    vehicle.gpio7= @(TRUE);
                } else if ([subTopic isEqualToString:@"voltage"]) {
                    vehicle.vbatt= @(0);
                    vehicle.vext= @(0);
                } else {
                    //
                }
            }
            
            if ([self.queueManagedObjectContext hasChanges] && ![self.queueManagedObjectContext save:NULL]) {
                NSLog(@"Unresolved error");
            }
            NSLog(@"processing %@ finished", topic);
        }];
    }
}

+ (NSString *)dataToString:(NSData *)data
{
    if (isutf8((unsigned char *)[data bytes], data.length) == 0) {
        NSString *message = [[NSString alloc] init];
        for (int i = 0; i < data.length; i++) {
            char c;
            [data getBytes:&c range:NSMakeRange(i, 1)];
            message = [message stringByAppendingFormat:@"%c", c];
        }
        
        const char *cp = [message cStringUsingEncoding:NSISOLatin1StringEncoding];
        if (cp) {
            NSString *u = @(cp);
            return [NSString stringWithFormat:@"%@", u];
        } else {
            return [NSString stringWithFormat:@"%@", [data description]];
        }
    } else {
        return [NSString stringWithFormat:@"%@", [data description]];
    }
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
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
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"OwnTracksGW.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    self.completionHandler = completionHandler;
    [self startBackgroundTimer];
}

#pragma actions

- (void)startBackgroundTimer
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        if (self.disconnectTimer && self.disconnectTimer.isValid) {
        } else {
            self.disconnectTimer = [NSTimer timerWithTimeInterval:BACKGROUND_DISCONNECT_AFTER
                                                           target:self
                                                         selector:@selector(disconnectInBackground)
                                                         userInfo:Nil repeats:FALSE];
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            [runLoop addTimer:self.disconnectTimer
                      forMode:NSDefaultRunLoopMode];
        }
    }
}

- (void)disconnectInBackground
{
    self.disconnectTimer = nil;
    [self.mqttThread setTerminate:TRUE];
    [self.mqttPlusThread setTerminate:TRUE];
}

@end
