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

#import "CJSONSerializer.h"
#import "NSData_Extensions.h"
#import "CURLOperation.h"
#import "CTemporaryData.h"
#import "CAnalyticsManager.h"
#import "CAnalyticsCouchDBMessenger.h"
#import "COutgoingDataManager.h"

static CAnalyticsManager *gInstance = NULL;

@interface CAnalyticsManager ()
@property (readwrite, nonatomic, retain) NSOperationQueue *operationQueue;
@property (readwrite, nonatomic, retain) COutgoingDataManager *outgoingDataManager;
@property (readwrite, nonatomic, retain) CAnalyticsCouchDBMessenger *messenger;
@property (readwrite, nonatomic, assign) NSTimer *timer;

- (void)processMessages;
@end

#pragma mark -

@implementation CAnalyticsManager

@synthesize operationQueue;
@synthesize outgoingDataManager;
@synthesize messenger;
@synthesize timer;
@synthesize session;

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

        outgoingDataManager = [[COutgoingDataManager alloc] initWithName:@"analytics"];
        
        messenger = [[CAnalyticsCouchDBMessenger alloc] initWithAnalyticsManager:self];
        
        timer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(timerFire:) userInfo:NULL repeats:YES];
        
        [self processMessages];
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

    [outgoingDataManager release];
    outgoingDataManager = NULL;

    [messenger release];
    messenger = NULL;
    //
    [super dealloc];
    }

#pragma mark -

- (NSString *)session
    {
    if (session == NULL)
        {
        session = [[NSString alloc] initWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
        }
    return(session);
    }

#pragma mark -

- (void)postMessage:(NSDictionary *)inMessage
    {
    NSDictionary *theFullMessage = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]], @"timestamp",
        self.session, @"session",
        inMessage, @"message",
        NULL];
    
    CJSONSerializer *theSerializer = [CJSONSerializer serializer];
    NSError *theError = NULL;
    NSMutableData *theData = [[[theSerializer serializeDictionary:theFullMessage error:&theError] mutableCopy] autorelease];
    [theData appendBytes:",\n" length:2];
    [self.outgoingDataManager writeData:theData];
    }

- (void)synchronize
    {
    }

- (void)processMessages
    {
    NSLog(@"Process Messages");
    
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
        
        [self.messenger sendBatchData:theData];
        
        return(YES);
        };
    
    [self.outgoingDataManager processFilesUsingBlock:theBlock];
    }

#pragma mark -

- (void)timerFire:(id)inParameter
    {
    [self processMessages];
    }

@end
