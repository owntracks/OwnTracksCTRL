//
//  Broker+Create.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 09.11.13.
//  Copyright (c) 2013, 2014 Christoph Krey. All rights reserved.
//

#import "Broker.h"

@interface Broker (Create)
+ (Broker *)existBrokerInManagedObjectContext:(NSManagedObjectContext *)context;
+ (Broker *)brokerInManagedObjectContext:(NSManagedObjectContext *)context;

@end
