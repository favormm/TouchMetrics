//
//  CPersistentRequestManager.m
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

#import "CPersistentRequestManager.h"

#import "CCoreDataManager.h"
#import "CURLOperation.h"

#import "NSOperationQueue_Extensions.h"
#import "NSManagedObjectContext_Extensions.h"

@interface CPersistentRequestManager ()
@property (readwrite, retain) CCoreDataManager *coreDataManager;
@property (readwrite, retain) NSOperationQueue *operationQueue;
@property (readwrite, assign) NSTimer *scanTimer;

- (void)cleanup;
@end

#pragma mark -

@implementation CPersistentRequestManager

@synthesize coreDataManager;
@synthesize operationQueue;
@synthesize scanTimer;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	#if 0
	NSURL *theModelURL = [NSURL URLWithString:@"file://localhost/Volumes/Users/schwa/Development/Products/Debug/Request.mom"];
	coreDataManager = [[CCoreDataManager alloc] initWithModelUrl:theModelURL persistentStoreName:@"Request" forceReplace:NO storeType:NULL storeOptions:NULL];
	#else
	coreDataManager = [[CCoreDataManager alloc] initWithModelName:@"Request" persistentStoreName:@"Request" forceReplace:NO storeType:NULL storeOptions:NULL];
	#endif
	coreDataManager.delegate = self;

	operationQueue = [[NSOperationQueue defaultOperationQueue] retain];

	[self cleanup];
	}
return(self);
}

- (void)addRequest:(NSURLRequest *)inRequest
{
NSInvocationOperation *theOperation = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(addRequest_:) object:inRequest] autorelease];
[self.operationQueue addOperation:theOperation];
}

- (void)cleanup
{
NSError *theError = NULL;
NSPredicate *thePredicate = [NSPredicate predicateWithFormat:@"inProgress == YES"];
NSArray *theRequests = [self.coreDataManager.managedObjectContext fetchObjectsOfEntityForName:@"Request" predicate:thePredicate error:&theError];
for (NSManagedObject *theRequestObject in theRequests)
	{
	[theRequestObject setValue:[NSNumber numberWithBool:NO] forKey:@"inProgress"];
	}

[self.coreDataManager save];
}

#pragma mark -

- (void)managedObjectContextDidSaveNotification:(NSNotification *)notification
{
if ([NSThread mainThread] != [NSThread currentThread])
	{
	[self performSelectorOnMainThread:@selector(managedObjectContextDidSaveNotification:) withObject:notification waitUntilDone:YES];
	return;
	}

NSLog(@"DID SAVE NOTIFICATION");
[self.coreDataManager.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
[self.coreDataManager save];
}

- (void)addRequest_:(NSURLRequest *)inRequest
{
NSAssert(self.coreDataManager.managedObjectContext != NULL, @"Managed object context is NULL");

NSManagedObject *theObject = [NSEntityDescription insertNewObjectForEntityForName:@"Request" inManagedObjectContext:self.coreDataManager.managedObjectContext];
[theObject setValue:[NSDate date] forKey:@"created"];
[theObject setValue:inRequest forKey:@"request"];
[self.coreDataManager save];
NSLog(@"Done");

NSInvocationOperation *theOperation = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(scanRequests_) object:NULL] autorelease];
[self.operationQueue addOperation:theOperation];
}

- (void)scanRequests_
{
NSLog(@"SCAN REQUESTS");

NSError *theError = NULL;
NSPredicate *thePredicate = [NSPredicate predicateWithFormat:@"inProgress == NO"];
NSArray *theRequests = [self.coreDataManager.managedObjectContext fetchObjectsOfEntityForName:@"Request" predicate:thePredicate error:&theError];
for (NSManagedObject *theRequestObject in theRequests)
	{
	NSLog(@"Creating a new CURLOperation...");
	
	[theRequestObject setValue:[NSNumber numberWithBool:YES] forKey:@"inProgress"];

	NSURLRequest *theURLRequest = [theRequestObject valueForKey:@"request"];
	CURLOperation *theOperation = [[[CURLOperation alloc] initWithRequest:theURLRequest] autorelease];
	theOperation.userInfo = [theRequestObject objectID];
	
	[theOperation addObserver:self forKeyPath:@"isFinished" options:0 context:NULL]; // TODO fix context
	[theOperation addObserver:self forKeyPath:@"isCancelled" options:0 context:NULL]; // TODO fix context
	
	[self.operationQueue addOperation:theOperation];
	}

[self.coreDataManager save];
}

#pragma mark -

- (void)coreDataManager:(CCoreDataManager *)inCoreDataManager didCreateNewManagedObjectContext:(NSManagedObjectContext *)inManagedObjectContext;
{
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:inManagedObjectContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
CURLOperation *theOperation = object;
NSManagedObjectID *theObjectID = theOperation.userInfo;
NSError *theError = NULL;
NSManagedObject *theRequestObject = [self.coreDataManager.managedObjectContext existingObjectWithID:theObjectID error:&theError];
if (theOperation.error != NULL)
	{
	[theRequestObject setValue:[NSNumber numberWithBool:NO] forKey:@"inProgress"];
	[theRequestObject setValue:[NSNumber numberWithInteger:[[theRequestObject valueForKey:@"attempts"] integerValue] + 1] forKey:@"attempts"];

	if (self.scanTimer == NULL)
		{
		self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(scanTimer:) userInfo:NULL repeats:NO];
		}
	}
else
	{
	NSLog(@"SUCCESS!");
	[self.coreDataManager.managedObjectContext deleteObject:theRequestObject];
	}

[theOperation removeObserver:self forKeyPath:@"isFinished"];
[theOperation removeObserver:self forKeyPath:@"isCancelled"];


[self.coreDataManager save];
}

- (void)scanTimer:(id)inParameter
{
self.scanTimer = NULL;

[self scanRequests_];
}

@end
