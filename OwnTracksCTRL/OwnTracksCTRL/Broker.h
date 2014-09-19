//
//  Broker.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 19.09.14.
//  Copyright (c) 2014 OwnTracks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Broker : NSManagedObject

@property (nonatomic, retain) NSString * host;
@property (nonatomic, retain) NSNumber * port;
@property (nonatomic, retain) NSNumber * tls;
@property (nonatomic, retain) NSNumber * auth;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * passwd;
@property (nonatomic, retain) NSString * base;
@property (nonatomic, retain) NSString * clientid;

@end
