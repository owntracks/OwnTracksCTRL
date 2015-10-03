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

#ifndef CTRLTV
#import <CocoaLumberjack/CocoaLumberjack.h>
#else 
#define DDLogVerbose NSLog
#endif

@interface StatelessThread()
@property (strong, nonatomic) MQTTSession *mqttSession;
@property (nonatomic, strong, readwrite) NSString *connectedTo;
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation StatelessThread

#ifndef CTRLTV
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#endif

- (void)main {
    DDLogVerbose(@"StatelessThread");
    
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
        self.connectedTo = self.host;
        
        NSMutableDictionary *subscriptions = [[NSMutableDictionary alloc] init];
        NSArray *topicFilters = [self.base componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for (NSString *topicFilter in topicFilters) {
            if (topicFilter.length) {
                [subscriptions setObject:@(MQTTQosLevelAtMostOnce) forKey:topicFilter];
            }
        }
        
        [self.mqttSession subscribeToTopics:subscriptions];
        
        while (!self.terminate) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        
        [self.mqttSession unsubscribeTopics:topicFilters];
        [self.mqttSession close];
    } else {
        NSString *loadButtonTitle = nil;
        NSString *errorMessage = [NSString stringWithFormat:@"%@://%@@%@:%d as %@\n%@",
                                  self.tls ? @"mqtts" : @"mqtt",
                                  self.user,
                                  self.host,
                                  self.port,
                                  self.clientid,
                                  [self.error description]];
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if ([self.error.domain isEqualToString:NSOSStatusErrorDomain] &&
            self.error.code == errSSLXCertChainInvalid &&
            self.tls &&
            delegate.broker.certurl &&
            delegate.broker.certurl.length > 0) {
            loadButtonTitle = @"Load Certificate";
            errorMessage = @"OwnTracks uses a TLS encrypted server connection to protect your privacy. Please load, check and install the server's certificate";
            DDLogVerbose(@"certurl %@", delegate.broker.certurl);
#ifndef CTRLTV
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"MQTT connection failed"
                                                            message:errorMessage
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", loadButtonTitle, nil];
        [alertView show];
#else
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:delegate.broker.certurl]];
#endif
        }
    }
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid {
    DDLogVerbose(@"PUBLISH %@ %@", topic, data);
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate performSelector:@selector(processMessage:)
                                  withObject:@{@"topic": topic, @"data": data}];
}

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error {
    switch (eventCode) {
        case MQTTSessionEventConnectionClosed:
        case MQTTSessionEventConnectionClosedByBroker:
            self.connectedTo = nil;
            break;
        case MQTTSessionEventConnected:
            break;
        default:
            self.error = error;
            break;
    }
}

#ifndef CTRLTV
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (buttonIndex > 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:delegate.broker.certurl]];
    }
}
#endif

@end
