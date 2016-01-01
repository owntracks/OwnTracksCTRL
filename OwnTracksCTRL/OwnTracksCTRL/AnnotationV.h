//
//  OPAnnotationView.h
//  OwnTracksGW
//
//  Created by Christoph Krey on 16.09.14.
//  Copyright © 2014-2016 christophkrey. All rights reserved.
//


#import "Vehicle+Create.h"

#ifndef CTRLTV

#import <MapKit/MapKit.h>
@interface AnnotationV : MKAnnotationView
- (UIImage *)getImage;
@end

#else

#import <UIKit/UIKit.h>

@interface AnnotationV : UIView
@property (strong, nonatomic) Vehicle * annotation;
- (UIImage *)getImage;
@end

#endif

