//
//  MapViewController.m
//  Macoun 2013
//
//  Created by Hoefele, Claus(choefele) on 22.09.13.
//  Copyright (c) 2013 Hoefele, Claus(choefele). All rights reserved.
//

#import "MapViewController.h"

@interface MapViewController ()

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Show Berlin on map
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(52.516221, 13.377829);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 1000, 1000);
    self.mapView.region = region;
    
    // Add pin for Brandenburg Gate
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = location;
    annotation.title = @"Berlin";
    annotation.subtitle = @"Brandenburger Tor";
    [self.mapView addAnnotation:annotation];
}

@end
