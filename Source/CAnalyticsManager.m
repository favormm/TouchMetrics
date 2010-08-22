//
//  CAnalyticsManager.m
//  TouchCode
//
//  Created by Jonathan Wight on 10/23/09.
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

#import "CAnalyticsManager.h"

#import "CBetterCoreDataManager.h"
#import "CJSONDataSerializer.h"
#import "NSData_Extensions.h"
#import "CURLOperation.h"
#import "CTemporaryData.h"
#import "CAnalyticsManager.h"
#import "NSManagedObjectContext_Extensions.h"
#import "CSerializedJSONData.h"
#import "CAnalyticsCouchDBMessenger.h"

static CAnalyticsManager *gInstance = NULL;

@interface CAnalyticsManager () <CCoreDataManagerDelegate>
@property (readwrite, nonatomic, retain) NSOperationQueue *operationQueue;
@property (readwrite, nonatomic, retain) CCoreDataManager *coreDataManager;
@property (readwrite, nonatomic, retain) CAnalyticsCouchDBMessenger *messenger;
@property (readwrite, nonatomic, assign) NSTimer *timer;

- (void)processMessages;
@end

#pragma mark -

@implementation CAnalyticsManager

@synthesize operationQueue;
@synthesize coreDataManager;
@synthesize messenger;
@synthesize timer;

+ (CAnalyticsManager *)sharedInstance
{
if (gInstance == NULL)
	{
	gInstance = [[self alloc] init];
	}
return(gInstance);
}

- (id)init
{
if ((self = [super init]) != NULL)
	{
    operationQueue = [[NSOperationQueue alloc] init];

	coreDataManager = [[CBetterCoreDataManager alloc] init];
    coreDataManager.name = @"Analytics";
	coreDataManager.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:coreDataManager.managedObjectContext];
	
    messenger = [[CAnalyticsCouchDBMessenger alloc] initWithAnalyticsManager:self];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(timerFire:) userInfo:NULL repeats:YES];
    }
return(self);
}

- (void)dealloc
{
[timer invalidate];
timer = NULL;

[operationQueue waitUntilAllOperationsAreFinished];
[operationQueue release];
operationQueue = NULL;

[coreDataManager release];
coreDataManager = NULL;

[messenger release];
messenger = NULL;
//
[super dealloc];
}

- (void)postMessage:(NSDictionary *)inMessage
{
__block CAnalyticsManager *_self = self;
NSBlockOperation *theOperation = [NSBlockOperation blockOperationWithBlock:^(void)
    {
    NSManagedObject *theObject = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:_self.coreDataManager.managedObjectContext];
    [theObject setValue:[NSDate date] forKey:@"created"];
    [theObject setValue:inMessage forKey:@"message"];
    [_self.coreDataManager save];
    }];
[self.operationQueue addOperation:theOperation];
}

- (void)processMessages
{
__block CAnalyticsManager *_self = self;
NSBlockOperation *theOperation = [NSBlockOperation blockOperationWithBlock:^(void) {
    NSMutableArray *theMessagesArray = [NSMutableArray array];

    NSError *theError = NULL;
    NSArray *theMessages = [_self.coreDataManager.managedObjectContext fetchObjectsOfEntityForName:@"Message" predicate:NULL error:&theError];
    for (NSManagedObject *theMessage in theMessages)
        {
        NSMutableDictionary *theMessageDictionary = [NSMutableDictionary dictionary];
        [theMessageDictionary setObject:[theMessage valueForKey:@"message"] forKey:@"message"];
        [theMessageDictionary setObject:[theMessage valueForKey:@"created"] forKey:@"created"];

        [theMessagesArray addObject:theMessageDictionary];

        [_self.coreDataManager.managedObjectContext deleteObject:theMessage];
        }

    [_self.coreDataManager save];

    NSDictionary *theMessage = [NSDictionary dictionaryWithObjectsAndKeys:
        [[NSBundle mainBundle] bundleIdentifier], @"CFBundleIdentifier",
        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], @"CFBundleVersion",
        theMessagesArray, @"messages",
        NULL];
        
    [_self.messenger sendDocument:theMessage];
    }];
[self.operationQueue addOperation:theOperation];
}

#pragma mark -

- (void)timerFire:(id)inParameter
{
NSError *theError = NULL;
NSUInteger theCount = [self.coreDataManager.managedObjectContext countOfObjectsOfEntityForName:@"Message" predicate:NULL error:&theError];
if (theCount > 10)
    {
    [self processMessages];
    }
}

- (void)managedObjectContextDidSaveNotification:(NSNotification *)notification
{
NSLog(@"DID SAVE");
}

@end
