//
//  TouchMetricsTestAppDelegate.m
//  TouchCode
//
//  Created by Jonathan Wight on 10/21/09.
//  Copyright 2009 toxicsoftware.com. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "TouchMetricsTestAppDelegate.h"

#import "NSData_Extensions.h"
#import "CAnalyticsManager.h"

@implementation TouchMetricsTestAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize imagePickerController;

- (void)dealloc
{
[window release];
window = NULL;
[viewController release];
viewController = NULL;
[imagePickerController release];
imagePickerController = NULL;
//
[super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{    
[window addSubview:self.viewController.view];
[window makeKeyAndVisible];

NSDictionary *theMessage = [NSDictionary dictionaryWithObjectsAndKeys:@"test", @"test", NULL];
[[CAnalyticsManager sharedInstance] postMessage:theMessage];
[[CAnalyticsManager sharedInstance] postMessage:theMessage];
[[CAnalyticsManager sharedInstance] postMessage:theMessage];
[[CAnalyticsManager sharedInstance] postMessage:theMessage];
[[CAnalyticsManager sharedInstance] postMessage:theMessage];
[[CAnalyticsManager sharedInstance] postMessage:theMessage];
}

@end

