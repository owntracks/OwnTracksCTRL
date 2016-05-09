//
//  Broker+CoreDataProperties.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 09.05.16.
//  Copyright © 2016 OwnTracks. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Broker.h"

NS_ASSUME_NONNULL_BEGIN

@interface Broker (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *auth;
@property (nullable, nonatomic, retain) NSString *base;
@property (nullable, nonatomic, retain) NSString *certurl;
@property (nullable, nonatomic, retain) NSString *clientid;
@property (nullable, nonatomic, retain) NSString *host;
@property (nullable, nonatomic, retain) NSString *passwd;
@property (nullable, nonatomic, retain) NSNumber *port;
@property (nullable, nonatomic, retain) NSNumber *tls;
@property (nullable, nonatomic, retain) NSString *trackurl;
@property (nullable, nonatomic, retain) NSString *user;

@end

NS_ASSUME_NONNULL_END
