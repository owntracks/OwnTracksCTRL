//
//  ConfD+Create.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 30.10.14.
//  Copyright (c) 2013, 2014 Christoph Krey. All rights reserved.
//

#import "ConfD.h"

@interface ConfD (Create)
+ (ConfD *)existConfDInManagedObjectContext:(NSManagedObjectContext *)context;
+ (ConfD *)confDInManagedObjectContext:(NSManagedObjectContext *)context;

@end
