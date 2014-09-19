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
@property (weak, nonatomic) IBOutlet UITextField *UIInfo;
@property (weak, nonatomic) IBOutlet UITextField *UITime;
@property (weak, nonatomic) IBOutlet UITextField *UISpeed;
@property (weak, nonatomic) IBOutlet UITextField *UIAltitude;
@property (weak, nonatomic) IBOutlet UITextField *UICoordinate;
@property (weak, nonatomic) IBOutlet UITextField *UICourse;
@property (weak, nonatomic) IBOutlet UITextView *UILocation;

@end

@implementation VehicleVC
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = [self.vehicle tid];
    self.UIAltitude.text = [NSString stringWithFormat:@"%.0f", [self.vehicle.alt doubleValue]];
    self.UICoordinate.text = [NSString stringWithFormat:@"%g,%g", [self.vehicle.lat doubleValue], [self.vehicle.lon doubleValue]];
    self.UICourse.text = [NSString stringWithFormat:@"%.0f", [self.vehicle.cog doubleValue]];
    self.UIInfo.text = self.vehicle.info;
    self.UISpeed.text = [NSString stringWithFormat:@"%.0f", [self.vehicle.vel doubleValue]];
    self.UITime.text = [NSString stringWithFormat:@"%@", self.vehicle.tst];

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
