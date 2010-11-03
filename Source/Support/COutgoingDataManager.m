//
//  COutgoingDataManager.m
//  TouchMetricsTest
//
//  Created by Jonathan Wight on 10/31/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "COutgoingDataManager.h"

#import "NSFileManager_Extensions.h"

@interface COutgoingDataManager ()
@property (readonly, retain) NSString *name;
@property (readonly, assign) NSUInteger maximumDataLength;
@property (readonly, retain) NSOperationQueue *operationQueue;
@property (readonly, retain) NSURL *directoryURL;
@property (readonly, retain) NSURL *currentFileURL;
@end

#pragma mark -

@implementation COutgoingDataManager

@synthesize name;
@synthesize maximumDataLength;
@synthesize operationQueue;
@synthesize currentFileURL;

- (id)initWithName:(NSString *)inName
    {
    if ((self = [super init]) != NULL)
        {
        name = [inName retain];
        maximumDataLength = 256 * 1024;
        }
    return(self);
    }

- (void)dealloc
    {
    // TODO
    //
    [super dealloc];
    }

#pragma mark -

- (NSOperationQueue *)operationQueue
    {
    @synchronized(self)
        {
        if (operationQueue == NULL)
            {
            operationQueue = [[NSOperationQueue alloc] init];
            operationQueue.maxConcurrentOperationCount = 1;
            }
        return(operationQueue);
        }
    }

- (NSURL *)directoryURL
    {
    @synchronized(self)
        {
        if (directoryURL == NULL)
            {
            NSError *theError = NULL;
            NSURL *theCachesURL = [[NSFileManager fileManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:NULL create:YES error:&theError];
            NSURL *theDirectoryURL = [theCachesURL URLByAppendingPathComponent:self.name];
            if ([[NSFileManager fileManager] createDirectoryAtPath:theDirectoryURL.path withIntermediateDirectories:YES attributes:NULL error:&theError] == NO)
                {
                NSLog(@"Error: %@", theError);
                }
            directoryURL = [theDirectoryURL retain];
            }
        return(directoryURL);
        }
    }

- (NSURL *)currentFileURL
    {
    @synchronized(self)
        {
        if (currentFileURL == NULL)
            {
            NSURL *theURL = [self.directoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Current.data"]];
            NSError *theError = NULL;
            if ([[NSFileManager fileManager] fileExistsAtPath:theURL.path] == NO)
                {
                if ([[NSData data] writeToURL:theURL options:0 error:&theError] == NO)
                    {
                    NSLog(@"Error: %@", theError);
                    }
                }
                
            currentFileURL = [theURL retain];
            }
        return(currentFileURL);
        }
    }

#pragma mark -

- (void)currentFileFull
    {
    @synchronized(self)
        {
        NSURL *theCurrentFileURL = self.currentFileURL;
        NSError *theError = NULL;
        NSDictionary *theAttributes = [[NSFileManager fileManager] attributesOfItemAtPath:theCurrentFileURL.path error:&theError];
        NSDate *theDate = [theAttributes fileModificationDate];
        NSURL *theURL = [self.directoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Full_%u_%u.data", (unsigned int)[theDate timeIntervalSinceReferenceDate], (unsigned int)arc4random()]];
        if ([[NSFileManager fileManager] moveItemAtURL:theCurrentFileURL toURL:theURL error:&theError] == NO)
            {
            NSLog(@"Error: %@", theError);
            }
        
        if ([[NSData data] writeToURL:theCurrentFileURL options:0 error:&theError] == NO)
            {
            NSLog(@"Error: %@", theError);
            }
        }
    }

- (void)writeData:(NSData *)inData
    {
    [self.operationQueue addOperationWithBlock:^(void) {
        NSURL *theCurrentFileURL = self.currentFileURL;
        NSError *theError = NULL;
        NSFileHandle *theFileHandle = [NSFileHandle fileHandleForWritingToURL:theCurrentFileURL error:&theError];
        [theFileHandle seekToEndOfFile];
        [theFileHandle writeData:inData];
        [theFileHandle synchronizeFile];
        [theFileHandle closeFile];

        NSDictionary *theAttributes = [[NSFileManager fileManager] attributesOfItemAtPath:theCurrentFileURL.path error:&theError];
        NSUInteger theFileSize = [theAttributes fileSize] + inData.length;
        if (theFileSize > self.maximumDataLength)
            {
            [self currentFileFull];
            }
        }];
    }
    
- (void)processFilesUsingBlock:(BOOL (^)(NSURL *inURL, BOOL *outStop))inBlock;
    {
//    ^(NSURL *url, NSError *error) { NSLog(@"%@", error); return(NO); }
    
    NSLog(@"%@", self.directoryURL);
//    NSFileManager *theFileManager = [[NSFileManager alloc] init];
//    NSDirectoryEnumerator *theEnumerator = [theFileManager enumeratorAtURL:self.directoryURL includingPropertiesForKeys:NULL options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles errorHandler:NULL];

    NSMutableArray *theURLs = [NSMutableArray array];

    NSDirectoryEnumerator *theEnumerator = [[NSFileManager fileManager] enumeratorAtPath:self.directoryURL.path];
    for (NSString *thePath in theEnumerator)
        {
        NSURL *theURL = [self.directoryURL URLByAppendingPathComponent:thePath];
        if ([[theURL lastPathComponent] isEqualToString:@"Current.data"])
            {
            continue;
            }
        else if ([[theURL pathExtension] isEqualToString:@"data"] == NO)
            {
            continue;
            }
        [theURLs addObject:theURL];
        }

    [theURLs sortUsingComparator:(id)^(NSURL *LHS, NSURL *RHS) { return([LHS.absoluteString compare:RHS.absoluteString]); }];

    for (NSURL *theURL in theURLs)
        {
        BOOL theStopFlag = NO;
        BOOL theProcessedFlag = inBlock(theURL, &theStopFlag);
        if (theProcessedFlag == YES)
            {
            NSError *theError = NULL;
            if ([[NSFileManager fileManager] removeItemAtURL:theURL error:&theError] == NO)
                {
                NSLog(@"Error: %@", theError);
                continue;
                }
            }

        if (theStopFlag == YES)
            {
            break;
            }
        }
    }
    
@end
