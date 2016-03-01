//
//  OPMapViewController.m
//  OwnTracksGW
//
//  Created by Christoph Krey on 16.09.14.
//  Copyright © 2014-2016 christophkrey. All rights reserved.
//

#import "MapVC.h"
#import "Vehicle+Create.h"
#import "AnnotationV.h"
#import "AppDelegate.h"
#import "VehicleVC.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

#ifndef CTRLTV
#import "MapPopOverSegue.h"
#else
#import "TVMapView.h"
#endif

@interface MapVC ()
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSURLSession *urlSession;
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (strong, nonatomic) Vehicle *vehicleToGet;
@property (strong, nonatomic) UIAlertController *alertController;

#ifndef CTRLTV
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UIConnection;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UIKiosk;
@property (weak, nonatomic) IBOutlet UIToolbar *UIDetailView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UILabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UITrack;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UITid;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UIInfo;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UIOrganize;

@property (nonatomic) MKMapRect lastMapRect;
@property (strong, nonatomic) NSTimer *timer;

#else

@property (weak, nonatomic) IBOutlet UIButton *UIConnection;
@property (strong, nonatomic) CLLocationManager *locationManager;

#endif

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
#ifndef CTRLTV
    self.lastMapRect = MKMapRectMake(0, 0, 0, 0);
#endif
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate addObserver:self forKeyPath:@"connectedTo"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];

#ifndef CTRLTV
    self.mapView.delegate = self;
    for (Vehicle *vehicle in self.fetchedResultsController.fetchedObjects) {
        [self.mapView addAnnotation:vehicle];
    }
    [appDelegate addObserver:self forKeyPath:@"kiosk"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];
    [self.navigationController.navigationBar setHidden:TRUE];

     self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(updateDetailView)
                                                userInfo:nil
                                                 repeats:true];
    
    if ([self.mapView.selectedAnnotations count] > 0) {
        self.UIDetailView.hidden = false;
    } else {
        self.UIDetailView.hidden = true;
    }
#else
    if (!self.locationManager) {
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        if (authorizationStatus != kCLAuthorizationStatusDenied &&
            authorizationStatus != kCLAuthorizationStatusDenied) {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            if (authorizationStatus == kCLAuthorizationStatusNotDetermined) {
                [self.locationManager requestWhenInUseAuthorization];
            }
            if ([CLLocationManager locationServicesEnabled]) {
                [self.locationManager requestLocation];
            }
        }
    }

    if ([self.view respondsToSelector:@selector(setVehicles:)]) {
        [self.view performSelector:@selector(setVehicles:) withObject:self.fetchedResultsController.fetchedObjects];
    }
#endif
}

#ifdef CTRLTV
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    for (CLLocation *location in locations) {
        if ([self.view isKindOfClass:[TVMapView class]]) {
            TVMapView *tvMapView = (TVMapView *)self.view;
            tvMapView.centerLocation = location.coordinate;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    DDLogError(@"locationManager didFailWithError: %@", error);

}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    DDLogVerbose(@"locationManager didChangeAuthorizationStatus: %d", status);

}
#endif

- (void)viewWillDisappear:(BOOL)animated {
    self.fetchedResultsController = nil;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate removeObserver:self forKeyPath:@"connectedTo"
                        context:nil];
#ifndef CTRLTV
    [appDelegate removeObserver:self forKeyPath:@"kiosk"
                        context:nil];
    [self.navigationController.navigationBar setHidden:FALSE];
    [self.timer invalidate];
#endif
    [super viewWillDisappear:animated];
}

#ifndef CTRLTV
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

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    [self.mapView setCenterCoordinate:[view.annotation coordinate] animated:true];
    [self updateDetailView];
    self.UIDetailView.hidden = false;
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    self.UIDetailView.hidden = true;
}

+ (void)centerOn:(Vehicle *)vehicle {
    [theMapVC centerOn:vehicle];
}

- (void)centerOn:(Vehicle *)vehicle {
    [self.mapView setCenterCoordinate:[vehicle coordinate] animated:TRUE];
    [self.mapView selectAnnotation:vehicle animated:TRUE];
}

