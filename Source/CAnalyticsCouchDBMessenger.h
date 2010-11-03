//
//  CAnalyticsCouchDBMessenger.h
//  TouchMetricsTest
//
//  Created by Jonathan Wight on 08/21/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCouchDBSession;
@class CAnalyticsManager;
@class CCouchDBServer;
@class CCouchDBDatabase;
@class CJSONSerializer;
@class COutgoingDataManager;
@class CPersistentOperationQueue;

@interface CAnalyticsCouchDBMessenger : NSObject {
    CAnalyticsManager *analyticsManager;
    CPersistentOperationQueue *operationQueue;
    CCouchDBSession *session;
    CCouchDBServer *server;
    CCouchDBDatabase *database;
    CJSONSerializer *serializer;
    COutgoingDataManager *outgoingDataManager;
    NSTimer *timer;
}

- (id)initWithAnalyticsManager:(CAnalyticsManager *)inAnalyticsManager;

- (void)sendDocument:(NSDictionary *)inDocument;

- (void)process;

- (void)synchronize;

@end
