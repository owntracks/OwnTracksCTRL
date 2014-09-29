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
@property (weak, nonatomic) IBOutlet UITextField *UIInfo; //
@property (weak, nonatomic) IBOutlet UITextField *UITime; //
@property (weak, nonatomic) IBOutlet UITextField *UISpeed; //
@property (weak, nonatomic) IBOutlet UITextField *UIAltitude; //
@property (weak, nonatomic) IBOutlet UITextField *UICoordinate; //
@property (weak, nonatomic) IBOutlet UITextField *UICourse; //
@property (weak, nonatomic) IBOutlet UITextView *UILocation; //
@property (weak, nonatomic) IBOutlet UITextField *UIEvent; //
@property (weak, nonatomic) IBOutlet UITextField *UIAlarm; //
@property (weak, nonatomic) IBOutlet UITextField *UIVext; //
@property (weak, nonatomic) IBOutlet UITextField *UIVbatt; //
@property (weak, nonatomic) IBOutlet UISwitch *UIGPIO1;//
@property (weak, nonatomic) IBOutlet UISwitch *UIGPIO3;//
@property (weak, nonatomic) IBOutlet UISwitch *UIGPIO7;//
@property (weak, nonatomic) IBOutlet UISegmentedControl *UIStatus; //
@property (weak, nonatomic) IBOutlet UITextField *UIDist; //
@property (weak, nonatomic) IBOutlet UITextField *UITrip; //
@property (weak, nonatomic) IBOutlet UITextField *UITopic; //
@property (weak, nonatomic) IBOutlet UITextField *UIStart; //
@property (weak, nonatomic) IBOutlet UITextField *UIVersion;
@property (weak, nonatomic) IBOutlet UITextField *UIIMEI;
@property (weak, nonatomic) IBOutlet UITextField *UITrigger;

@end

@implementation VehicleVC
- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    self.title = [NSString stringWithFormat:@"Detail - %@", [self.vehicle tid]];
    
    self.UIEvent.text = self.vehicle.event;
    self.UIAlarm.text = self.vehicle.alarm;
    self.UIVbatt.text = [NSString stringWithFormat:@"%.1fV", [self.vehicle.vbatt doubleValue]];
    self.UIVext.text = [NSString stringWithFormat:@"%.1fV", [self.vehicle.vext doubleValue]];
    self.UIGPIO1.on = [self.vehicle.gpio1 boolValue];
    self.UIGPIO3.on = [self.vehicle.gpio3 boolValue];
    self.UIGPIO7.on = [self.vehicle.gpio7 boolValue];
    self.UIStatus.selectedSegmentIndex = [self.vehicle.status intValue] + 1;
    self.UIDist.text = [NSString stringWithFormat:@"%.0fm", [self.vehicle.dist doubleValue]];
    self.UITrip.text = [NSString stringWithFormat:@"%.0fm", [self.vehicle.trip doubleValue]];
    self.UITopic.text = self.vehicle.topic;
    self.UIStart.text = [NSDateFormatter localizedStringFromDate:self.vehicle.start
                                                       dateStyle:NSDateFormatterShortStyle
                                                       timeStyle:NSDateFormatterShortStyle];
    self.UIVersion.text = self.vehicle.version;
    self.UIIMEI.text = self.vehicle.imei;

    self.UIAltitude.text = [NSString stringWithFormat:@"%.0fm",
                            [self.vehicle.alt doubleValue]];
    self.UICoordinate.text = [NSString stringWithFormat:@"%g,%g",
                              [self.vehicle.lat doubleValue],
                              [self.vehicle.lon doubleValue]];
    self.UICourse.text = [NSString stringWithFormat:@"%.0f°", [self.vehicle.cog doubleValue]];
    self.UIInfo.text = self.vehicle.info;
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

@end
