//
//  OPAnnotationView.m
//  OwnTracksGW
//
//  Created by Christoph Krey on 16.09.14.
//  Copyright (c) 2014 christophkrey. All rights reserved.
//

#import "AnnotationV.h"
#import "Vehicle+Create.h"

@implementation AnnotationV

#define CIRCLE_SIZE 40.0
#define CIRCLE_COLOR [UIColor yellowColor]

#define FENCE_ON_COLOR [UIColor greenColor]
#define FENCE_OFF_COLOR [UIColor blueColor]
#define FENCE_ERROR_COLOR [UIColor redColor]
#define FENCE_FACTOR 0.125

#define ID_COLOR [UIColor blackColor]
#define ID_FONTFACTOR 0.5
#define ID_INSET 3.0

#define COURSE_COLOR [UIColor blueColor]
#define COURSE_WIDTH 10.0

#define TACHO_COLOR [UIColor redColor]
#define TACHO_SCALE 30.0
#define TACHO_MAX 540.0

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
        self.frame = CGRectMake(0, 0, CIRCLE_SIZE, CIRCLE_SIZE);
    }
    return self;
}

- (UIImage *)getImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(CIRCLE_SIZE, CIRCLE_SIZE), NO, 0.0);
    [self drawRect:CGRectMake(0, 0, CIRCLE_SIZE, CIRCLE_SIZE)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)drawRect:(CGRect)rect
{
    // It is all within a circle
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:rect];
    [circle addClip];
    
    
    // Yellow or Photo background
    [CIRCLE_COLOR setFill];
    [circle fill];
    
    // Tachometer logarithmic
    
    Vehicle *vehicle = nil;
    if ([self.annotation isKindOfClass:[Vehicle class]]) {
        vehicle = (Vehicle *)self.annotation;
    }
    
    if (vehicle
        && [vehicle.status intValue] == 1
        && ![vehicle.trigger isEqualToString:@"L"]
        && ![vehicle.trigger isEqualToString:@"T"]) {
        double speed = [vehicle.vel doubleValue];
        if (speed > 0) {
            UIBezierPath *tacho = [[UIBezierPath alloc] init];
            [tacho moveToPoint:CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + rect.size.height / 2)];
            [tacho addLineToPoint:CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + rect.size.height)];
            [tacho appendPath:[UIBezierPath bezierPathWithArcCenter:CGPointMake(rect.size.width / 2, rect.size.height / 2)
                                                             radius:rect.size.width / 2
                                                         startAngle:M_PI_2
                                                           endAngle:M_PI_2 +
                               2 * M_PI *log(1 + speed / TACHO_SCALE) / log (1 + TACHO_MAX / TACHO_SCALE)
                                                          clockwise:true]];
            [tacho addLineToPoint:CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + rect.size.height / 2)];
            [tacho closePath];
            
            [TACHO_COLOR setFill];
            [tacho fill];
            [CIRCLE_COLOR setStroke];
            [tacho setLineWidth:1.0];
            [tacho stroke];
        }
    }
    
    // ID
    if (vehicle) {
        NSString *tid = vehicle.tid;
        UIFont *font = [UIFont boldSystemFontOfSize:rect.size.width * ID_FONTFACTOR];
        NSDictionary *attributes = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName: ID_COLOR};
        CGRect boundingRect = [tid boundingRectWithSize:rect.size options:0 attributes:attributes context:nil];
        CGRect textRect = CGRectMake(rect.origin.x + (rect.size.width - boundingRect.size.width) / 2,
                                     rect.origin.y + (rect.size.height - boundingRect.size.height) / 2,
                                     boundingRect.size.width, boundingRect.size.height);
        
        [tid drawInRect:textRect withAttributes:attributes];
    }
    
    // FENCE
    if (vehicle) {
        switch ([vehicle.status intValue]) {
            case 1:
                [FENCE_ON_COLOR setStroke];
                break;
            case -1:
                [FENCE_OFF_COLOR setStroke];
                break;
            default:
                [FENCE_ERROR_COLOR setStroke];
                break;
        }
        [circle setLineWidth:rect.size.width * FENCE_FACTOR];
        [circle stroke];
    }
    
    // Course
    if (vehicle
        && [vehicle.status intValue] == 1
        && ![vehicle.trigger isEqualToString:@"L"]
        && ![vehicle.trigger isEqualToString:@"T"]) {
            double cog = [vehicle.cog doubleValue];
        if (cog >= 0) {
            UIBezierPath *course = [UIBezierPath bezierPathWithOvalInRect:
                                    CGRectMake(
                                               rect.origin.x + rect.size.width / 2 + rect.size.width / 2 * cos((cog -90 )/ 360 * 2 * M_PI) - COURSE_WIDTH / 2,
                                               rect.origin.y + rect.size.height / 2 + rect.size.width / 2 * sin((cog -90 )/ 360 * 2 * M_PI) - COURSE_WIDTH / 2,
                                               COURSE_WIDTH,
                                               COURSE_WIDTH
                                               )
                                    ];
            [COURSE_COLOR setFill];
            [course fill];
            [CIRCLE_COLOR setStroke];
            [course setLineWidth:1.0];
            [course stroke];
        }
    }
    
    [UIView animateWithDuration:0.5
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.bounds = CGRectMake(0, 0, CIRCLE_SIZE * 2, CIRCLE_SIZE * 2);
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:0.5
                                          animations:^{
                                              self.bounds = CGRectMake(0, 0, CIRCLE_SIZE, CIRCLE_SIZE);
                                          }
                                          completion:nil];
                     }];
}


@end
