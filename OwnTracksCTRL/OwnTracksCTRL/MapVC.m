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
#import "MapPopOverSegue.h"

@interface MapVC ()
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UIConnection;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UIKiosk;
@property (weak, nonatomic) IBOutlet UIToolbar *UIDetailView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UILabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UITrack;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UITid;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UIInfo;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UIOrganize;

@property (strong, nonatomic) NSURLConnection *urlConnection;
@property (strong, nonatomic) Vehicle *vehicleToGet;
@property (strong, nonatomic) NSMutableData *dataToGet;
@property (strong, nonatomic) NSTimer *timer;
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

- (void)loadView {
    [super loadView];
    theMapVC = self;
    self.lastMapRect = MKMapRectMake(0, 0, 0, 0);
}

+ (void)centerOn:(Vehicle *)vehicle {
    [theMapVC centerOn:vehicle];
}

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

}

- (void)viewWillDisappear:(BOOL)animated {
    self.fetchedResultsController = nil;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate removeObserver:self forKeyPath:@"kiosk"
                        context:nil];
    [appDelegate removeObserver:self forKeyPath:@"connectedTo"
                        context:nil];
    [self.navigationController.navigationBar setHidden:FALSE];
    [self.timer invalidate];
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
        
        self.UILabel.title = [NSString stringWithFormat:@"T=%.0fkm, A=%@%@%@%@, n=%ld, I=%@",
                              [vehicle.trip doubleValue] / 1000,
                              days > 0 ? [NSString stringWithFormat:@"%d:", days]: @"",
                              hours > 0 ? [NSString stringWithFormat:@"%d:", hours]: @"",
                              minutes > 0 ? [NSString stringWithFormat:@"%d:", minutes]: @"",
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

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    self.UIDetailView.hidden = true;
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
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    //
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"connectedTo"]) {
        if ([object valueForKey:keyPath]) {
            self.UIConnection.tintColor = COLOR_ON;
        } else {
            self.UIConnection.tintColor = COLOR_ERR;
        }
    } else if ([keyPath isEqualToString:@"kiosk"]) {
        if ([[object valueForKey:keyPath] boolValue]) {
            self.UIKiosk.tintColor = COLOR_ON;
            [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
        } else {
            self.UIKiosk.tintColor = COLOR_NEUTRAL;
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        }
    }
}

- (void)getTrack:(Vehicle *)vehicle {
    if (self.urlConnection) {
        [self.urlConnection cancel];
    }
    self.vehicleToGet = vehicle;
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSString *post = [NSString stringWithFormat:@"username=%@&password=%@&tid=%@&nrecs=%d&topic=%@",
                      delegate.broker.user,
                      delegate.broker.passwd,
                      vehicle.tid,
                      500,
                      vehicle.topic];
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld",(unsigned long)[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:delegate.broker.trackurl]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    self.dataToGet = [[NSMutableData alloc] init];
    self.urlConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = true;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
        if (httpURLResponse.statusCode != 200) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
            NSString *message = [NSString stringWithFormat:@"%ld %@\n%@",
                                 (long)httpURLResponse.statusCode,
                                 [NSHTTPURLResponse localizedStringForStatusCode:httpURLResponse.statusCode],
                                 httpURLResponse.URL];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"HTTP Response"
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil];
            [alertView show];
            self.vehicleToGet.track = nil;
            self.dataToGet = nil;
            self.vehicleToGet = nil;
            self.urlConnection = nil;
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.dataToGet appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Loading failed"
                                                        message:[AppDelegate dataToString:self.dataToGet]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
    [alertView show];
    self.vehicleToGet.track = nil;
    self.dataToGet = nil;
    self.vehicleToGet = nil;
    self.urlConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
    self.vehicleToGet.track = self.dataToGet;
    self.dataToGet = nil;
    self.vehicleToGet = nil;
    self.urlConnection = nil;
}



@end

