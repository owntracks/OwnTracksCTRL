//
//  Broker.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 09.05.16.
//  Copyright © 2016 OwnTracks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface Broker : NSManagedObject

+ (Broker *)existBrokerInManagedObjectContext:(NSManagedObjectContext *)context;
+ (Broker *)brokerInManagedObjectContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END

#import "Broker+CoreDataProperties.h"
