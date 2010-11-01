//
//  COutgoingDataManager.h
//  TouchMetricsTest
//
//  Created by Jonathan Wight on 10/31/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

// TODO bad class name. rename.
@interface COutgoingDataManager : NSObject {
    NSString *name;
    NSUInteger maximumDataLength;
    NSOperationQueue *operationQueue;
    NSURL *directoryURL;
    NSURL *currentFileURL;
}

- (id)initWithName:(NSString *)inName;

- (void)writeData:(NSData *)inData;

- (void)processFilesUsingBlock:(BOOL (^)(NSURL *inURL, BOOL *outStop))inBlock;

@end
