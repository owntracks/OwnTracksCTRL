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
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UITracking;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *UIKiosk;
@property (weak, nonatomic) IBOutlet UIButton *UIInfo;
@property (weak, nonatomic) IBOutlet UIButton *UITrack;
@property (weak, nonatomic) IBOutlet UILabel *UILabel1;
@property (weak, nonatomic) IBOutlet UILabel *UILabel2;
@property (weak, nonatomic) IBOutlet UIImageView *UIImage;
@property (weak, nonatomic) IBOutlet UIView *UIDetailView;

@property (strong, nonatomic) NSURLConnection *urlConnection;
@property (strong, nonatomic) Vehicle *vehicleToGet;
@property (strong, nonatomic) NSMutableData *dataToGet;
@property (strong, nonatomic) NSTimer *timer;
@end

#define COLOR_ERR [UIColor colorWithRed:190.0/255.0 green:0.0 blue:0.0 alpha:1.0]
#define COLOR_ON  [UIColor colorWithRed:0.0 green:190.0/255.0 blue:0.0 alpha:1.0]
#define COLOR_TRANSITION  [UIColor colorWithRed:190.0/255.0 green:190.0/255.0 blue:0.0 alpha:1.0]
#define COLOR_NEUTRAL [UIColor grayColor]
#define COLOR_TRACK [UIColor redColor]

static MapVC *theMapVC;

@implementation MapVC

- (void)loadView {
    [super loadView];
    theMapVC = self;
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showDetail:"]) {
        if ([segue isKindOfClass:[MapPopOverSegue class]]) {
            MapPopOverSegue *mapPopOverSegue = (MapPopOverSegue *)segue;
            mapPopOverSegue.view = self.mapView;
            mapPopOverSegue.rect = self.UIInfo.frame;
            if ([segue.destinationViewController respondsToSelector:@selector(setVehicle:)]) {
                [segue.destinationViewController performSelector:@selector(setVehicle:)
                                                      withObject:sender];
            }
        }
    }
    if ([segue.identifier isEqualToString:@"showDetailPush:"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setVehicle:)]) {
            [segue.destinationViewController performSelector:@selector(setVehicle:)
                                                  withObject:sender];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    [self.mapView setCenterCoordinate:[view.annotation coordinate] animated:true];
    if ([view isKindOfClass:[AnnotationV class]]) {
        AnnotationV *annotationV = (AnnotationV *)view;
        self.UIImage.image = [annotationV getImage];
        [self updateDetailView];
    }
    self.UIDetailView.hidden = false;
}

- (void)updateDetailView {
    if ([self.mapView.selectedAnnotations count] > 0) {
        Vehicle *vehicle = (Vehicle *)self.mapView.selectedAnnotations[0];
        
        NSTimeInterval age = -[vehicle.tst timeIntervalSinceNow];
        self.UILabel1.text = [NSString stringWithFormat:@"T=%.0fkm, A=%@%@%@%@",
                              [vehicle.trip doubleValue] / 1000,
                              age > 24*60*60 ? [NSString stringWithFormat:@"%0.f:", age / (24*60*60)]: @"",
                              age > 60*60 ? [NSString stringWithFormat:@"%0.f:", fmod(age / (60*60), 24)]: @"",
                              age > 60 ? [NSString stringWithFormat:@"%0.f:", fmod(age / 60, 60)]: @"",
                              [NSString stringWithFormat:@"%0.fs", fmod(age, 60)]
                              ];
        self.UILabel2.text = [NSString stringWithFormat:@"n=%ld, I=%@",
                              (long)[vehicle trackCount],
                              vehicle.info ? vehicle.info : @"-"];
        
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
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    self.UIImage.image = nil;
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
                    Vehicle *vehicle = (Vehicle *)annotation;
                    [self updateDetailView];
                    AnnotationV *annotationView = [[AnnotationV alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
                    annotationView.annotation = vehicle;
                    self.UIImage.image = [annotationView getImage];
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

#define ACTION_MAP @"Map Modes"
#define ACTION_MQTT @"MQTT Connection"
#define ACTION_KIOSK @"Kiosk Mode"
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

- (IBAction)exitPressed:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)InfoPressed:(UIButton *)sender {
    if ([self.mapView.selectedAnnotations count] > 0) {
        Vehicle *vehicle = (Vehicle *)self.mapView.selectedAnnotations[0];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [self performSegueWithIdentifier:@"showDetail:" sender:vehicle];
        } else {
            [self performSegueWithIdentifier:@"showDetailPush:" sender:vehicle];
        }
    }
}

- (IBAction)TrackPressed:(UIButton *)sender {
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

- (IBAction)KioskPressed:(UIBarButtonItem *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:ACTION_KIOSK
                                                             delegate:self
                                                    cancelButtonTitle:([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? @"Cancel" : nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  @"ON",
                                  @"OFF",
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
    } else if ([actionSheet.title isEqualToString:ACTION_KIOSK]) {
        switch (buttonIndex - actionSheet.firstOtherButtonIndex) {
            case 0:
                delegate.kiosk = @(true);
                break;
            case 1:
                delegate.kiosk = @(false);
                break;
        }
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

