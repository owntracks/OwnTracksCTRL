//
//  Vehicle.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 09.05.16.
//  Copyright © 2016 OwnTracks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Vehicle : NSManagedObject <MKAnnotation, MKOverlay>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) MKMapRect boundingMapRect;

+ (Vehicle *)vehicleNamed:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Vehicle *)existsVehicleWithTid:(NSString *)tid inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Vehicle *)existsVehicleNamed:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSArray *)allVehiclesInManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)trash;
- (NSUInteger)trackCount;
- (MKPolyline *)polyLine;
- (NSString *)subtitle;

@end

NS_ASSUME_NONNULL_END

#import "Vehicle+CoreDataProperties.h"
