//
//  ConfD+Create.m
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 30.10.14.
//  Copyright © 2013-2016 Christoph Krey. All rights reserved.
//

#import "ConfD+Create.h"

@implementation ConfD (Create)

+ (ConfD *)existConfDInManagedObjectContext:(NSManagedObjectContext *)context
{
    ConfD *confD = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ConfD"];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            confD = [matches lastObject];
        }
    }
    
    return confD;
}

+ (ConfD *)confDInManagedObjectContext:(NSManagedObjectContext *)context
{
    ConfD *confD = [ConfD existConfDInManagedObjectContext:context];
    
    if (!confD) {
        
        confD = [NSEntityDescription insertNewObjectForEntityForName:@"ConfD" inManagedObjectContext:context];
        confD.user = @"demo";
        confD.passwd = @"demo";
    }
    
    return confD;
}

@end
