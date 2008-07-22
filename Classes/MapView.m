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

#import "MapView.h"
#import "MapWebView.h"

#define DROPPED_TOUCH_MOVED_EVENTS_RATIO  (0.8)
#define ZOOM_IN_TOUCH_SPACING_RATIO       (0.75)
#define ZOOM_OUT_TOUCH_SPACING_RATIO      (1.5)

@interface MapView (Private)
- (void)	resetTouches;
- (CGFloat)	eucledianDistanceFromPoint:(CGPoint)from toPoint:(CGPoint)to;
- (void)	setPanningModeWithLocation:(CGPoint)location;
- (void)	setZoomingModeWithSpacing:(CGFloat)spacing;
- (BOOL)	isPanning;
- (BOOL)	isZooming;
@end

@implementation MapView

//-- Public Methods ------------------------------------------------------------
@synthesize mMapWebView;
@synthesize mOnClickHandler;
//------------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)frame {
    if (! (self = [super initWithFrame:frame]))
        return nil;
    
    self.onClickHandler = nil;
    self.autoresizesSubviews = YES;
    self.multipleTouchEnabled = YES;
    
    mMapWebView = [[[MapWebView alloc] initWithFrame:self.bounds] autorelease];
    [self addSubview:mMapWebView];
    
    [self resetTouches];
    
    return self;
}
//------------------------------------------------------------------------------
- (void) dealloc {
    [mMapWebView release];
	[super dealloc];
}

//-- Touch Events Handling Methods ---------------------------------------------
- (void) touchesCanceled {
    [self resetTouches];
}
//------------------------------------------------------------------------------
- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    mTouchMovedEventCounter = 0;
    
    NSSet *allTouches = [event allTouches];
    
    switch ([allTouches count]) {
        case 1: {
            // potential pan gesture
            UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
            [self setPanningModeWithLocation:[touch locationInView:self]];
        } break;
            
        case 2: {
            // potential zoom gesture
            UITouch *touch0 = [[allTouches allObjects] objectAtIndex:0];
            UITouch *touch1 = [[allTouches allObjects] objectAtIndex:1];
            CGFloat spacing = 
            [self eucledianDistanceFromPoint:[touch0 locationInView:self] 
                                     toPoint:[touch1 locationInView:self]];
            [self setZoomingModeWithSpacing:spacing];
        } break;
            
        default:
            [self resetTouches];
            break;
    }
}
//------------------------------------------------------------------------------
- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    
    if (++mTouchMovedEventCounter % (int)(1.0 / (1.0 - DROPPED_TOUCH_MOVED_EVENTS_RATIO)))
        return;
    
    NSSet *allTouches = [event allTouches];
    
    switch ([allTouches count]) {
        case 1: {
            // potential pan gesture
            if (! [self isPanning]) {
                [self resetTouches];
                break;
            }
            UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
            CGPoint currentLocation = [touch locationInView:self];
            int dX = (int)(currentLocation.x - mLastTouchLocation.x);
            int dY = (int)(currentLocation.y - mLastTouchLocation.y);
            [self setPanningModeWithLocation:[touch locationInView:self]];
            
            [mMapWebView moveByDx:dX dY:dY];
        } break;
            
        case 2: {
            // potential zoom gesture
            if (! [self isZooming]) {
                [self resetTouches];
                break;
            }
            UITouch *touch0 = [[allTouches allObjects] objectAtIndex:0];
            UITouch *touch1 = [[allTouches allObjects] objectAtIndex:1];
            CGFloat spacing = 
            [self eucledianDistanceFromPoint:[touch0 locationInView:self] 
                                     toPoint:[touch1 locationInView:self]];
            CGFloat spacingRatio = spacing / mLastTouchSpacing;
            
            if (spacingRatio >= ZOOM_OUT_TOUCH_SPACING_RATIO) {
                [self setZoomingModeWithSpacing:spacing];
                [mMapWebView zoomIn];
            }
            else if (spacingRatio <= ZOOM_IN_TOUCH_SPACING_RATIO) {
                [self setZoomingModeWithSpacing:spacing];
                [mMapWebView zoomOut];
            }
        } break;
            
        default:
            [self resetTouches];
            break;
    }
}
//------------------------------------------------------------------------------
- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    
    NSSet *allTouches = [event allTouches];
    
    switch ([allTouches count]) {
        case 1: {
            UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
            switch (touch.tapCount) {
                case 1:
                    if (mOnClickHandler)
                        [self performSelector:mOnClickHandler];
                    break;
                
                case 2: {
                    CGPoint pixel = [touch locationInView:self];
                    [mMapWebView panToCenterWithPixel:GPointMake(pixel.x, pixel.y)];
                } break;
            }
        } break;
    }
    
    [self resetTouches];
}

//-- Private Methods -----------------------------------------------------------
- (void) resetTouches {
    mLastTouchLocation = CGPointMake(-1, -1);
    mLastTouchSpacing = -1;
}
//------------------------------------------------------------------------------
- (CGFloat) eucledianDistanceFromPoint:(CGPoint)from toPoint:(CGPoint)to {
    float dX = to.x - from.x;
    float dY = to.y - from.y;
    
    return sqrt(dX * dX + dY * dY);
}
//------------------------------------------------------------------------------
- (void) setPanningModeWithLocation:(CGPoint)location {
    mLastTouchLocation = location;
    mLastTouchSpacing = -1;
}
//------------------------------------------------------------------------------
- (void) setZoomingModeWithSpacing:(CGFloat)spacing {
    mLastTouchLocation = CGPointMake(-1, -1);
    mLastTouchSpacing = spacing;
}
//------------------------------------------------------------------------------
- (BOOL) isPanning {
    return mLastTouchLocation.x > 0 ? YES : NO;
}
//------------------------------------------------------------------------------
- (BOOL) isZooming {
    return mLastTouchSpacing > 0 ? YES : NO;
}
//------------------------------------------------------------------------------
@end