- (void)updateDetailView {
    if ([self.mapView.selectedAnnotations count] > 0) {
        Vehicle *vehicle = (Vehicle *)self.mapView.selectedAnnotations[0];
        self.UITid.title = vehicle.tid;
        
        self.UIOrganize.enabled = (vehicle.track != nil);
        
        NSTimeInterval age = -[vehicle.tst timeIntervalSinceNow];
        int days = age / (24*60*60);
        int hours = fmod(age, 24*60*60) / (60*60);
        int minutes = fmod(age , (24*60)) / 60;
        int seconds = fmod(age, 60);
        
        self.UILabel.title = [NSString stringWithFormat:@"Age=%@%@%@%@, Track=%ld, Info=%@",
                              days > 0 ? [NSString stringWithFormat:@"%dd:", days]: @"",
                              hours > 0 ? [NSString stringWithFormat:@"%dh:", hours]: @"",
                              minutes > 0 ? [NSString stringWithFormat:@"%dm:", minutes]: @"",
                              [NSString stringWithFormat:@"%ds", seconds],
                              (long)[vehicle trackCount],
                              vehicle.info ? vehicle.info : @"-"];
        
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if (delegate.broker.trackurl && delegate.broker.trackurl.length > 0) {
            self.UITrack.enabled = true;
            if ([vehicle.showtrack boolValue]) {
                if (vehicle.track) {
                    if (vehicle.track.length > 0) {
                        self.UITrack.tintColor = COLOR_ON;
                    } else {
                        self.UITrack.tintColor = COLOR_TRANSITION;
                    }
                } else {
                    self.UITrack.tintColor = COLOR_ERR;
                }
            } else {
                self.UITrack.tintColor = COLOR_NEUTRAL;
            }
        } else {
            self.UITrack.enabled = false;
        }
    }
}

#endif

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
	    DDLogError(@"fetchedResultsController performFetch: %@", error);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    //
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    //
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
#ifndef CTRLTV
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
            [self.mapView removeOverlay:anObject];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.mapView removeAnnotation:anObject];
            [self.mapView removeOverlay:anObject];
            
            [self.mapView addAnnotation:anObject];
            if (annotation == selectedAnnotation) {
                [self.mapView selectAnnotation:annotation animated:true];
                if ([annotation isKindOfClass:[Vehicle class]]) {
                    [self updateDetailView];
                }
            }
            if ([annotation isKindOfClass:[Vehicle class]]) {
                Vehicle *vehicle = (Vehicle *)annotation;
                if ([vehicle.showtrack boolValue]) {
                    [self.mapView addOverlay:vehicle];
                }
            }
            break;
            
        case NSFetchedResultsChangeMove:
            //
            break;
    }
#endif
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
#ifdef CTRLTV
    if ([self.view respondsToSelector:@selector(setVehicles:)]) {
        [self.view performSelector:@selector(setVehicles:) withObject:controller.fetchedObjects];
    }
#endif
}

#ifndef CTRLTV
- (IBAction)mapPressed:(UIBarButtonItem *)sender {
    if (self.mapView.mapType == MKMapTypeStandard) {
        self.mapView.mapType = MKMapTypeSatellite;
    } else if (self.mapView.mapType == MKMapTypeSatellite) {
        self.mapView.mapType = MKMapTypeHybrid;
    } else {
        self.mapView.mapType = MKMapTypeStandard;
    }
}

