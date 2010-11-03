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
@property (readwrite, nonatomic, retain) CAnalyticsCouchDBMessenger *messenger;
@end

#pragma mark -

@implementation CAnalyticsManager

@synthesize messenger;
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
        messenger = [[CAnalyticsCouchDBMessenger alloc] initWithAnalyticsManager:self];
        }
    return(self);
    }

- (void)dealloc
    {
    [messenger release];
    messenger = NULL;
    //
    [super dealloc];
    }

#pragma mark -

- (id)session
    {
    if (session == NULL)
        {
        session = [[NSDate date] retain];
        }
    return(session);
    }

#pragma mark -

- (void)postEvent:(NSDictionary *)inEvent
    {
    NSMutableDictionary *theFullMessage = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [NSDate date], @"timestamp",
        self.session, @"session",
        @"event", @"type",
        NULL];

    [theFullMessage addEntriesFromDictionary:inEvent];

    [self.messenger sendDocument:theFullMessage];
    }

- (void)startEvent:(NSDictionary *)inEvent
    {
    NSMutableDictionary *theFullMessage = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [NSDate date], @"timestamp",
        self.session, @"session",
        @"start_event", @"type",
        NULL];

    [theFullMessage addEntriesFromDictionary:inEvent];

    [self.messenger sendDocument:theFullMessage];
    }
    
- (void)endEvent:(NSDictionary *)inEvent
    {
    NSMutableDictionary *theFullMessage = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [NSDate date], @"timestamp",
        self.session, @"session",
        @"end_event", @"type",
        NULL];

    [theFullMessage addEntriesFromDictionary:inEvent];

    [self.messenger sendDocument:theFullMessage];
    }

- (void)synchronize
    {
    [self.messenger synchronize];
    }

@end
