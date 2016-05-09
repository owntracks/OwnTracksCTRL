//
//  Vehicle+CoreDataProperties.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 09.05.16.
//  Copyright © 2016 OwnTracks. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Vehicle.h"

NS_ASSUME_NONNULL_BEGIN

@interface Vehicle (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *acc;
@property (nullable, nonatomic, retain) NSString *alarm;
@property (nullable, nonatomic, retain) NSNumber *alt;
@property (nullable, nonatomic, retain) NSNumber *cog;
@property (nullable, nonatomic, retain) NSNumber *dist;
@property (nullable, nonatomic, retain) NSString *event;
@property (nullable, nonatomic, retain) NSNumber *gpio1;
@property (nullable, nonatomic, retain) NSNumber *gpio2;
@property (nullable, nonatomic, retain) NSNumber *gpio3;
@property (nullable, nonatomic, retain) NSNumber *gpio5;
@property (nullable, nonatomic, retain) NSNumber *gpio7;
@property (nullable, nonatomic, retain) NSString *imei;
@property (nullable, nonatomic, retain) NSString *info;
@property (nullable, nonatomic, retain) NSNumber *lat;
@property (nullable, nonatomic, retain) NSNumber *lon;
@property (nullable, nonatomic, retain) NSNumber *showtrack;
@property (nullable, nonatomic, retain) NSDate *start;
@property (nullable, nonatomic, retain) NSNumber *status;
@property (nullable, nonatomic, retain) NSNumber *temp0;
@property (nullable, nonatomic, retain) NSNumber *temp1;
@property (nullable, nonatomic, retain) NSString *tid;
@property (nullable, nonatomic, retain) NSString *topic;
@property (nullable, nonatomic, retain) NSData *track;
@property (nullable, nonatomic, retain) NSString *trigger;
@property (nullable, nonatomic, retain) NSNumber *trip;
@property (nullable, nonatomic, retain) NSDate *tst;
@property (nullable, nonatomic, retain) NSNumber *vacc;
@property (nullable, nonatomic, retain) NSNumber *vbatt;
@property (nullable, nonatomic, retain) NSNumber *vel;
@property (nullable, nonatomic, retain) NSString *version;
@property (nullable, nonatomic, retain) NSNumber *vext;

@end

NS_ASSUME_NONNULL_END
