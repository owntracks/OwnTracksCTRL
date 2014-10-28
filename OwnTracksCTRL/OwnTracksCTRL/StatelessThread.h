//
//  OPMQTTThread.h
//  OwnTracksGW
//
//  Created by Christoph Krey on 18.09.14.
//  Copyright (c) 2014 christophkrey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MQTTClient/MQTTClient.h>

@interface StatelessThread : NSThread <MQTTSessionDelegate, UIAlertViewDelegate>
@property (nonatomic) BOOL terminate;
@property (nonatomic,readonly) BOOL connected;
@property (strong, nonatomic) NSString *user;
@property (strong, nonatomic) NSString *passwd;
@property (strong, nonatomic) NSString *clientid;
@property (strong, nonatomic) NSString *host;
@property (strong, nonatomic) NSString *base;
@property (nonatomic) BOOL tls;
@property (nonatomic) int port;
@end
