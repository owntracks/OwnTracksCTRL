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
        broker.clientid = [[UIDevice currentDevice] name];
        broker.base = @"owntracks/+/+";
    }
    
    return broker;
}

@end
