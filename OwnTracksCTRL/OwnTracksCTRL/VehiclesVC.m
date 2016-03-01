//
//  OPMasterViewController.m
//  OwnTracksGW
//
//  Created by Christoph Krey on 29.05.14.
//  Copyright © 2014-2016 christophkrey. All rights reserved.
//

#import "VehiclesVC.h"
#import "AnnotationV.h"
#import "Vehicle+Create.h"
#import "AppDelegate.h"
#import "VehicleVC.h"
#import <AddressBookUI/AddressBookUI.h>

#ifndef CTRLTV
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "MapVC.h"
#else
#define DDLogVerbose NSLog
#define DDLogError NSLog
#endif

@interface VehiclesVC ()
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation VehiclesVC

#ifndef CTRLTV
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#endif


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = @"OwnTracksCTRL - Vehicles";
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"vehicle" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath highlight:false];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [NSObject cancelPreviousPerformRequestsWithTarget:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"context save: %@", error);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *tableViewCell = (UITableViewCell *)sender;
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tableViewCell];
        
        if ([[segue identifier] isEqualToString:@"setVehicleForDetail:"]) {
            Vehicle *vehicle = [[self fetchedResultsController] objectAtIndexPath:indexPath];
            [[segue destinationViewController] performSelector:@selector(setVehicle:) withObject:vehicle];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
#ifndef CTRLTV
    Vehicle *vehicle = (Vehicle *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UIViewController *vc = self.navigationController.viewControllers[[self.navigationController.viewControllers count] - 2];
    if ([vc respondsToSelector:@selector(centerOn:)]) {
        [vc performSelector:@selector(centerOn:) withObject:vehicle];
    }
    [self.navigationController popViewControllerAnimated:true];
#endif
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Vehicle"
                                              inManagedObjectContext:appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"tid" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *aFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:appDelegate.managedObjectContext
                                          sectionNameKeyPath:nil
                                                   cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        DDLogError(@"fetchedResultsController performFetch: %@", error);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath highlight:(BOOL)highlight
{
    Vehicle *vehicle = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = vehicle.info ? vehicle.info : vehicle.topic;

#ifndef CTRLTV
    cell.detailTextLabel.text = [vehicle subtitle];
#else
    cell.detailTextLabel.text = @"reverse geocoding...";
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[vehicle.lat doubleValue] longitude:[vehicle.lon doubleValue]];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
         if ([placemarks count] > 0) {
             CLPlacemark *placemark = placemarks[0];
             cell.detailTextLabel.text = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
         }
     }];
#endif

    AnnotationV *annotationView = [[AnnotationV alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    annotationView.annotation = vehicle;
    cell.imageView.image = [annotationView getImage];
    
    if (highlight) {
        [UIView animateWithDuration:0.2
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             cell.contentView.backgroundColor = [UIColor greenColor] ;
                         }
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:0.2
                                              animations:^{
                                                  cell.contentView.backgroundColor = [UIColor whiteColor];
                                              }
                                              completion:nil];
                         }];
    }
}

@end
