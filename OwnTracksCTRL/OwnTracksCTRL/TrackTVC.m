//
//  TrackTVC.m
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 13.12.14.
//  Copyright © 2014-2016 OwnTracks. All rights reserved.
//

#import "TrackTVC.h"
#ifndef CTRLTV
#import <AddressBookUI/AddressBookUI.h>
#endif

@interface NSDate (Descend)
- (NSComparisonResult)descendingCompare:(NSDate *)aDate;
@end

@implementation NSDate (Descend)
- (NSComparisonResult)descendingCompare:(NSDate *)aDate {
    if ([self timeIntervalSince1970] == [aDate timeIntervalSince1970]) {
        return NSOrderedSame;
    } else if ([self timeIntervalSince1970] < [aDate timeIntervalSince1970]) {
        return NSOrderedDescending;
    } else {
        return NSOrderedAscending;
    }
}
@end

@interface TrackTVC ()
@property (strong, nonatomic) NSDictionary *tracks;
@end

@implementation TrackTVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = [NSString stringWithFormat:@"Track - %@", self.vehicle.tid];
    self.tableView.sectionIndexMinimumDisplayRowCount = 1;
    self.tracks = nil;
    NSDictionary *dictionary = nil;
    if (self.vehicle.track) {
        NSError *error;
        dictionary = [NSJSONSerialization JSONObjectWithData:self.vehicle.track options:0 error:&error];
        if (dictionary) {
            NSArray *track = dictionary[@"track"];
            if (track && [track count] > 0) {
                NSMutableDictionary *tracks = [[NSMutableDictionary alloc] init];
                for (NSDictionary *trackpoint in track) {
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[trackpoint[@"tst"] doubleValue]];
                    
                    // build day = date @ 00:00:00,0 hours
                    NSDateComponents *components = [[NSCalendar currentCalendar] componentsInTimeZone:[NSTimeZone defaultTimeZone] fromDate:date];
                    components.hour = 0;
                    components.minute = 0;
                    components.second = 0;
                    components.nanosecond = 0;
                    NSDate *day = [components date];
                    
                    NSMutableArray *dateTrack = [tracks[day] mutableCopy];
                    if (!dateTrack) {
                        dateTrack = [[NSMutableArray alloc] init];
                    }
                    [dateTrack addObject:trackpoint];
                    tracks[day] = dateTrack;
                }
                self.tracks = tracks;
            }
        }
    }
    [self.tableView reloadData];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tracks.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.tracks && self.tracks.count > section) {
        NSArray *sortedKeys = [self.tracks.allKeys sortedArrayUsingSelector:@selector(descendingCompare:)];
        NSDate *date = sortedKeys[section];
        return [NSDateFormatter localizedStringFromDate:date
                                              dateStyle:NSDateFormatterShortStyle
                                              timeStyle:NSDateFormatterNoStyle];
    } else {
        return nil;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.tracks) {
        NSArray *sortedKeys = [self.tracks.allKeys sortedArrayUsingSelector:@selector(descendingCompare:)];
        NSMutableArray *indices = [[NSMutableArray alloc] init];
        for (NSDate *date in sortedKeys) {
            [indices addObject:[NSString stringWithFormat:@"%ld", (long)[[NSCalendar currentCalendar] component:NSCalendarUnitDay fromDate:date]]];
        }
        return indices;
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.tracks && self.tracks.count > section) {
        NSArray *sortedKeys = [self.tracks.allKeys sortedArrayUsingSelector:@selector(descendingCompare:)];
        NSArray *track = self.tracks[sortedKeys[section]];
        return track.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"track" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath highlight:false];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath highlight:(BOOL)highlight
{
    if (self.tracks && self.tracks.count > indexPath.section) {
        NSArray *sortedKeys = [self.tracks.allKeys sortedArrayUsingSelector:@selector(descendingCompare:)];
        NSArray *track = self.tracks[sortedKeys[indexPath.section]];
        if (track.count > indexPath.row) {
            NSDictionary *trackpoint = track[indexPath.row];
            
            cell.textLabel.text = [NSString stringWithFormat:@"%@",
                                   [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:[trackpoint[@"tst"] doubleValue]]
                                                                  dateStyle:NSDateFormatterNoStyle
                                                                  timeStyle:NSDateFormatterShortStyle]
                                   ];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.6f,%.6f",
                                         [trackpoint[@"lat"] doubleValue],
                                         [trackpoint[@"lon"] doubleValue]
                                         ];
            CLGeocoder *geocoder = [[CLGeocoder alloc] init];
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[trackpoint[@"lat"] doubleValue] longitude:[trackpoint[@"lon"] doubleValue]];
            [geocoder reverseGeocodeLocation:location completionHandler:
             ^(NSArray *placemarks, NSError *error) {
                 if ([placemarks count] > 0) {
                     CLPlacemark *placemark = placemarks[0];
#ifndef CTRLTV
                     NSString *address = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
#else
                     NSString *address = [NSString stringWithFormat:@"%@ %@ %@ %@ %@",
                                          placemark.subThoroughfare,
                                          placemark.thoroughfare,
                                          placemark.postalCode,
                                          placemark.administrativeArea,
                                          placemark.country];
#endif
                     cell.detailTextLabel.text = [address stringByReplacingOccurrencesOfString:@"\n"
                                                                                    withString:@", "];
                     [cell.detailTextLabel setNeedsDisplay];
                     cell.textLabel.text = [NSString stringWithFormat:@"%@ (%.6f,%.6f)",
                                            [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:[trackpoint[@"tst"] doubleValue]]
                                                                           dateStyle:NSDateFormatterNoStyle
                                                                           timeStyle:NSDateFormatterShortStyle],
                                            [trackpoint[@"lat"] doubleValue],
                                            [trackpoint[@"lon"] doubleValue]
                                            ];
                     [cell.textLabel setNeedsDisplay];
                 }
             }];
        }
    }
}
@end
