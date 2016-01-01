//
//  MapPopOverSegue.m
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 16.10.14.
//  Copyright © 2014-2016 OwnTracks. All rights reserved.
//

#import "MapPopOverSegue.h"

@interface MapPopOverSegue()
@property (strong, nonatomic) id observer;
@end

@implementation MapPopOverSegue

#ifndef CTRLTV
- (void)perform {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    self.observer = [center addObserverForName:UIDeviceOrientationDidChangeNotification
                                        object:nil
                                         queue:nil
                                    usingBlock:^(NSNotification *note) {
                                        [self.popoverController dismissPopoverAnimated:true];
                                    }];
    [self.popoverController presentPopoverFromBarButtonItem:self.item
                                   permittedArrowDirections:UIPopoverArrowDirectionUp
                                                   animated:true];
}

- (void)dealloc {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self.observer];
}
#endif

@end
