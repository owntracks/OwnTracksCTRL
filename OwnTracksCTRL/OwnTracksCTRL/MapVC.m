//
//  OPMapViewController.m
//  OwnTracksGW
//
//  Created by Christoph Krey on 16.09.14.
//  Copyright © 2014-2016 christophkrey. All rights reserved.
//

#import "MapVC.h"
#import "Vehicle.h"
#import "AnnotationV.h"
#import "AppDelegate.h"
#import "VehicleVC.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

#import "MapPopOverSegue.h"

@interface MapVC ()
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) UIAlertController *alertController;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *UIConnection;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UIOrganize;

@property (nonatomic) MKMapRect lastMapRect;

@end

#define COLOR_ERR [UIColor colorWithRed:190.0/255.0 green:0.0 blue:0.0 alpha:1.0]
#define COLOR_ON  [UIColor colorWithRed:0.0 green:190.0/255.0 blue:0.0 alpha:1.0]
#define COLOR_TRANSITION  [UIColor colorWithRed:190.0/255.0 green:190.0/255.0 blue:0.0 alpha:1.0]
#define COLOR_NEUTRAL [UIColor colorWithRed:67.0/255.0 green:142.0/255.0 blue:225.0/255.0 alpha:1.0]
#define COLOR_TRACK [UIColor redColor]
#define INSET UIEdgeInsetsMake(100.0, 25.0, 75.0, 25.0)

static MapVC *theMapVC;

@implementation MapVC

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

- (void)loadView {
    [super loadView];
    theMapVC = self;
    self.mapView.showsScale = TRUE;
    self.mapView.showsTraffic = TRUE;

    self.lastMapRect = MKMapRectMake(0, 0, 0, 0);
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate addObserver:self forKeyPath:@"connectedTo"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];

    self.mapView.delegate = self;
    for (Vehicle *vehicle in self.fetchedResultsController.fetchedObjects) {
        [self.mapView addAnnotation:vehicle];
    }
#ifndef CTRLTV
    [self.navigationController.navigationBar setHidden:TRUE];
#endif
}

- (void)viewWillDisappear:(BOOL)animated {
    self.fetchedResultsController = nil;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate removeObserver:self forKeyPath:@"connectedTo"
                        context:nil];
    [self.navigationController.navigationBar setHidden:FALSE];
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
#ifdef CTRLTV
#else
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];

            UIButton *trackButton = [UIButton buttonWithType:UIButtonTypeSystem];
            UIImage *trackImage = [UIImage imageNamed:@"Track"];

            CGRect trackButtonFrame = trackButton.frame;
            trackButtonFrame.size = trackImage.size;
            trackButton.frame = trackButtonFrame;

            [trackButton setImage:trackImage forState:UIControlStateNormal];
            annotationView.leftCalloutAccessoryView = trackButton;
#endif

            annotationView.canShowCallout = TRUE;

            return annotationView;
        }
        return nil;
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[Vehicle class]]) {
        Vehicle *vehicle = (Vehicle *)overlay;
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:[vehicle polyLine]];
        [renderer setLineWidth:3];
        [renderer setStrokeColor:COLOR_TRACK];
        return renderer;
    } else {
        return nil;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    Vehicle *vehicle = (Vehicle *)view.annotation;
    if (control == view.rightCalloutAccessoryView) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [self performSegueWithIdentifier:@"showDetail:" sender:vehicle];
        } else {
            [self performSegueWithIdentifier:@"showDetailPush:" sender:vehicle];
        }

    } else if (control == view.leftCalloutAccessoryView) {
        [self toggleTrack:vehicle];

    } else {
        if (MKMapRectEqualToRect(self.lastMapRect, MKMapRectMake(0, 0, 0, 0))) {
            Vehicle *vehicle = (Vehicle *)view.annotation;
            if ([vehicle.showtrack boolValue]) {
                MKMapRect mapRect = [vehicle boundingMapRect];
                self.lastMapRect = self.mapView.visibleMapRect;
                [self.mapView setVisibleMapRect:mapRect edgePadding:INSET animated:TRUE];
            } else {
                CLLocationCoordinate2D coordinate = vehicle.coordinate;
                if (coordinate.latitude != 0 || coordinate.longitude != 0) {
                    MKMapPoint point = MKMapPointForCoordinate(coordinate);
                    MKMapRect mapRect;
                    mapRect.origin = point;
                    mapRect.size.height = 1;
                    mapRect.size.width = 1;
                    self.lastMapRect = self.mapView.visibleMapRect;
                    [self.mapView setVisibleMapRect:mapRect animated:YES];
                }
            }
        } else {
            [self.mapView setVisibleMapRect:self.lastMapRect animated:TRUE];
            self.lastMapRect = MKMapRectMake(0, 0, 0, 0);
        }
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    [self.mapView setCenterCoordinate:[view.annotation coordinate] animated:true];
    Vehicle *vehicle = (Vehicle *)view.annotation;
    DDLogVerbose(@"didSelectAnnotationView: %@", vehicle.tid);
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    Vehicle *vehicle = (Vehicle *)view.annotation;
    DDLogVerbose(@"didDeselectAnnotationView: %@", vehicle.tid);
}

