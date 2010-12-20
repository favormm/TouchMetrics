//
//  CAutomaticAnalyticsManager.m
//  TouchMetricsTest
//
//  Created by Jonathan Wight on 08/21/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CAutomaticAnalyticsManager.h"

#import "Swizzle.h"

#include <sys/param.h>
#include <sys/mount.h>

#import "CBetterLocationManager.h"
#import "CLLocation_Extensions.h"
#import "CLLocation_GeohashExtensions.h"

static IMP gOldViewDidAppearImp = NULL;
static IMP gOldViewWillDisappearImp = NULL;

@interface UIViewController (UIViewController_Swizzled)

- (void)myViewDidAppear:(BOOL)animated;
- (void)myViewWillDisappear:(BOOL)animated;

@end

#pragma mark -

@implementation CAutomaticAnalyticsManager

+ (void)load
    {
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];

    Swizzle([UIViewController class], @selector(viewDidAppear:), @selector(myViewDidAppear:), &gOldViewDidAppearImp);
    Swizzle([UIViewController class], @selector(viewWillDisappear:), @selector(myViewWillDisappear:), &gOldViewWillDisappearImp);

	id theBlock = ^(NSNotification *arg1) {
		[[CAutomaticAnalyticsManager sharedInstance] postEvent:[NSDictionary dictionaryWithObject:arg1.name forKey:@"Notification"]];
		};

	[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:NULL queue:NULL usingBlock:theBlock];
	[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:NULL queue:NULL usingBlock:theBlock];
	[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:NULL queue:NULL usingBlock:theBlock];
	[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:NULL queue:NULL usingBlock:theBlock];
	[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:NULL queue:NULL usingBlock:theBlock];
	[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:NULL queue:NULL usingBlock:theBlock];

	id theLaunchBlock = ^(NSNotification *arg1) {
		NSMutableDictionary *theDictionary = [NSMutableDictionary dictionary];
		
		if (arg1.userInfo)
			{
			[theDictionary setObject:arg1.userInfo forKey:@"Launch.userInfo"];
			}
		
		[theDictionary setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleNameKey] forKey:@"App.name"];
		[theDictionary setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleIdentifierKey] forKey:@"App.identifier"];
		[theDictionary setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey] forKey:@"App.version"];

		UIScreen *theScreen = [UIScreen mainScreen];
		[theDictionary setObject:[NSNumber numberWithFloat:theScreen.bounds.size.width] forKey:@"UIScreen.mainScreen.width"];
		[theDictionary setObject:[NSNumber numberWithFloat:theScreen.bounds.size.height] forKey:@"UIScreen.mainScreen.height"];

		[theDictionary setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey] forKey:@"App.version"];

		[theDictionary setObject:((NSLocale *)[NSLocale currentLocale]).localeIdentifier forKey:@"NSLocale.currentLocale.localeIdentifier"];
		[theDictionary setObject:((NSLocale *)[NSLocale systemLocale]).localeIdentifier forKey:@"NSLocale.systemLocale.localeIdentifier"];

		struct statfs theStat;
		statfs([[[NSBundle mainBundle] bundlePath] UTF8String], &theStat);
		[theDictionary setObject:[NSNumber numberWithUnsignedLongLong:theStat.f_bsize] forKey:@"f_bsize"];
		[theDictionary setObject:[NSNumber numberWithUnsignedLongLong:theStat.f_blocks] forKey:@"f_blocks"];
		[theDictionary setObject:[NSNumber numberWithUnsignedLongLong:theStat.f_bfree] forKey:@"f_bfree"];
		[theDictionary setObject:[NSNumber numberWithUnsignedLongLong:theStat.f_bavail] forKey:@"f_bavail"];
		
		
		UIDevice *theDevice = [UIDevice currentDevice];
		[theDictionary setObject:theDevice.name forKey:@"UIDevice.name"];
		[theDictionary setObject:theDevice.model forKey:@"UIDevice.model"];
		[theDictionary setObject:theDevice.localizedModel forKey:@"UIDevice.localizedModel"];
		[theDictionary setObject:theDevice.systemName forKey:@"UIDevice.systemName"];
		[theDictionary setObject:theDevice.systemVersion forKey:@"UIDevice.systemVersion"];
		[theDictionary setObject:[NSNumber numberWithInt:theDevice.orientation] forKey:@"UIDevice.orientation"];
//		[theDictionary setObject:theDevice.obfuscatedDeviceIdentifier forKey:@"UIDevice.obfuscatedDeviceIdentifier"];

		[[CAutomaticAnalyticsManager sharedInstance] postEvent:theDictionary];
		};

	[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:NULL queue:NULL usingBlock:theLaunchBlock];

	__block id theLocationObserver = NULL;
	id theLocationBlock = ^(NSNotification *arg1) {
		CLLocation *theLocation = [arg1.userInfo objectForKey:kBetterLocationManagerNewLocationKey];
		if (theLocation.stale == NO)
			{
			NSDictionary *theDictionary = [NSDictionary dictionaryWithObject:[theLocation geohashWithPrecision:5] forKey:@"Location"];
			[[CAutomaticAnalyticsManager sharedInstance] postEvent:theDictionary];

			if (theLocationObserver)
				{
				[[NSNotificationCenter defaultCenter] removeObserver:theLocationObserver];
				}
			}
		};

	theLocationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kBetterLocationManagerDidUpdateToLocationNotification object:NULL queue:NULL usingBlock:theLocationBlock];

    [thePool release];
    }

@end

#pragma mark -

@implementation UIViewController (UIViewController_Swizzled)

- (void)myViewDidAppear:(BOOL)animated
    {
    gOldViewDidAppearImp(self, @selector(viewDidAppear:), animated);

    NSMutableDictionary *theMessage = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        @"viewDidAppear:", @"selector",
        NSStringFromClass([self class]), @"class",
        [NSNumber numberWithUnsignedInteger:(NSUInteger)self], @"id",
        NULL];

    if (self.title)
        {
        [theMessage setObject:self.title forKey:@"title"];
        }

    if (self.nibName)
        {
        [theMessage setObject:self.nibName forKey:@"nibName"];
        }


    [[CAnalyticsManager sharedInstance] postEvent:theMessage];
    }

- (void)myViewWillDisappear:(BOOL)animated
    {
    NSMutableDictionary *theMessage = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        @"viewWillDisappear:", @"selector",
        NSStringFromClass([self class]), @"class",
        NULL];

    if (self.title)
        {
        [theMessage setObject:self.title forKey:@"title"];
        }

    [[CAnalyticsManager sharedInstance] postEvent:theMessage];

    gOldViewWillDisappearImp(self, @selector(viewWillDisappear:), animated);
    }

@end
