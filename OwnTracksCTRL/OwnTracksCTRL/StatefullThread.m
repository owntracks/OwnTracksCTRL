//
//  OPMQTTPlusThread.m
//  OwnTracksGW
//
//  Created by Christoph Krey on 18.09.14.
//  Copyright (c) 2014 christophkrey. All rights reserved.
//

#import "StatefullThread.h"
#import "AppDelegate.h"

@interface StatefullThread()
@property (strong, nonatomic) MQTTSession *mqttSession;
@property (nonatomic) BOOL sessionPresent;
@end

static BOOL firstStart = TRUE;

@implementation StatefullThread
- (void)main {
    NSLog(@"StatefullThread");
    
    self.mqttSession = [[MQTTSession alloc] initWithClientId:[NSString stringWithFormat:@"%@-plus", self.clientid]
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
                                                     forMode:NSRunLoopCommonModes];
    
    self.mqttSession.delegate = self;
    if ([self.mqttSession connectAndWaitToHost:self.host
                                          port:self.port
                                      usingSSL:self.tls]) {
        
        if (firstStart || !self.sessionPresent) {
            [self.mqttSession subscribeAndWaitToTopic:[NSString stringWithFormat:@"%@/+", self.base]
                                              atLevel:MQTTQosLevelAtLeastOnce];
        }
        firstStart = FALSE;
        
        while (!self.terminate) {
            [NSThread sleepForTimeInterval:1];
        }
        
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
