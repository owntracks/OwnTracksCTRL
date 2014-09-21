//
//  OPMapViewController.h
//  OwnTracksGW
//
//  Created by Christoph Krey on 16.09.14.
//  Copyright (c) 2014 christophkrey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Vehicle+Create.h"


@interface MapVC : UIViewController <MKMapViewDelegate, NSFetchedResultsControllerDelegate, UIActionSheetDelegate>
- (void)centerOn:(Vehicle *)vehicle;
@end
