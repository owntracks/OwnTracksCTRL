//
//  OPDetailViewControllerTableViewController.m
//  OwnTracksGW
//
//  Created by Christoph Krey on 18.09.14.
//  Copyright (c) 2014 christophkrey. All rights reserved.
//

#import "VehicleVC.h"
#import "Vehicle+Create.h"

@interface VehicleVC ()
@property (weak, nonatomic) IBOutlet UILabel *UIInfo;
@property (weak, nonatomic) IBOutlet UILabel *UITime;
@property (weak, nonatomic) IBOutlet UILabel *UISpeed;
@property (weak, nonatomic) IBOutlet UILabel *UIAltitude;
@property (weak, nonatomic) IBOutlet UILabel *UICoordinate;
@property (weak, nonatomic) IBOutlet UILabel *UICourse;
@property (weak, nonatomic) IBOutlet UITextView *UILocation; //
@property (weak, nonatomic) IBOutlet UILabel *UIEvent;
@property (weak, nonatomic) IBOutlet UILabel *UIAlarm;
@property (weak, nonatomic) IBOutlet UILabel *UIVext;
@property (weak, nonatomic) IBOutlet UILabel *UIVbatt;
@property (weak, nonatomic) IBOutlet UILabel *UIGPIO;
@property (weak, nonatomic) IBOutlet UILabel *UIStatus;
@property (weak, nonatomic) IBOutlet UILabel *UIDist;
@property (weak, nonatomic) IBOutlet UILabel *UITrip;
@property (weak, nonatomic) IBOutlet UILabel *UITopic;
@property (weak, nonatomic) IBOutlet UILabel *UIStart;
@property (weak, nonatomic) IBOutlet UILabel *UIVersion;
@property (weak, nonatomic) IBOutlet UILabel *UIIMEI;
@property (weak, nonatomic) IBOutlet UILabel *UITrigger;
@property (strong, nonatomic) NSArray *keysToObserve;
@end

@implementation VehicleVC

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    self.keysToObserve = @[
                           @"tst",
                           @"status",
                           @"lon",
                           @"lat",
                           @"vbatt",
                           @"vext",
                           @"info",
                           @"alarm",
                           @"event",
                           @"gpio1",
                           @"gpio3",
                           @"gpio2",
                           @"gpio5",
                           @"gpio7",
                           @"cog",
                           @"vel",
                           @"alt",
                           @"dist",
                           @"trip"
                           ];
    
    for (NSString *keyToObserve in self.keysToObserve) {
        [self.vehicle addObserver:self
                       forKeyPath:keyToObserve
                          options:NSKeyValueObservingOptionNew
                          context:nil];
    }
    [self observeValueForKeyPath:nil ofObject:nil change:nil context:nil]; // to set values initially
}

- (void)viewWillDisappear:(BOOL)animated {
    for (NSString *keyToObserve in self.keysToObserve) {
        [self.vehicle removeObserver:self forKeyPath:keyToObserve];
    }
    [super viewWillDisappear:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    self.title = [NSString stringWithFormat:@"Detail - %@", [self.vehicle tid]];
    
    self.UIInfo.text = self.vehicle.info;
    self.UIEvent.text = self.vehicle.event;
    self.UIAlarm.text = self.vehicle.alarm;
    
    self.UIVbatt.text = [NSString stringWithFormat:@"%.1f V", [self.vehicle.vbatt doubleValue]];
    self.UIVext.text = [NSString stringWithFormat:@"%.1f V", [self.vehicle.vext doubleValue]];
    self.UIGPIO.text = @"";
    if ([self.vehicle.gpio1 boolValue]) {
        self.UIGPIO.text = [self.UIGPIO.text stringByAppendingString:@"1 "];
    }
    if ([self.vehicle.gpio3 boolValue]) {
        self.UIGPIO.text = [self.UIGPIO.text stringByAppendingString:@"3 "];
    }
    if ([self.vehicle.gpio2 boolValue]) {
        self.UIGPIO.text = [self.UIGPIO.text stringByAppendingString:@"2 "];
    }
    if ([self.vehicle.gpio5 boolValue]) {
        self.UIGPIO.text = [self.UIGPIO.text stringByAppendingString:@"5 "];
    }
    if ([self.vehicle.gpio7 boolValue]) {
        self.UIGPIO.text = [self.UIGPIO.text stringByAppendingString:@"7 "];
    }
    switch ([self.vehicle.status intValue]) {
        case -1:
            self.UIStatus.text = @"☒ off";
            break;
        case 1:
            self.UIStatus.text = @"☑︎ on";
            break;
        case 0:
        default:
            self.UIStatus.text = @"∅ disconnected";
            break;
            
    }
    self.UIDist.text = [NSString stringWithFormat:@"%.0f m", [self.vehicle.dist doubleValue]];
    self.UITrip.text = [NSString stringWithFormat:@"%.0f km", [self.vehicle.trip doubleValue] / 1000];
    self.UITopic.text = self.vehicle.topic;
    self.UIStart.text = [NSDateFormatter localizedStringFromDate:self.vehicle.start
                                                       dateStyle:NSDateFormatterShortStyle
                                                       timeStyle:NSDateFormatterShortStyle];
    self.UIVersion.text = self.vehicle.version;
    self.UIIMEI.text = self.vehicle.imei;
    
    self.UIAltitude.text = [NSString stringWithFormat:@"%.0f m",
                            [self.vehicle.alt doubleValue]];
    self.UICoordinate.text = [NSString stringWithFormat:@"%.6f,%.6f",
                              [self.vehicle.lat doubleValue],
                              [self.vehicle.lon doubleValue]];
    self.UICourse.text = [NSString stringWithFormat:@"%.0f°", [self.vehicle.cog doubleValue]];
    self.UISpeed.text = [NSString stringWithFormat:@"%.0f km/h", [self.vehicle.vel doubleValue]];
    self.UITime.text = [NSDateFormatter localizedStringFromDate:self.vehicle.tst
                                                      dateStyle:NSDateFormatterShortStyle
                                                      timeStyle:NSDateFormatterShortStyle];
    
    // Trigger
    NSURL *bundleURL = [[NSBundle mainBundle] bundleURL];
    NSURL *plistURL = [bundleURL URLByAppendingPathComponent:@"Triggers.plist"];
    
    NSDictionary *triggers = [NSDictionary dictionaryWithContentsOfURL:plistURL];
    NSString *triggerText = triggers[self.vehicle.trigger];
    self.UITrigger.text = triggerText ? triggerText : self.vehicle.trigger;
    
    
    // Location
    if (!keyPath || [keyPath isEqualToString:@"lat"] || [keyPath isEqualToString:@"lon"]) {
        self.UILocation.text = @"reverse geocoding...";
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[self.vehicle.lat doubleValue] longitude:[self.vehicle.lon doubleValue]];
        [geocoder reverseGeocodeLocation:location completionHandler:
         ^(NSArray *placemarks, NSError *error) {
             if ([placemarks count] > 0) {
                 CLPlacemark *placemark = placemarks[0];
                 NSArray *address = placemark.addressDictionary[@"FormattedAddressLines"];
                 if (address && [address count] >= 1) {
                     self.UILocation.text = address[0];
                     for (int i = 1; i < [address count]; i++) {
                         self.UILocation.text = [NSString stringWithFormat:@"%@, %@",
                                                 self.UILocation.text, address[i]];
                     }
                     [self.UILocation setNeedsDisplay];
                 }
             }
         }];
    }
}

@end
