//
//  MapPopOverSegue.h
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 16.10.14.
//  Copyright (c) 2014 OwnTracks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MapPopOverSegue : UIStoryboardPopoverSegue
@property (nonatomic) CGRect rect;
@property (weak, nonatomic) UIView *view;
@end
