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
@class CPersistentOperationQueue;

@interface CAnalyticsCouchDBMessenger : NSObject {
    CAnalyticsManager *analyticsManager;
    CCouchDBSession *session;
    CCouchDBServer *server;
    CCouchDBDatabase *database;
    CPersistentOperationQueue *persistentRequestManager;
}

- (id)initWithAnalyticsManager:(CAnalyticsManager *)inAnalyticsManager;

- (void)sendDocument:(NSDictionary *)inDocument;
- (void)sendBatchData:(NSData *)inData;

@end
