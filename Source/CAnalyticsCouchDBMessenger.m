//
//  CAnalyticsCouchDBMessenger.m
//  TouchMetricsTest
//
//  Created by Jonathan Wight on 08/21/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CAnalyticsCouchDBMessenger.h"

#import "CCouchDBServer.h"
#import "CCouchDBDatabase.h"
#import "CPersistentOperationQueue.h"
#import "CAnalyticsManager.h"
#import "CURLOperation.h"
#import "CCouchDBSession.h"
#import "CCodingCouchDBURLOperation.h"

@interface CAnalyticsCouchDBMessenger () <CPersistentOperationQueueDelegate>
@property (readwrite, nonatomic, assign) CAnalyticsManager *analyticsManager;
@property (readwrite, nonatomic, retain) CCouchDBSession *session;
@property (readwrite, nonatomic, retain) CCouchDBServer *server;
@property (readwrite, nonatomic, retain) CCouchDBDatabase *database;
@property (readwrite, nonatomic, retain) CPersistentOperationQueue *persistentRequestManager;
@end

#pragma mark -

@implementation CAnalyticsCouchDBMessenger

@synthesize analyticsManager;
@synthesize session;
@synthesize server;
@synthesize database;
@synthesize persistentRequestManager;

- (id)initWithAnalyticsManager:(CAnalyticsManager *)inAnalyticsManager;
{
if ((self = [super init]) != NULL)
    {
    analyticsManager = inAnalyticsManager;
    
    persistentRequestManager = [[CPersistentOperationQueue alloc] init];
    persistentRequestManager.delegate = self;

    session = [[CCouchDBSession alloc] init];
    session.operationQueue = persistentRequestManager;
    session.URLOperationClass = [CCodingCouchDBURLOperation class];
    
    server = [[CCouchDBServer alloc] initWithSession:session URL:[NSURL URLWithString:@"http://localhost:5984/"]];
    
    database = [[CCouchDBDatabase alloc] initWithServer:server name:@"touchanalytics"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:NULL];
    }
return(self);
}

- (void)dealloc
{
analyticsManager = NULL;
[session release];
session = NULL;
[server release];
server = NULL;
[database release];
database = NULL;
[persistentRequestManager release];
persistentRequestManager = NULL;
//
[super dealloc];
}

- (void)invalidate
{
[self.persistentRequestManager hibernate];
}

- (void)sendDocument:(NSDictionary *)inDocument;
{
[self.database createDocument:inDocument successHandler:^(id inParameter) { NSLog(@"SUCCESS"); } failureHandler:^(NSError *inError) { NSLog(@"ERROR: %@", inError); }];
}

- (void)applicationWillResignActive:(NSNotification *)inNotification
{
[self invalidate];
}

- (void)applicationWillTerminate:(NSNotification *)inNotification
{
[self invalidate];
}

#pragma mark -

- (void)persistentOperationQueue:(CPersistentOperationQueue *)inPersistentOperationQueue didUnhibernateOperation:(NSOperation *)inOperation;
{
if ([inOperation isKindOfClass:[CCodingCouchDBURLOperation class]])
    {
    CCodingCouchDBURLOperation *theOperation = (CCodingCouchDBURLOperation *)inOperation;
    theOperation.successHandler = ^(id inParameter) { NSLog(@"SUCCESS"); };
    theOperation.failureHandler = ^(NSError *inError) { NSLog(@"ERROR: %@", inError); };
    }

}

@end
