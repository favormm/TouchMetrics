//
//  CAutomaticAnalyticsManager.m
//  TouchMetricsTest
//
//  Created by Jonathan Wight on 08/21/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CAutomaticAnalyticsManager.h"

#import "Swizzle.h"

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

[thePool release];
}

- (id)init
{
if ((self = [super init]) != NULL)
    {
    }
return(self);
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


[[CAnalyticsManager sharedInstance] postMessage:theMessage];
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

[[CAnalyticsManager sharedInstance] postMessage:theMessage];

gOldViewWillDisappearImp(self, @selector(viewWillDisappear:), animated);
}

@end
