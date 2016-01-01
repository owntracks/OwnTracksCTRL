//
//  TVMapView.h
//  OwnTracksCTRLTV
//
//  Created by Christoph Krey on 06.10.15.
//  Copyright © 2015-2016 OwnTracks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Vehicle+Create.h"

@interface TVMapView : UIView
@property (strong, nonatomic) NSArray *vehicles;
@property (nonatomic) CLLocationCoordinate2D centerLocation;


@end
