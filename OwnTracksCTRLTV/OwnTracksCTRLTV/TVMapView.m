//
//  TVMapView.m
//  OwnTracksCTRLTV
//
//  Created by Christoph Krey on 06.10.15.
//  Copyright © 2015-2016 OwnTracks. All rights reserved.
//

#import "TVMapView.h"
#import "AnnotationV.h"
#import <Foundation/Foundation.h>

#ifndef CTRLTV
#import <CocoaLumberjack/CocoaLumberjack.h>
#else
#define DDLogVerbose NSLog
#define DDLogError NSLog
#endif


@interface CLLocation(Bearing)
- (CLLocationDirection)bearingToLocation:(CLLocation *)location;

@end

@implementation CLLocation (Bearing)

- (CLLocationDirection)bearingToLocation:(CLLocation *)location {
    double f1 = self.coordinate.latitude / 90.0 * M_PI_2;
    double f2 = location.coordinate.latitude / 90. * M_PI_2;
    double l1 = self.coordinate.longitude / 90. * M_PI_2;
    double l2 = location.coordinate.longitude / 90. * M_PI_2;

    double y = sin(l2 - l1) * cos(f2);
    double x = cos(f1) * sin(f2) - sin(f1) * cos(f2) * cos(l2 - l1);
    CLLocationDirection bearing = atan2(y, x) / M_PI_2 * 90.0;
    return bearing;
}
@end

@implementation TVMapView

#ifndef CTRLTV
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#endif

- (void)setVehicles:(NSArray *)vehicles {
    _vehicles = vehicles;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    if (!CLLocationCoordinate2DIsValid(self.centerLocation) || (self.centerLocation.latitude == 0.0 && self.centerLocation.longitude == 0.0)) {
        self.centerLocation = CLLocationCoordinate2DMake(51.2, 6.7);
    }

    self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:1.0];

    CGRect squareRect = CGRectMake((rect.size.width - rect.size.height) / 2, 0, rect.size.height, rect.size.height);
    DDLogVerbose(@"squareRect %f %f", squareRect.origin.x, squareRect.size.height);
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:squareRect];


    [[UIColor blueColor] setFill];
    [circle fill];

    // calculate max distance from center
    CLLocationDistance maxDistance = 0;

    CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:self.centerLocation.latitude longitude:self.centerLocation.longitude];
    DDLogVerbose(@"%@ lat %f, lon %f", @"center", centerLocation.coordinate.latitude, centerLocation.coordinate.longitude);

    for (Vehicle *vehicle in self.vehicles) {
        CLLocation *vehicleLocation = [[CLLocation alloc] initWithLatitude:[vehicle.lat doubleValue] longitude:[vehicle.lon doubleValue]];
        CLLocationDistance distance = [vehicleLocation distanceFromLocation:centerLocation];
        DDLogVerbose(@"%@ lat %f, lon %f, distance %f", [vehicle tid], vehicleLocation.coordinate.latitude, vehicleLocation.coordinate.longitude, distance);
        if (distance > maxDistance) {
            maxDistance = distance;
        }
    }

    DDLogVerbose(@"maxDistance %f", maxDistance);
    UIFont *font = [UIFont fontWithName:@"Courier" size:36.0];

    NSDictionary *attrsDictionary = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: [UIColor whiteColor]
                                      };

    NSString *scaleString = [NSString stringWithFormat:@"< %.0f km >", maxDistance / 1000 * 2];
    NSAttributedString *scale = [[NSAttributedString alloc]
                                 initWithString:scaleString
                                 attributes:attrsDictionary];

    CGRect scaleRect = [scale boundingRectWithSize:squareRect.size
                                           options:0
                                           context:nil];

    [scale drawInRect:CGRectMake(squareRect.size.width / 2 - scaleRect.size.width / 2,
                                 squareRect.size.height / 2 - scaleRect.size.height / 2,
                                 scaleRect.size.width, scaleRect.size.height)];
    

    for (Vehicle *vehicle in self.vehicles) {
        AnnotationV *annotationV = [[AnnotationV alloc] init];
        annotationV.annotation = vehicle;
        UIImage *image = [annotationV getImage];

        CLLocation *vehicleLocation = [[CLLocation alloc] initWithLatitude:[vehicle.lat doubleValue] longitude:[vehicle.lon doubleValue]];
        CLLocationDistance distance = [vehicleLocation distanceFromLocation:centerLocation];
        CLLocationDirection bearing = [vehicleLocation bearingToLocation:centerLocation];

        double r = distance / maxDistance * squareRect.size.height / 2;
        CGPoint point = CGPointMake(squareRect.origin.x + squareRect.size.width / 2 - r * cos((bearing - 90.0 )/ 360 * 2 * M_PI) - image.size.width / 2,
                                    squareRect.origin.y + squareRect.size.height / 2 - r * sin((bearing - 90.0 )/ 360 * 2 * M_PI)  - image.size.height / 2);

        DDLogVerbose(@"%@ distance %f, bearing %f, point %f, %f", [vehicle tid], distance, bearing, point.x, point.y);

        [image drawAtPoint:point blendMode:kCGBlendModeNormal alpha:1.0];
    }
}



@end
