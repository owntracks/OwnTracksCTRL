//
//  OPMapViewController.h
//  OwnTracksGW
//
//  Created by Christoph Krey on 16.09.14.
//  Copyright © 2014-2016 christophkrey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Vehicle.h"

#import <MapKit/MapKit.h>

@interface MapVC : UIViewController <MKMapViewDelegate, NSFetchedResultsControllerDelegate>
+ (void)centerOn:(Vehicle *)vehicle;
- (void)centerOn:(Vehicle *)vehicle;
@end