+ (void)centerOn:(Vehicle *)vehicle {
    [theMapVC centerOn:vehicle];
}

- (void)centerOn:(Vehicle *)vehicle {
    [self.mapView setCenterCoordinate:[vehicle coordinate] animated:TRUE];
    [self.mapView selectAnnotation:vehicle animated:TRUE];
}

- (void)toggleTrack:(Vehicle *)vehicle {
    if ([vehicle.showtrack boolValue]) {
        [self.mapView removeOverlay:vehicle];
        vehicle.showtrack = @(false);
    } else {
        vehicle.track = nil;
        [self getTrack:vehicle];
        [self.mapView addOverlay:vehicle];
        vehicle.showtrack = @(true);
    }
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate saveContext];
}

- (NSFetchedResultsController *)fetchedResultsController {
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
	    DDLogError(@"fetchedResultsController performFetch: %@", error);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    //
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    //
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    Vehicle *vehicle = (Vehicle *)anObject;

    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.mapView addAnnotation:vehicle];
            [self.mapView addOverlay:vehicle];
            break;

        case NSFetchedResultsChangeDelete:
            [self.mapView removeAnnotation:vehicle];
            [self.mapView removeOverlay:vehicle];
            break;
            
        case NSFetchedResultsChangeUpdate: {
            Vehicle *selectedVehicle;
            for (id<MKAnnotation> annotation in self.mapView.selectedAnnotations) {
                if (annotation == vehicle) {
                    selectedVehicle = (Vehicle *)annotation;
                    break;
                }
            }
            [self.mapView removeAnnotation:vehicle];
            [self.mapView removeOverlay:vehicle];
            [self.mapView addAnnotation:vehicle];
            if ([vehicle.showtrack boolValue]) {
                [self.mapView addOverlay:vehicle];
            }
            if (selectedVehicle) {
                [self.mapView setSelectedAnnotations:@[vehicle]];
                [self.mapView setCenterCoordinate:vehicle.coordinate animated:TRUE];
            }
            break;
        }

        case NSFetchedResultsChangeMove:
            //
            break;
    }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    //
}

- (IBAction)swipeGesture:(UISwipeGestureRecognizer *)sender {
    [self mapPressed:nil];
}

- (IBAction)mapPressed:(UIBarButtonItem *)sender {
    if (self.mapView.mapType == MKMapTypeStandard) {
        self.mapView.mapType = MKMapTypeSatellite;
    } else if (self.mapView.mapType == MKMapTypeSatellite) {
        self.mapView.mapType = MKMapTypeHybrid;
    } else {
        self.mapView.mapType = MKMapTypeStandard;
    }
}
- (IBAction)longPress:(UILongPressGestureRecognizer *)sender {
    [self zoomPressed:nil];
}

- (IBAction)zoomPressed:(UIBarButtonItem *)sender {
    if (MKMapRectEqualToRect(self.lastMapRect, MKMapRectMake(0, 0, 0, 0))) {
        MKMapRect rect = self.mapView.visibleMapRect;
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
                    rect.size.width = point.x - rect.origin.x;
                }
                if (point.y < rect.origin.y) {
                    rect.size.height += rect.origin.y - point.y;
                    rect.origin.y = point.y;
                }
                if (point.y > rect.origin.y + rect.size.height) {
                    rect.size.height = point.y - rect.origin.y;
                }
            }
        }
        
        self.lastMapRect = self.mapView.visibleMapRect;
        [self.mapView setVisibleMapRect:rect edgePadding:INSET animated:TRUE];
    } else {
        [self.mapView setVisibleMapRect:self.lastMapRect animated:TRUE];
        self.lastMapRect = MKMapRectMake(0, 0, 0, 0);
    }
}

