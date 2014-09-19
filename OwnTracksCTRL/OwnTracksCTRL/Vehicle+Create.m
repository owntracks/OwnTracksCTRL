//
//  Vehicle+Create.m
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 11.11.13.
//  Copyright (c) 2013, 2014 Christoph Krey. All rights reserved.
//

#import "Vehicle+Create.h"

@implementation Vehicle (Create)

+ (Vehicle *)existsVehicleNamed:(NSString *)name
     inManagedObjectContext:(NSManagedObjectContext *)context
{
    Vehicle *vehicle = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Vehicle"];
    request.predicate = [NSPredicate predicateWithFormat:@"topic = %@", name];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            vehicle = [matches lastObject];
        }
    }
    return vehicle;
}

+ (Vehicle *)vehicleNamed:(NSString *)name
    inManagedObjectContext:(NSManagedObjectContext *)context
{
    Vehicle *vehicle = [Vehicle existsVehicleNamed:name inManagedObjectContext:context];
    
    if (!vehicle) {
        vehicle = [NSEntityDescription insertNewObjectForEntityForName:@"Vehicle" inManagedObjectContext:context];
        
        vehicle.topic = name;
    }
    return vehicle;
}

+ (NSArray *)allVehiclesInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Vehicle"];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    return matches;
}

- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([self.lat doubleValue], [self.lon doubleValue]);
    return coordinate;
}

- (NSString *)title {
    return self.info ? self.info : self.topic;
}

- (NSString *)subtitle {
    return [NSString stringWithFormat:@"%@", self.tst];
}

@end
