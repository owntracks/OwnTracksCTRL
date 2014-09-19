//
//  OPMQTTThread.m
//  OwnTracksGW
//
//  Created by Christoph Krey on 18.09.14.
//  Copyright (c) 2014 christophkrey. All rights reserved.
//

#import "StatelessThread.h"
#import "AppDelegate.h"

@interface StatelessThread()
@property (strong, nonatomic) MQTTSession *mqttSession;
@property (nonatomic) BOOL sessionPresent;
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
                                                 forMode:NSRunLoopCommonModes];
    
    self.mqttSession.delegate = self;
    if ([self.mqttSession connectAndWaitToHost:self.host
                                      port:self.port
                                  usingSSL:self.tls]) {
        
        if (!self.sessionPresent) {
            [self.mqttSession subscribeAndWaitToTopic:self.base atLevel:MQTTQoSLevelAtMostOnce];
        }
     
        while (!self.terminate) {
            [NSThread sleepForTimeInterval:1];
        }
        
        [self.mqttSession unsubscribeAndWaitTopic:self.base];
        [self.mqttSession closeAndWait];
    }
}

- (void)connected:(MQTTSession *)session sessionPresent:(BOOL)sessionPresent {
    NSLog(@"CONNACK %d", sessionPresent);
    self.sessionPresent = sessionPresent;
}

- (void)subAckReceived:(MQTTSession *)session msgID:(UInt16)msgID grantedQoss:(NSArray *)qoss {
    NSLog(@"SUBACK %@", qoss);
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    NSLog(@"PUBLISH %@ %@", topic, data);
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate performSelectorOnMainThread:@selector(processMessage:)
                                  withObject:@{@"topic": topic, @"data": data}
                               waitUntilDone:FALSE];
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error {
    NSLog(@"Event %ld %@", (long)eventCode, error);
}

@end
