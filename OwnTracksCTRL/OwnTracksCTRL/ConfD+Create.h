//
//  ConfD+Create.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 30.10.14.
//  Copyright © 2013-2016 Christoph Krey. All rights reserved.
//

#import "ConfD.h"

@interface ConfD (Create)
+ (ConfD *)existConfDInManagedObjectContext:(NSManagedObjectContext *)context;
+ (ConfD *)confDInManagedObjectContext:(NSManagedObjectContext *)context;

@end
