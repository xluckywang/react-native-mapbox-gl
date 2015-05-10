//
//  RCTMapboxGL.m
//  RCTMapboxGL
//
//  Created by Bobby Sudekum on 4/30/15.
//  Copyright (c) 2015 Mapbox. All rights reserved.
//

#import "RCTMapboxGL.h"
#import "RCTBridgeModule.h"
#import "RCTEventDispatcher.h"
#import "UIView+React.h"

@implementation RCTMapboxGL {
  /* Required to publish events */
  RCTEventDispatcher *_eventDispatcher;

  /* Our map subview instance */
  MGLMapView *_map;

  /* Map properties */
  NSString *_accessToken;
  NSMutableDictionary *_annotations;
  NSMutableDictionary *_newAnnotations;
  CLLocationCoordinate2D _centerCoordinate;
  BOOL _clipsToBounds;
  BOOL _debugActive;
  double _direction;
  BOOL _finishedLoading;
  BOOL _rotateEnabled;
  BOOL _showsUserLocation;
  NSURL *_styleURL;
  double _zoomLevel;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
  if (self = [super init]) {
    _eventDispatcher = eventDispatcher;
    _clipsToBounds = YES;
    _finishedLoading = NO;
    _annotations = [NSMutableDictionary dictionary];
  }

  return self;
}

- (void)setAccessToken:(NSString *)accessToken
{
  _accessToken = accessToken;
  [self updateMap];
}

- (void)updateMap
{
  if (_map) {
    _map.centerCoordinate = _centerCoordinate;
    _map.clipsToBounds = _clipsToBounds;
    _map.debugActive = _debugActive;
    _map.direction = _direction;
    _map.rotateEnabled = _rotateEnabled;
    _map.showsUserLocation = _showsUserLocation;
    _map.styleURL = _styleURL;
    _map.zoomLevel = _zoomLevel;

    /* A bit of a hack because hooking into the fully rendered event didn't seem to work */
    [self performSelector:@selector(updateAnnotations) withObject:nil afterDelay:1];
  } else {
    /* We need to have a height/width specified in order to render */
    if (_accessToken && _styleURL && self.bounds.size.height > 0 && self.bounds.size.width > 0) {
      [self createMap];
    }
  }
}

- (void)createMap
{
  _map = [[MGLMapView alloc] initWithFrame:self.bounds accessToken:_accessToken styleURL:_styleURL];
  _map.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _map.delegate = self;
  [self updateMap];
  [self addSubview:_map];
  [self layoutSubviews];
}

- (void)layoutSubviews
{
  [self updateMap];
  _map.frame = self.bounds;
}

- (void)setAnnotations:(NSMutableDictionary *)annotations
{
  _newAnnotations = annotations;
  [self updateMap];
}

- (void)updateAnnotations
{
  if (_newAnnotations) {
    NSArray *oldKeys = [_annotations allKeys];
    NSArray *newKeys = [_newAnnotations allKeys];

    // Take into account any already placed pins
    if (oldKeys.count) {
      NSMutableArray *removeableKeys = [NSMutableArray array];
      for (NSValue *oldKey in oldKeys){
        // Collect all keys that existed in "oldKeys" but not in "newKeys"
        // anymore, so they can be removed
        if (![newKeys containsObject:oldKey]){
          [removeableKeys addObject:oldKey];
        }
      }

      // Remove each of the "removableKeys" from the map
      if (removeableKeys.count){
        NSArray *removed = [_annotations objectsForKeys:removeableKeys notFoundMarker:[NSNull null]];
        [_map removeAnnotations: removed];
      }

      // Remove any annotations that exist in both new and old from
      // newAnnotations, so we don't create duplicates
      [_newAnnotations removeObjectsForKeys:[_annotations allKeys]];
    }

    [_annotations addEntriesFromDictionary:_newAnnotations];
    [_map addAnnotations:[_newAnnotations allValues]];

    /* [_map updateUserLocationAnnotationView]; */
    _newAnnotations = nil;
  }
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
{
  _centerCoordinate = centerCoordinate;
  [self updateMap];
}

- (void)setDebugActive:(BOOL)debugActive
{
  _debugActive = debugActive;
  [self updateMap];
}

- (void)setRotateEnabled:(BOOL)rotateEnabled
{
  _rotateEnabled = rotateEnabled;
  [self updateMap];
}

- (void)setShowsUserLocation:(BOOL)showsUserLocation
{
  _showsUserLocation = showsUserLocation;
  [self updateMap];
}

- (void)setClipsToBounds:(BOOL)clipsToBounds
{
  _clipsToBounds = clipsToBounds;
  [self updateMap];
}

- (void)setDirection:(double)direction
{
  _direction = direction;
  [self updateMap];
}

- (void)setZoomLevel:(double)zoomLevel
{
  _zoomLevel = zoomLevel;
  [self updateMap];
}

- (void)setStyleURL:(NSURL*)styleURL
{
  _styleURL = styleURL;
  [self updateMap];
}

- (void)mapView:(RCTMapboxGL *)mapView regionDidChangeAnimated:(BOOL)animated
{

  CLLocationCoordinate2D region = _map.centerCoordinate;

  NSDictionary *event = @{ @"target": self.reactTag,
                           @"region": @{ @"latitude": @(region.latitude),
                                         @"longitude": @(region.longitude),
                                         @"zoom": [NSNumber numberWithDouble:_map.zoomLevel] } };

  [_eventDispatcher sendInputEventWithName:@"topChange" body:event];
}

@end

/* MGLAnnotation */

@interface MGLAnnotation ()

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *subtitle;

@end

@implementation MGLAnnotation

+ (instancetype)annotationWithLocation:(CLLocationCoordinate2D)coordinate title:(NSString *)title subtitle:(NSString *)subtitle
{
    return [[self alloc] initWithLocation:coordinate title:title subtitle:subtitle];
}

- (instancetype)initWithLocation:(CLLocationCoordinate2D)coordinate title:(NSString *)title subtitle:(NSString *)subtitle
{
    if (self = [super init]) {
      _coordinate = coordinate;
      _title = title;
      _subtitle = subtitle;
    }

    return self;
}

@end
