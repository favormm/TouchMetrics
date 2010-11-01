//
//  CCodingCouchDBURLOperation.h
//  TouchMetricsTest
//
//  Created by Jonathan Wight on 08/21/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CCouchDBURLOperation.h"

#import "CPersistentOperationQueue.h"

@interface CCodingCouchDBURLOperation : CCouchDBURLOperation <CHibernating, NSCoding> {

}

@end