#ifndef CTRLTV

- (IBAction)ConnectionButtonPressed:(UIButton *)sender {
    [self ConnectionPressed:nil];
}

- (IBAction)ConnectionPressed:(UIBarButtonItem *)sender {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (delegate.connectedTo) {
        [delegate disconnect];
    } else {
        [delegate connect];
    }
}

- (IBAction)exitPressed:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)organizePressed:(UIBarButtonItem *)sender {
    if ([self.mapView.selectedAnnotations count] > 0) {
        Vehicle *vehicle = (Vehicle *)self.mapView.selectedAnnotations[0];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [self performSegueWithIdentifier:@"showTrack:" sender:vehicle];
        } else {
            [self performSegueWithIdentifier:@"showTrackPush:" sender:vehicle];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showDetail:"] || [segue.identifier isEqualToString:@"showTrack:"]) {
        if ([segue isKindOfClass:[MapPopOverSegue class]]) {
            MapPopOverSegue *mapPopOverSegue = (MapPopOverSegue *)segue;
            mapPopOverSegue.view = self.mapView;
            if ([segue.destinationViewController respondsToSelector:@selector(setVehicle:)]) {
                [segue.destinationViewController performSelector:@selector(setVehicle:)
                                                      withObject:sender];
            }
            if ([segue.identifier isEqualToString:@"showDetail:"]) {
                mapPopOverSegue.item = sender;
            } else {
                mapPopOverSegue.item = self.UIOrganize;
            }
        }
    }
    if ([segue.identifier isEqualToString:@"showDetailPush:"] || [segue.identifier isEqualToString:@"showTrackPush:"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setVehicle:)]) {
            [segue.destinationViewController performSelector:@selector(setVehicle:)
                                                  withObject:sender];
        }
    }
}


#endif

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"connectedTo"]) {
        if ([object valueForKey:keyPath]) {
            [self performSelectorOnMainThread:@selector(changeUIForConnectedTo:) withObject:@TRUE waitUntilDone:NO];
        } else {
            [self performSelectorOnMainThread:@selector(changeUIForConnectedTo:) withObject:@FALSE waitUntilDone:NO];
        }
    }
}

- (void)changeUIForConnectedTo:(NSNumber *)connectedTo {
    if (self.UIConnection) {
    if ([connectedTo boolValue]) {
        self.UIConnection.tintColor = COLOR_ON;
    } else {
        self.UIConnection.tintColor = COLOR_ERR;
    }
    }
}

- (void)getTrack:(Vehicle *)vehicle {
    __block Vehicle *vehicleToGet = vehicle;
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSArray <NSString *> *topicComponents = [vehicle.topic componentsSeparatedByString:@"/"];
    NSString *post = [NSString stringWithFormat:@"user=%@&device=%@",
                      topicComponents[1],
                      topicComponents[2]
                      ];
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld",(unsigned long)[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:delegate.broker.trackurl]];
    [request setHTTPMethod:@"POST"];
    
    NSString *authStr = [NSString stringWithFormat:@"%@:%@",
                         [[NSUserDefaults standardUserDefaults] valueForKey:@"ctrluser"],
                         [[NSUserDefaults standardUserDefaults] valueForKey:@"ctrlpass"]];
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat: @"Basic %@",[authData base64EncodedStringWithOptions:0]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    NSURLSession *urlSession = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *downloadTask =
    [urlSession downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        
        DDLogVerbose(@"downloadTaskWithRequest completionhandler %@ %@ %@", location, response, error);
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            vehicleToGet.track = nil;
        }
        if (error) {
            vehicleToGet.track = nil;
        } else {
            if (location) {
                vehicleToGet.track = [NSData dataWithContentsOfURL:location];
            }
        }
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate saveContext];
    }];
    
    [downloadTask resume];
}

- (void)showAlertController {
    [self presentViewController:self.alertController animated:YES completion:nil];
}

@end

