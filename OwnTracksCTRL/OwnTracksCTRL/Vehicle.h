//
//  Vehicle.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 20.01.15.
//  Copyright (c) 2015 OwnTracks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Vehicle : NSManagedObject

@property (nonatomic, retain) NSNumber * acc;
@property (nonatomic, retain) NSString * alarm;
@property (nonatomic, retain) NSNumber * alt;
@property (nonatomic, retain) NSNumber * cog;
@property (nonatomic, retain) NSNumber * dist;
@property (nonatomic, retain) NSString * event;
@property (nonatomic, retain) NSNumber * gpio1;
@property (nonatomic, retain) NSNumber * gpio2;
@property (nonatomic, retain) NSNumber * gpio3;
@property (nonatomic, retain) NSNumber * gpio5;
@property (nonatomic, retain) NSNumber * gpio7;
@property (nonatomic, retain) NSString * imei;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSNumber * showtrack;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSString * tid;
@property (nonatomic, retain) NSString * topic;
@property (nonatomic, retain) NSData * track;
@property (nonatomic, retain) NSString * trigger;
@property (nonatomic, retain) NSNumber * trip;
@property (nonatomic, retain) NSDate * tst;
@property (nonatomic, retain) NSNumber * vacc;
@property (nonatomic, retain) NSNumber * vbatt;
@property (nonatomic, retain) NSNumber * vel;
@property (nonatomic, retain) NSString * version;
@property (nonatomic, retain) NSNumber * vext;
@property (nonatomic, retain) NSNumber * temp0;
@property (nonatomic, retain) NSNumber * temp1;

@end
