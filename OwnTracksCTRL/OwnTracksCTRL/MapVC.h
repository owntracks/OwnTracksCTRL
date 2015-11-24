//
//  OPMapViewController.h
//  OwnTracksGW
//
//  Created by Christoph Krey on 16.09.14.
//  Copyright (c) 2014 christophkrey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Vehicle+Create.h"

#ifndef CTRLTV

#import <MapKit/MapKit.h>

@interface MapVC : UIViewController <MKMapViewDelegate, NSFetchedResultsControllerDelegate>
+ (void)centerOn:(Vehicle *)vehicle;
- (void)centerOn:(Vehicle *)vehicle;
@end

#else

@interface MapVC : UIViewController <NSFetchedResultsControllerDelegate, CLLocationManagerDelegate>
@end

#endif
