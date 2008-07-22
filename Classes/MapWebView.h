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

#import <UIKit/UIKit.h>

typedef struct {
    double minLat;
    double minLng;
    double maxLat;
    double maxLng;
} GLatLngBounds;

typedef struct {
    long x;
    long y;
} GPoint;

typedef struct {
    double lat;
    double lng;
} GLatLng;

#define GLatLngBoundsMake(minLat, minLng, maxLat, maxLng) \
                                (GLatLngBounds){(double)(minLat), (double)(minLng), \
                                                (double)(maxLat), (double)(maxLng)}
#define GPointMake(x, y)        (GPoint){(long)(x), (long)(y)}
#define GLatLngMake(lat, lng)   (GLatLng){(double)(lat), (double)(lng)}
#define GPoint2CGPoint(p)       CGPointMake((p).x, (p).y)

#define G_NORMAL_MAP            @"G_NORMAL_MAP"
#define G_SATELLITE_MAP         @"G_SATELLITE_MAP"
#define G_HYBRID_MAP            @"G_HYBRID_MAP"
#define G_PHYSICAL_MAP          @"G_PHYSICAL_MAP"
#define G_MOON_ELEVATION_MAP    @"G_MOON_ELEVATION_MAP"
#define G_MOON_VISIBLE_MAP      @"G_MOON_VISIBLE_MAP"
#define G_MARS_ELEVATION_MAP    @"G_MARS_ELEVATION_MAP"
#define G_MARS_VISIBLE_MAP      @"G_MARS_VISIBLE_MAP"
#define G_MARS_INFRARED_MAP     @"G_MARS_INFRARED_MAP"
#define G_SKY_VISIBLE_MAP       @"G_SKY_VISIBLE_MAP"

@protocol MapWebViewDelegate
- (void) mapZoomUpdatedTo:(int)zoomLevel;
- (void) mapCenterUpdatedToLatLng:(GLatLng)latlng;
- (void) mapCenterUpdatedToPixel:(GPoint)pixel;
@end

@interface MapWebView : UIWebView {
@private
    id <MapWebViewDelegate> mDelegate;
}
@property (retain, getter = delegate) id <MapWebViewDelegate> mDelegate;

- (void)      didMoveToSuperview;
- (NSString*) evalJS:(NSString*)script;
- (void)      moveByDx:(int)dX dY:(int)dY;

//-- Methods corresponding to Google Maps Javascript API methods ---------------
- (int)       getZoom;
- (void)      setZoom:(int)zoomLevel;
- (void)      zoomIn;
- (void)      zoomOut;
- (GLatLng)   getCenterLatLng;
- (GPoint)    getCenterPixel;
- (void)      setCenterWithPixel:(GPoint)pixel;
- (void)      setCenterWithLatLng:(GLatLng)latlng;
- (void)      panToCenterWithPixel:(GPoint)pixel;
- (GLatLng)   fromContainerPixelToLatLng:(GPoint)pixel;
- (GPoint)    fromLatLngToContainerPixel:(GLatLng)latlng;
- (int)       getBoundsZoomLevel:(GLatLngBounds)bounds;
- (void)      setMapType:(NSString*)mapType;
@end
