//
//  Vehicle+Create.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 11.11.13.
//  Copyright © 2013-2016 Christoph Krey. All rights reserved.
//

#import "Vehicle.h"

#ifndef CTRLTV

#import <MapKit/MapKit.h>
@interface Vehicle (Create) <MKAnnotation, MKOverlay>

+ (Vehicle *)vehicleNamed:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Vehicle *)existsVehicleWithTid:(NSString *)tid inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Vehicle *)existsVehicleNamed:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSArray *)allVehiclesInManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)trash;
- (CLLocationCoordinate2D)coordinate;
- (NSUInteger)trackCount;
- (MKPolyline *)polyLine;
- (NSString *)subtitle;

@end

#else

#import <CoreLocation/CoreLocation.h>
@interface Vehicle (Create)

+ (Vehicle *)vehicleNamed:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Vehicle *)existsVehicleWithTid:(NSString *)tid inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Vehicle *)existsVehicleNamed:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSArray *)allVehiclesInManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)trash;
- (CLLocationCoordinate2D)coordinate;
- (NSUInteger)trackCount;
- (NSString *)subtitle;

@end

#endif
