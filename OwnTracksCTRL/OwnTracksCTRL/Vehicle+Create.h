//
//  Vehicle+Create.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 11.11.13.
//  Copyright (c) 2013, 2014 Christoph Krey. All rights reserved.
//

#import "Vehicle.h"
#import <MapKit/MapKit.h>

@interface Vehicle (Create) <MKAnnotation, MKOverlay>
+ (Vehicle *)vehicleNamed:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Vehicle *)existsVehicleWithTid:(NSString *)tid inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Vehicle *)existsVehicleNamed:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSArray *)allVehiclesInManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)trash;
- (CLLocationCoordinate2D)coordinate;
- (MKPolyline *)polyLine;

@end
