//
//  MapViewController.m
//  Macoun 2013
//
//  Created by Hoefele, Claus(choefele) on 22.09.13.
//  Copyright (c) 2013 Hoefele, Claus(choefele). All rights reserved.
//

#import "MapViewController.h"

#import "DataReader.h"
#import "DataReaderDelegate.h"
#import "MapClusterController.h"
#import "MapClusterAnnotation.h"
#import "Annotation.h"

@interface MapViewController ()<MKMapViewDelegate, UISearchBarDelegate, DataReaderDelegate>

@property (nonatomic, strong) MapClusterController *mapClusterController;
@property (nonatomic, strong) NSMutableArray *annotations;
@property (nonatomic, assign) MKCoordinateSpan regionSpanBeforeChange;
@property (nonatomic, strong) Annotation *annotationToSelect;

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mapView.delegate = self;
    [self.searchDisplayController.searchBar removeFromSuperview];
    self.searchDisplayController.displaysSearchBarInNavigationBar = YES;
    self.annotations = [NSMutableArray arrayWithCapacity:100];
    
    // Show Berlin on map
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(52.516221, 13.377829);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 45000, 45000);
    self.mapView.region = region;
    
//    // Add pin for Brandenburg Gate
//    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
//    annotation.coordinate = location;
//    annotation.title = @"Berlin";
//    annotation.subtitle = @"Brandenburger Tor";
//    [self.mapView addAnnotation:annotation];
    
    // Add annotations
    DataReader *dataReader = [[DataReader alloc] init];
    dataReader.delegate = self;
    [dataReader startReading];
    
    // Create cluster controller
    self.mapClusterController = [[MapClusterController alloc] initWithMapView:self.mapView];
}

#define fequal(a, b) (fabs((a) - (b)) < FLT_EPSILON)

- (void)deselectAllAnnotations
{
    NSArray *selectedAnnotations = self.mapView.selectedAnnotations;
    for (id<MKAnnotation> selectedAnnotation in selectedAnnotations) {
        [self.mapView deselectAnnotation:selectedAnnotation animated:YES];
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    self.regionSpanBeforeChange = mapView.region.span;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    // Deselect all annotations when zooming in/out.
    BOOL hasZoomed = !fequal(mapView.region.span.longitudeDelta, self.regionSpanBeforeChange.longitudeDelta);
    if (hasZoomed) {
        [self deselectAllAnnotations];
    }

    [self.mapClusterController updateAnnotationsWithCompletionHandler:NULL];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *annotationView;
    
    if ([annotation isKindOfClass:MapClusterAnnotation.class]) {
        static NSString * const pinIdentifier = @"pinIdentifier";
        MKPinAnnotationView *pinAnnotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:pinIdentifier];
        if (pinAnnotationView == nil) {
            pinAnnotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pinIdentifier];
            pinAnnotationView.canShowCallout = YES;
        }
        annotationView = pinAnnotationView;
    }
    
    return annotationView;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    MKOverlayView *view;
    if ([overlay isKindOfClass:MKPolygon.class]) {
        MKPolygonView *polygonView = [[MKPolygonView alloc] initWithPolygon:(MKPolygon *)overlay];
        polygonView.strokeColor = [UIColor.blueColor colorWithAlphaComponent:0.7];
        polygonView.lineWidth = 1;
        view = polygonView;
    }
    
    return view;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    // Show location in Maps app
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:view.annotation.coordinate addressDictionary:nil];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    mapItem.name = view.annotation.title;
    [mapItem openInMapsWithLaunchOptions:nil];
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    [self.mapClusterController didAddAnnotationViews:views];
}

- (void)dataReader:(DataReader *)dataReader addAnnotations:(NSArray *)annotations
{
    [self.annotations addObjectsFromArray:annotations];
    [self.mapClusterController addAnnotations:annotations];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const cellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    Annotation *annotation = self.annotations[indexPath.row];
    cell.textLabel.text = annotation.title;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.annotations.count;
}

- (BOOL)isCoordinateUpToDate:(CLLocationCoordinate2D)coordinate
{
    BOOL isCoordinateUpToDate = fequal(coordinate.latitude, self.mapView.region.center.latitude) && fequal(coordinate.longitude, self.mapView.region.center.longitude);
    return isCoordinateUpToDate;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchDisplayController setActive:NO animated:YES];
    [self deselectAllAnnotations];
    
    // Zoom in to selected annoation
    self.annotationToSelect = self.annotations[indexPath.row];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.annotationToSelect.coordinate, 400, 400);
    [self.mapView setRegion:region animated:YES];
    if ([self isCoordinateUpToDate:region.center]) {
        // Manually call update methods because region won't change
        [self mapView:self.mapView regionWillChangeAnimated:YES];
        [self mapView:self.mapView regionDidChangeAnimated:YES];
    }
}

@end
