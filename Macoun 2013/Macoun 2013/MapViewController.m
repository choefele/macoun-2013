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

@interface MapViewController ()<MKMapViewDelegate, DataReaderDelegate>

@property (nonatomic, strong) MapClusterController *mapClusterController;

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mapView.delegate = self;
    
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

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self.mapClusterController updateAnnotationsWithCompletionHandler:NULL];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *annotationView;
    
    if ([annotation isKindOfClass:MKPointAnnotation.class]) {
        static NSString * const pinIdentifier = @"pinIdentifier";
        MKPinAnnotationView *pinAnnotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:pinIdentifier];
        if (pinAnnotationView == nil) {
            pinAnnotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pinIdentifier];
            pinAnnotationView.canShowCallout = YES;
            
            UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            pinAnnotationView.rightCalloutAccessoryView = rightButton;
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

- (void)dataReader:(DataReader *)dataReader addAnnotations:(NSArray *)annotations
{
    [self.mapClusterController addAnnotations:annotations];
}

@end