- (IBAction)zoomPressed:(UIBarButtonItem *)sender {
    if (MKMapRectEqualToRect(self.lastMapRect, MKMapRectMake(0, 0, 0, 0))) {
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

#endif
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

#ifndef CTRLTV
- (IBAction)exitPressed:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)InfoPressed:(UIBarButtonItem *)sender {
    if ([self.mapView.selectedAnnotations count] > 0) {
        Vehicle *vehicle = (Vehicle *)self.mapView.selectedAnnotations[0];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [self performSegueWithIdentifier:@"showDetail:" sender:vehicle];
        } else {
            [self performSegueWithIdentifier:@"showDetailPush:" sender:vehicle];
        }
    }
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
                mapPopOverSegue.item = self.UIInfo;
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


- (IBAction)TrackPressed:(UIBarButtonItem *)sender {
    if ([self.mapView.selectedAnnotations count] > 0) {
        Vehicle *vehicle = (Vehicle *)self.mapView.selectedAnnotations[0];
        if ([vehicle.showtrack boolValue]) {
            [self.mapView removeOverlay:vehicle];
            vehicle.showtrack = @(false);
        } else {
            [self getTrack:vehicle];
            [self.mapView addOverlay:vehicle];
            vehicle.showtrack = @(true);
        }
    }
}

- (IBAction)TidPressed:(UIBarButtonItem *)sender {
    if ([[self.mapView selectedAnnotations] count]) {
        if (MKMapRectEqualToRect(self.lastMapRect, MKMapRectMake(0, 0, 0, 0))) {
            Vehicle *vehicle = (Vehicle *)[self.mapView selectedAnnotations][0];
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


- (IBAction)KioskPressed:(UIBarButtonItem *)sender {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if ([delegate.kiosk boolValue]) {
        delegate.kiosk = @(false);
    } else {
        delegate.kiosk = @(true);
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
    if ([keyPath isEqualToString:@"kiosk"]) {
            [self performSelectorOnMainThread:@selector(changeUIForKiosk:)
                                   withObject:[object valueForKey:keyPath]
                                waitUntilDone:NO];
    }
}

- (void)changeUIForConnectedTo:(NSNumber *)connectedTo {
    if ([connectedTo boolValue]) {
        self.UIConnection.tintColor = COLOR_ON;
    } else {
        self.UIConnection.tintColor = COLOR_ERR;
    }
#ifdef CTRLTV
    if ([connectedTo boolValue]) {
        [self.UIConnection setTitle:@"Disconnect" forState:UIControlStateNormal];
    } else {
        [self.UIConnection setTitle:@"Connect" forState:UIControlStateNormal];
    }
#endif
}

- (void)changeUIForKiosk:(NSNumber *)kiosk {
#ifndef CTRLTV
    if ([kiosk boolValue]) {
        self.UIKiosk.tintColor = COLOR_ON;
        [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    } else {
        self.UIKiosk.tintColor = COLOR_NEUTRAL;
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
#endif
}

- (void)getTrack:(Vehicle *)vehicle {
    if (self.downloadTask) {
        [self.downloadTask cancel];
    }
    self.vehicleToGet = vehicle;
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
    
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", delegate.confD.user, delegate.confD.passwd];
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat: @"Basic %@",[authData base64EncodedStringWithOptions:0]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    self.downloadTask =
    [self.urlSession downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        
        DDLogVerbose(@"downloadTaskWithRequest completionhandler %@ %@ %@", location, response, error);
#ifndef CTRLTV
        [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
#endif
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            NSString *message = [NSString stringWithFormat:@"%ld %@\n%@",
                                 (long)httpResponse.statusCode,
                                 [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode],
                                 httpResponse.URL];

            self.alertController = [UIAlertController alertControllerWithTitle:@"HTTP Response"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     [self.alertController dismissViewControllerAnimated:TRUE completion:nil];
                                                                 }];
            
            [self.alertController addAction:cancelAction];
            [self performSelectorOnMainThread:@selector(showAlertController) withObject:nil waitUntilDone:NO];
            self.vehicleToGet.track = nil;
            self.vehicleToGet = nil;
        }
        
        if (error) {
            self.alertController = [UIAlertController alertControllerWithTitle:@"Loading failed"
                                                                       message:[error localizedDescription]
                                                                preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     [self.alertController dismissViewControllerAnimated:TRUE completion:nil];
                                                                 }];
            
            [self.alertController addAction:cancelAction];
            [self performSelectorOnMainThread:@selector(showAlertController) withObject:nil waitUntilDone:NO];
            self.vehicleToGet.track = nil;
            self.vehicleToGet = nil;

        } else {
            if (location) {
                self.vehicleToGet.track = [NSData dataWithContentsOfURL:location];
            }
        }
        
        self.downloadTask = nil;
        self.urlSession = nil;
    }];
    
    [self.downloadTask resume];
#ifndef CTRLTV
    [UIApplication sharedApplication].networkActivityIndicatorVisible = true;
#endif
}

- (void)showAlertController {
    [self presentViewController:self.alertController animated:YES completion:nil];
}

@end

