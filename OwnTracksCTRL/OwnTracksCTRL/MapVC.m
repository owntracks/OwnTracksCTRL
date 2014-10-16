//
//  OPMapViewController.m
//  OwnTracksGW
//
//  Created by Christoph Krey on 16.09.14.
//  Copyright (c) 2014 christophkrey. All rights reserved.
//

#import "MapVC.h"
#import "Vehicle+Create.h"
#import "AnnotationV.h"
#import "AppDelegate.h"
#import "VehicleVC.h"

@interface MapVC ()
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UIConnection;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UITracking;

@end

@implementation MapVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.mapView.delegate = self;
    for (Vehicle *vehicle in self.fetchedResultsController.fetchedObjects) {
        [self.mapView addAnnotation:vehicle];
    }
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate addObserver:self forKeyPath:@"connectedTo"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.fetchedResultsController = nil;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate removeObserver:self forKeyPath:@"connectedTo"
                     context:nil];
    [super viewWillDisappear:animated];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    } else {
        if ([annotation isKindOfClass:[Vehicle class]]) {
            Vehicle *vehicle = (Vehicle *)annotation;
            MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"Vehicle"];
            if (annotationView) {
                annotationView.annotation = vehicle;
                [annotationView setNeedsDisplay];
            } else {
                annotationView = [[AnnotationV alloc] initWithAnnotation:vehicle reuseIdentifier:@"Vehicle"];
            }
            annotationView.canShowCallout = YES;
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            return annotationView;
        }
        return nil;
    }
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    [self performSegueWithIdentifier:@"showDetail:" sender:view];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showDetail:"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setVehicle:)]) {
            if ([sender isKindOfClass:[MKAnnotationView class]]) {
                MKAnnotationView *annotationView = (MKAnnotationView *)sender;
            [segue.destinationViewController performSelector:@selector(setVehicle:)
                                                  withObject:annotationView.annotation];
            }
        }
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    [self.mapView setCenterCoordinate:[view.annotation coordinate] animated:true];
}

- (void)centerOn:(Vehicle *)vehicle {
    [self.mapView setCenterCoordinate:[vehicle coordinate] animated:TRUE];
    [self.mapView selectAnnotation:vehicle animated:TRUE];
}


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
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    //
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    //
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    id <MKAnnotation> annotation = (id <MKAnnotation>)anObject;
    id <MKAnnotation> selectedAnnotation = nil;
    NSArray *selectedAnnotations = self.mapView.selectedAnnotations;
    if ([selectedAnnotations count] > 0) {
        selectedAnnotation = (id <MKAnnotation>)selectedAnnotations[0];
    }
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.mapView addAnnotation:anObject];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.mapView removeAnnotation:anObject];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.mapView removeAnnotation:anObject];
            [self.mapView addAnnotation:anObject];
            if (annotation == selectedAnnotation) {
                [self.mapView selectAnnotation:annotation animated:true];
            }
            break;
            
        case NSFetchedResultsChangeMove:
            //
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    //
}

#define ACTION_MAP @"Map Modes"
#define ACTION_MQTT @"MQTT Connection"
- (IBAction)TrackingPressed:(UIBarButtonItem *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:ACTION_MAP
                                                             delegate:self
                                                    cancelButtonTitle:([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? @"Cancel" : nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  @"Zoom to selected Vehicle",
                                  @"Show all Vehicles",
                                  @"Standard Map",
                                  @"Satellite Map",
                                  @"Hybrid Map",
                                  nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];

}
- (IBAction)ConnectionPressed:(UIBarButtonItem *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:ACTION_MQTT
                                                             delegate:self
                                                    cancelButtonTitle:([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? @"Cancel" : nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  @"(Re-)Connect",
                                  @"Disconnect",
                                  nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    if ([actionSheet.title isEqualToString:ACTION_MAP]) {
        switch (buttonIndex - actionSheet.firstOtherButtonIndex) {
            case 0:
            {
                if ([[self.mapView selectedAnnotations] count]) {
                    MKMapRect rect;
                    BOOL first = TRUE;
                    
                    for (Vehicle *vehicle in [self.mapView selectedAnnotations])
                    {
                        CLLocationCoordinate2D coordinate = vehicle.coordinate;
                        if (coordinate.latitude != 0 || coordinate.longitude != 0) {
                            MKMapPoint point = MKMapPointForCoordinate(coordinate);
                            if (first) {
                                rect.origin = point;
                                rect.size.height = 0;
                                rect.size.width = 0;
                                first = false;
                            }
                            if (point.x < rect.origin.x) {
                                rect.size.width += rect.origin.x - point.x;
                                rect.origin.x = point.x;
                            }
                            if (point.x > rect.origin.x + rect.size.width) {
                                rect.size.width += point.x - rect.origin.x;
                            }
                            if (point.y < rect.origin.y) {
                                rect.size.height += rect.origin.y - point.y;
                                rect.origin.y = point.y;
                            }
                            if (point.y > rect.origin.y + rect.size.height) {
                                rect.size.height += point.y - rect.origin.y;
                            }
                        }
                    }
                    
                    rect.origin.x -= rect.size.width/10.0;
                    rect.origin.y -= rect.size.height/10.0;
                    rect.size.width *= 1.2;
                    rect.size.height *= 1.2;
                    
                    [self.mapView setVisibleMapRect:rect animated:YES];
                }
                break;
            }
                
            case 1:
            {
                MKMapRect rect;
                BOOL first = TRUE;
                
                for (Vehicle *vehicle in [self.mapView annotations])
                {
                    CLLocationCoordinate2D coordinate = vehicle.coordinate;
                    if (coordinate.latitude != 0 || coordinate.longitude != 0) {
                        MKMapPoint point = MKMapPointForCoordinate(coordinate);
                        if (first) {
                            rect.origin = point;
                            rect.size.height = 0;
                            rect.size.width = 0;
                            first = false;
                        }

                        if (point.x < rect.origin.x) {
                            rect.size.width += rect.origin.x - point.x;
                            rect.origin.x = point.x;
                        }
                        if (point.x > rect.origin.x + rect.size.width) {
                            rect.size.width += point.x - rect.origin.x;
                        }
                        if (point.y < rect.origin.y) {
                            rect.size.height += rect.origin.y - point.y;
                            rect.origin.y = point.y;
                        }
                        if (point.y > rect.origin.y + rect.size.height) {
                            rect.size.height += point.y - rect.origin.y;
                        }
                    }
                }
                
                rect.origin.x -= rect.size.width/10.0;
                rect.origin.y -= rect.size.height/10.0;
                rect.size.width *= 1.2;
                rect.size.height *= 1.2;
                
                [self.mapView setVisibleMapRect:rect animated:YES];
                break;
            }
            case 2:
                self.mapView.mapType = MKMapTypeStandard;
                break;
            case 3:
                self.mapView.mapType = MKMapTypeSatellite;
                break;
            case 4:
                self.mapView.mapType = MKMapTypeHybrid;
                break;
        }
    } else if ([actionSheet.title isEqualToString:ACTION_MQTT]) {
        switch (buttonIndex - actionSheet.firstOtherButtonIndex) {
            case 0:
                [delegate connect];
                break;
            case 1:
                [delegate disconnect];
                break;
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"connectedTo"]) {
        if ([object valueForKey:keyPath]) {
            self.UIConnection.tintColor = [UIColor colorWithRed:0.0 green:190.0/255.0 blue:0.0 alpha:1.0];
        } else {
            self.UIConnection.tintColor = [UIColor colorWithRed:190.0/255.0 green:0.0 blue:0.0 alpha:1.0];
        }
    }
}

@end

