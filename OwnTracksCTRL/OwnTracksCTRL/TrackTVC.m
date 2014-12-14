//
//  TrackTVC.m
//  OwnTracksCTRL
//
//  Created by Christoph Krey on 13.12.14.
//  Copyright (c) 2014 OwnTracks. All rights reserved.
//

#import "TrackTVC.h"

@interface NSString (Descend)
- (NSComparisonResult)descendingLocalizedCompare:(NSString *)aString;
@end

@implementation NSString (Descend)


- (NSComparisonResult)descendingLocalizedCompare:(NSString *)aString {
    return [self localizedCaseInsensitiveCompare:aString] * -1;
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
                    NSString *dateString = [NSDateFormatter localizedStringFromDate:date
                                                                          dateStyle:NSDateFormatterShortStyle
                                                                          timeStyle:NSDateFormatterNoStyle];
                    NSMutableArray *dateTrack = [tracks[dateString] mutableCopy];
                    if (!dateTrack) {
                        dateTrack = [[NSMutableArray alloc] init];
                    }
                    [dateTrack addObject:trackpoint];
                    tracks[dateString] = dateTrack;
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
        NSArray *sortedKeys = [self.tracks.allKeys sortedArrayUsingSelector:@selector(descendingLocalizedCompare:)];
        return sortedKeys[section];
    } else {
        return nil;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.tracks) {
        NSArray *sortedKeys = [self.tracks.allKeys sortedArrayUsingSelector:@selector(descendingLocalizedCompare:)];
        return sortedKeys;
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.tracks && self.tracks.count > section) {
        NSArray *sortedKeys = [self.tracks.allKeys sortedArrayUsingSelector:@selector(descendingLocalizedCompare:)];
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
        NSArray *sortedKeys = [self.tracks.allKeys sortedArrayUsingSelector:@selector(descendingLocalizedCompare:)];
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
                     NSArray *address = placemark.addressDictionary[@"FormattedAddressLines"];
                     if (address && [address count] >= 1) {
                         cell.detailTextLabel.text = address[0];
                         for (int i = 1; i < [address count]; i++) {
                             cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@",
                                                          cell.detailTextLabel.text, address[i]];
                         }
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
                 }
             }];
        }
    }
}
@end
