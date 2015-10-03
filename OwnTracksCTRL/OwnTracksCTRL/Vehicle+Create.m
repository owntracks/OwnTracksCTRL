//
//  Vehicle+Create.m
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 11.11.13.
//  Copyright (c) 2013, 2014 Christoph Krey. All rights reserved.
//

#import "Vehicle+Create.h"
#import "AppDelegate.h"

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

+ (Vehicle *)existsVehicleWithTid:(NSString *)tid
         inManagedObjectContext:(NSManagedObjectContext *)context
{
    Vehicle *vehicle = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Vehicle"];
    request.predicate = [NSPredicate predicateWithFormat:@"tid = %@", tid];
    
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

+ (void)trash {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSArray *vehicles = [Vehicle allVehiclesInManagedObjectContext:delegate.managedObjectContext];
    for (Vehicle *vehicle in vehicles) {
        [delegate.managedObjectContext deleteObject:vehicle];
    }
    [delegate saveContext];
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

- (NSString *)subtitle {
    return self.tst ? [NSDateFormatter localizedStringFromDate:self.tst
                                                     dateStyle:NSDateFormatterShortStyle
                                                     timeStyle:NSDateFormatterShortStyle]
    : @"<null>" ;
}

- (NSString *)title {
    return self.info ? self.info : self.tid;
}

- (NSUInteger)trackCount {
    NSUInteger count = 0;
    NSDictionary *dictionary = nil;
    if (self.track) {
        NSError *error;
        dictionary = [NSJSONSerialization JSONObjectWithData:self.track options:0 error:&error];
        if (dictionary) {
            NSArray *track = dictionary[@"track"];
            if (track) {
                count = track.count;
            }
        }
    }
    return count;
}


#ifndef CTRLTV
- (MKMapRect)boundingMapRect {
    MKMapPoint point = MKMapPointForCoordinate([self coordinate]);
    MKMapRect mapRect = MKMapRectMake(
                                   point.x,
                                   point.y,
                                   1.0,
                                   1.0
                                   );
    NSDictionary *dictionary = nil;
    if (self.track) {
        NSError *error;
        dictionary = [NSJSONSerialization JSONObjectWithData:self.track options:0 error:&error];
        if (dictionary) {
            NSArray *track = dictionary[@"track"];
            if (track) {
                for (NSDictionary *trackpoint in track) {
                    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(
                                                                                   [trackpoint[@"lat"] doubleValue],
                                                                                   [trackpoint[@"lon"] doubleValue]
                                                                                   );
                    MKMapPoint mapPoint = MKMapPointForCoordinate(coordinate);
                    if (mapPoint.x < mapRect.origin.x) {
                        mapRect.size.width += mapRect.origin.x - mapPoint.x;
                        mapRect.origin.x = mapPoint.x;
                    } else if (mapPoint.x + 3 > mapRect.origin.x + mapRect.size.width) {
                        mapRect.size.width = mapPoint.x - mapRect.origin.x;
                    }
                    if (mapPoint.y < mapRect.origin.y) {
                        mapRect.size.height += mapRect.origin.y - mapPoint.y;
                        mapRect.origin.y = mapPoint.y;
                    } else if (mapPoint.y > mapRect.origin.y + mapRect.size.height) {
                        mapRect.size.height = mapPoint.y - mapRect.origin.y;
                    }
                }
            }
        }
    }
    return mapRect;
}

- (MKPolyline *)polyLine {
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D));
    coordinates[0] = [self coordinate];
    int count = 1;
    
    NSDictionary *dictionary = nil;
    if (self.track) {
        NSError *error;
        dictionary = [NSJSONSerialization JSONObjectWithData:self.track options:0 error:&error];
        if (dictionary) {
            NSArray *track = dictionary[@"track"];
            if (track && [track count] > 0) {
                coordinates = (CLLocationCoordinate2D *)realloc(coordinates,
                                                                [track count] * sizeof(CLLocationCoordinate2D));
                count = 0;
                if (coordinates) {
                    for (NSDictionary *trackpoint in track) {
                        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(
                                                                                       [trackpoint[@"lat"] doubleValue],
                                                                                       [trackpoint[@"lon"] doubleValue]
                                                                                       );
                        coordinates[count++] = coordinate;
                    }
                }
            }
        }
    }
    
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:count];
    free(coordinates);
    return polyLine;
}

#endif

@end
