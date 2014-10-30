//
//  ConfD.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 30.10.14.
//  Copyright (c) 2014 OwnTracks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ConfD : NSManagedObject

@property (nonatomic, retain) NSString * passwd;
@property (nonatomic, retain) NSString * user;

@end
