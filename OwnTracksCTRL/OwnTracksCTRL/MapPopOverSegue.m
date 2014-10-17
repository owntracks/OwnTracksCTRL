//
//  MapPopOverSegue.m
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 16.10.14.
//  Copyright (c) 2014 OwnTracks. All rights reserved.
//

#import "MapPopOverSegue.h"

@implementation MapPopOverSegue

- (void)perform {
    [self.popoverController presentPopoverFromRect:self.rect
                                            inView:self.view
                          permittedArrowDirections:UIPopoverArrowDirectionLeft
                                          animated:true];
}

@end
