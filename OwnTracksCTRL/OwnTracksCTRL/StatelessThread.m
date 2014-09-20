//
//  OPMQTTThread.m
//  OwnTracksGW
//
//  Created by Christoph Krey on 18.09.14.
//  Copyright (c) 2014 christophkrey. All rights reserved.
//

#import "StatelessThread.h"
#import "AppDelegate.h"
#import "Vehicle+Create.h"

@interface StatelessThread()
@property (strong, nonatomic) MQTTSession *mqttSession;

@end

@implementation StatelessThread

- (void)main {
    NSLog(@"StatelessThread");
    
    self.mqttSession = [[MQTTSession alloc] initWithClientId:self.clientid
                                                    userName:self.user
                                                    password:self.passwd
                                                   keepAlive:60
                                                cleanSession:TRUE
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
                [subscriptions setObject:@(MQTTQoSLevelAtMostOnce) forKey:topicFilter];
            }
        }
        
        [self.mqttSession subscribeToTopics:subscriptions];
        
        while (!self.terminate) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [self.mqttSession unsubscribeTopics:topicFilters];
        [self.mqttSession close];
    }
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    NSLog(@"PUBLISH %@ %@", topic, data);
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate performSelector:@selector(processMessage:)
                                  withObject:@{@"topic": topic, @"data": data}];
}

@end
