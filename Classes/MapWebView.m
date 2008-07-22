/*
 * Copyright (c) 2008, eSpace Technologies.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice, 
 * this list of conditions and the following disclaimer in the documentation 
 * and/or other materials provided with the distribution.
 * 
 * Neither the name of eSpace nor the names of its contributors may be used 
 * to endorse or promote products derived from this software without specific 
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "MapWebView.h"

#define DEFAULT_ZOOM_LEVEL	17

@interface MapWebView (Private)
- (void) loadMap;
@end

@implementation MapWebView

//-- Public Methods ------------------------------------------------------------
@synthesize mDelegate;
//------------------------------------------------------------------------------
- (void) didMoveToSuperview {
    // this hook method is used to initialize the view; we don't want 
    // any user input to be delivered to the UIWebView, instead, the 
    // MapView overlay will receive all input and convert it to commands 
    // that can be performed by the Google Maps Javascript API directly
    
    self.userInteractionEnabled = NO;
    self.scalesPageToFit = NO;
    self.autoresizingMask = 
    	UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    [self loadMap];
}
//------------------------------------------------------------------------------
- (NSString*) evalJS:(NSString*)script {
    return [self stringByEvaluatingJavaScriptFromString:script];
}
//------------------------------------------------------------------------------
- (void) moveByDx:(int)dX dY:(int)dY {
    int centerX = ((int)[self bounds].size.width) >> 1;
    int centerY = ((int)[self bounds].size.height) >> 1;
    [self setCenterWithPixel:GPointMake(centerX - dX, centerY - dY)];
}

//-- Methods corresponding to Google Maps Javascript API methods ---------------
- (int) getZoom {
    return [[self evalJS:@"map.getZoom();"] intValue];
}
//------------------------------------------------------------------------------
- (void) setZoom:(int)level {
    [self evalJS:[NSString stringWithFormat:@"map.setZoom(%d);", level]];
    
    if (self.delegate)
        [self.delegate mapZoomUpdatedTo:level];
}
//------------------------------------------------------------------------------
- (void) zoomIn {
    [self evalJS:@"map.zoomIn();"];
    
    if (self.delegate)
        [self.delegate mapZoomUpdatedTo:[self getZoom]];
}
//------------------------------------------------------------------------------
- (void) zoomOut {
    [self evalJS:@"map.zoomOut();"];
    
    if (self.delegate)
        [self.delegate mapZoomUpdatedTo:[self getZoom]];
}
//------------------------------------------------------------------------------
- (void) setCenterWithPixel:(GPoint)pixel {
    NSString *script = 
        [NSString stringWithFormat:
         @"var newCenterPixel = new GPoint(%ld, %ld);"
          "var newCenterLatLng = map.fromContainerPixelToLatLng(newCenterPixel);"
          "map.setCenter(newCenterLatLng);", 
         pixel.x, pixel.y];
    
    [self evalJS:script];
    
    if (self.delegate)
        [self.delegate mapCenterUpdatedToPixel:pixel];
}
//------------------------------------------------------------------------------
- (void) setCenterWithLatLng:(GLatLng)latlng {
    NSString *script = 
        [NSString stringWithFormat:
         @"var newCenterLatLng = map.fromContainerPixelToLatLng(newCenterPixel);"
          "map.setCenter(new GLatLng(%lf, %lf));", 
         latlng.lat, latlng.lng];
    
    [self evalJS:script];
    
    if (self.delegate)
        [self.delegate mapCenterUpdatedToLatLng:latlng];
}
//------------------------------------------------------------------------------
- (GLatLng) getCenterLatLng {
    // the result should be in the form "(<latitude>, <longitude>)"
    NSString *centerStr = [self evalJS:@"map.getCenter().toString();"];
    
    GLatLng latlng;
    sscanf([centerStr UTF8String], "(%lf, %lf)", &latlng.lat, &latlng.lng);
    
    return latlng;
}
//------------------------------------------------------------------------------
- (GPoint) getCenterPixel {
    // the result should be in the form "(<x>, <y>)"
    NSString *centerStr = 
    	[self evalJS:@"map.fromLatLngToContainerPixel(map.getCenter()).toString();"];
    
    GPoint pixel;
    sscanf([centerStr UTF8String], "(%ld, %ld)", &pixel.x, &pixel.y);
    
    return pixel;
}
//------------------------------------------------------------------------------
- (void) panToCenterWithPixel:(GPoint)pixel {
    NSString *script = 
        [NSString stringWithFormat:
         @"var newCenterPixel = new GPoint(%ld, %ld);"
          "var newCenterLatLng = map.fromContainerPixelToLatLng(newCenterPixel);"
          "map.panTo(newCenterLatLng);"
          "map.zoomIn();", 
         pixel.x, pixel.y];
    
    [self evalJS:script];
    
    if (self.delegate) {
        [self.delegate mapZoomUpdatedTo:[self getZoom]];
        [self.delegate mapCenterUpdatedToPixel:[self getCenterPixel]];
    }
}
//------------------------------------------------------------------------------
- (GLatLng) fromContainerPixelToLatLng:(GPoint)pixel {
    NSString *script = 
    	[NSString stringWithFormat:
	 	 @"map.fromContainerPixelToLatLng(new GPoint(%ld, %ld)).toString();", 
     	 pixel.x, pixel.y];
    
    NSString *latlngStr = [self evalJS:script];
    
    GLatLng latlng;
    sscanf([latlngStr UTF8String], "(%lf, %lf)", &latlng.lat, &latlng.lng);
    
    return latlng;
}
//------------------------------------------------------------------------------
- (GPoint) fromLatLngToContainerPixel:(GLatLng)latlng {
    NSString *script = 
        [NSString stringWithFormat:
         @"map.fromLatLngToContainerPixel(new GLatLng(%lf, %lf)).toString();", 
         latlng.lat, latlng.lng];
    
    NSString *pixelStr = [self evalJS:script];
    
    GPoint pixel;
    sscanf([pixelStr UTF8String], "(%ld, %ld)", &pixel.x, &pixel.y);
    
    return pixel;
}
//------------------------------------------------------------------------------
- (int) getBoundsZoomLevel:(GLatLngBounds)bounds {
    NSString *script;
    
    script = 
        [NSString stringWithFormat:
         @"map.getBoundsZoomLevel(new GLatLngBounds(new GLatLng(%lf, %lf), new GLatLng(%lf, %lf))).toString();", 
         bounds.minLat, bounds.minLng, bounds.maxLat, bounds.maxLng];
    
    NSString *zoomLevelStr = [self evalJS:script];
    
    int zoomLevel;
    sscanf([zoomLevelStr UTF8String], "%d", &zoomLevel);
    
    return zoomLevel;
}
//------------------------------------------------------------------------------
- (void) setMapType:(NSString*)mapType {
    [self evalJS:[NSString stringWithFormat:@"map.setMapType(%@);", mapType]];
}

//-- Private Methods -----------------------------------------------------------
- (void) loadMap {
    int width = (int) self.frame.size.width;
    int height = (int) self.frame.size.height;
    
    NSString *urlStr = 
        [NSString stringWithFormat:
         @"http://www.wenear.com/iphone-test?width=%d&height=%d&zoom=%d", 
         width, height, DEFAULT_ZOOM_LEVEL];
    
    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
}
//------------------------------------------------------------------------------
@end
