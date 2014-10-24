//
//  Broker+Create.m
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 09.11.13.
//  Copyright (c) 2013, 2014 Christoph Krey. All rights reserved.
//

#import "Broker+Create.h"
#import <UIKit/UIKit.h>

@implementation Broker (Create)

+ (Broker *)existBrokerInManagedObjectContext:(NSManagedObjectContext *)context
{
    Broker *broker = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Broker"];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            broker = [matches lastObject];
        }
    }
    
    return broker;
}

+ (Broker *)brokerInManagedObjectContext:(NSManagedObjectContext *)context
{
    Broker *broker = [Broker existBrokerInManagedObjectContext:context];
    
    if (!broker) {
        
        broker = [NSEntityDescription insertNewObjectForEntityForName:@"Broker" inManagedObjectContext:context];
        
        broker.host = @"localhost";
        broker.port = @1883;
        broker.tls = @NO;
        broker.auth = @NO;
        broker.user = @"";
        broker.passwd = @"";
        
        NSString *deviceName = [[UIDevice currentDevice] name];
        NSString *defaultClientID = @"";
        for (int i = 0; i < deviceName.length; i++) {
            unichar ch = [deviceName characterAtIndex:i];
            if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:ch]) {
                defaultClientID = [defaultClientID stringByAppendingString:[NSString stringWithCharacters:&ch length:1]];
            }
        }
        if (defaultClientID.length < 1) {
            defaultClientID = @"ClientID";
        }
        if (defaultClientID.length > 23) {
            defaultClientID = [defaultClientID substringToIndex:23];
        }
        broker.clientid = defaultClientID;
        broker.base = @"owntracks/+/+";
    }
    
    return broker;
}

@end
