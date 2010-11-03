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
#import "CJSONSerializer.h"
#import "COutgoingDataManager.h"
#import "CJSONSerializedData.h"

@interface CAnalyticsCouchDBMessenger () <CPersistentOperationQueueDelegate>
@property (readwrite, nonatomic, assign) CAnalyticsManager *analyticsManager;
@property (readwrite, nonatomic, retain) CPersistentOperationQueue *operationQueue;
@property (readwrite, nonatomic, retain) CCouchDBSession *session;
@property (readwrite, nonatomic, retain) CCouchDBServer *server;
@property (readwrite, nonatomic, retain) CCouchDBDatabase *database;
@property (readwrite, nonatomic, retain) CJSONSerializer *serializer;
@property (readwrite, nonatomic, retain) COutgoingDataManager *outgoingDataManager;
@property (readwrite, nonatomic, assign) NSTimer *timer;

- (void)invalidate;
@end

#pragma mark -

@implementation CAnalyticsCouchDBMessenger

@synthesize analyticsManager;
@synthesize session;
@synthesize server;
@synthesize database;
@synthesize serializer;
@synthesize outgoingDataManager;
@synthesize operationQueue;
@synthesize timer;

- (id)initWithAnalyticsManager:(CAnalyticsManager *)inAnalyticsManager;
    {
    if ((self = [super init]) != NULL)
        {
        analyticsManager = inAnalyticsManager;
        
        operationQueue = [[CPersistentOperationQueue alloc] initWithName:@"Analytics/Queue"];
        operationQueue.delegate = self;

        session = [[CCouchDBSession alloc] init];
        session.operationQueue = operationQueue;
        session.URLOperationClass = [CCodingCouchDBURLOperation class];
        
        server = [[CCouchDBServer alloc] initWithSession:session URL:[NSURL URLWithString:@"http://touchcode.couchone.com:5984/"]];
        
        database = [[CCouchDBDatabase alloc] initWithServer:server name:@"touch-analytics"];
        
        serializer = [session.serializer retain];
        
        outgoingDataManager = [[COutgoingDataManager alloc] initWithName:@"Analytics/Outgoing"];
   
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication] queue:NULL usingBlock:^(NSNotification *arg1) { [self invalidate]; }];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:[UIApplication sharedApplication] queue:NULL usingBlock:^(NSNotification *arg1) { [self invalidate]; }];
        timer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(timerFire:) userInfo:NULL repeats:YES];
        }
    return(self);
    }

- (void)dealloc
    {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    analyticsManager = NULL;

    [operationQueue release];
    operationQueue = NULL;

    [outgoingDataManager release];
    outgoingDataManager = NULL;

    [session release];
    session = NULL;

    [server release];
    server = NULL;

    [database release];
    database = NULL;
    
    [super dealloc];
    }

#pragma mark -

- (void)sendDocument:(NSDictionary *)inDocument;
    {
    NSError *theError = NULL;
    NSMutableData *theData = [[[self.serializer serializeDictionary:inDocument error:&theError] mutableCopy] autorelease];
    NSAssert1(theData != NULL, @"serializing data failed: %@", theError);
    [theData appendBytes:",\n" length:2];
    [self.outgoingDataManager writeData:theData];
    }

- (void)process
    {
    NSLog(@"PROCESS");
    
    NSData *theHeaderData = [@"[" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *theFooterData = [@"]" dataUsingEncoding:NSUTF8StringEncoding];
    
    id theBlock = ^(NSURL *inURL, BOOL *outStop)
        {
        NSError *theError = NULL;
        
        NSMutableData *theData = [NSMutableData data];
        
        [theData appendData:theHeaderData];
        NSData *theMessageData = [NSData dataWithContentsOfURL:inURL options:NSDataReadingMapped error:&theError];
        [theData appendData:theMessageData];
        [theData appendData:theFooterData];

        CJSONSerializedData *theJSONData = [[[CJSONSerializedData alloc] initWithData:theData] autorelease];

        NSOperation *theOperation = [self.database operationToBulkCreateDocuments:theJSONData successHandler:^(id inParameter) { NSLog(@"POST SUCCESS: %@", inParameter); } failureHandler:^(NSError *inError) { NSLog(@"POST ERROR: %@", inError); }];
        [self.operationQueue addOperation:theOperation];
        
        return(YES);
        };
    
    [self.outgoingDataManager processFilesUsingBlock:theBlock];
    }

- (void)synchronize
    {
    [self process];
    }

- (void)invalidate
    {
    [timer invalidate];
    timer = NULL;
    
    [self.operationQueue hibernate];
    }

#pragma mark -

- (void)timerFire:(id)inParameter
    {
    [self process];
    }

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
