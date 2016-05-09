//
//  OPAppDelegate.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 29.05.14.
//  Copyright © 2014-2016  christophkrey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Broker.h"
#import "StatelessThread.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) Broker *broker;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSString *connectedTo;
@property (readonly, strong, nonatomic) NSString *token;

@property (strong, nonatomic) NSNumber *kiosk;

- (void)saveContext;
- (void)processMessage:(NSDictionary *)object;
- (NSURL *)applicationDocumentsDirectory;
- (void)connect;
- (void)disconnect;
- (void)connectError:(StatelessThread *)statelessThread;

@end
