//
//  OPMQTTPlusThread.m
//  OwnTracksGW
//
//  Created by Christoph Krey on 18.09.14.
//  Copyright © 2014-2016 christophkrey. All rights reserved.
//

#import "StatefullThread.h"
#import "AppDelegate.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface StatefullThread()
@property (strong, nonatomic) MQTTSession *mqttSession;
@end

@implementation StatefullThread

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

- (void)main {
    
    self.mqttSession = [[MQTTSession alloc] initWithClientId:[NSString stringWithFormat:@"%@Z", self.clientid]
                                                    userName:self.user
                                                    password:self.passwd
                                                   keepAlive:60
                                                cleanSession:FALSE
                                                        will:NO
                                                   willTopic:nil
                                                     willMsg:nil
                                                     willQoS:0
                                              willRetainFlag:NO
                                               protocolLevel:4
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSDefaultRunLoopMode];
    
    self.mqttSession.delegate = self;
    if ([self.mqttSession connectAndWaitToHost:self.host
                               port:self.port
                           usingSSL:self.tls]) {
        
        NSMutableDictionary *subscriptions = [[NSMutableDictionary alloc] init];
        NSArray *topicFilters = [self.base componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for (NSString *topicFilter in topicFilters) {
            if (topicFilter.length) {
                [subscriptions setObject:@(MQTTQosLevelAtLeastOnce) forKey:[NSString stringWithFormat:@"%@/+", topicFilter]];
                [subscriptions setObject:@(MQTTQosLevelAtLeastOnce) forKey:[NSString stringWithFormat:@"%@/+/+", topicFilter]];
            }
        }
        
        [self.mqttSession subscribeAndWaitToTopics:subscriptions];
        
        while (!self.terminate) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
    [self.mqttSession closeAndWait];
    }
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    DDLogVerbose(@"PUBLISH %@ %@", topic, data);
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate performSelector:@selector(processMessage:)
                      withObject:@{@"topic": topic, @"data": data}];
}


@end
