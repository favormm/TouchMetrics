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

#import "CPersistentOperationQueue.h"

@interface CPersistentOperationQueue ()
@end

#pragma mark -

@implementation CPersistentOperationQueue

@synthesize delegate;

- (id)init
{
if ((self = [super init]) != NULL)
	{
//    [self setSuspended:YES];
    [self unhibernate];
	}
return(self);
}

- (void)dealloc
{
[self hibernate];

delegate = NULL;
//
[super dealloc];
}

#pragma mark -

- (void)addOperation:(NSOperation *)inOperation
{
void (^theOldBlock)(void) = inOperation.completionBlock;
inOperation.completionBlock = ^(void) { 
    if (theOldBlock) theOldBlock();
    };
[super addOperation:inOperation];
}

#pragma mark -

- (NSString *)hibernationPath
{
NSString *thePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
thePath = [thePath stringByAppendingPathComponent:@"PersistentOperations"];
NSError *theError = NULL;
if ([[NSFileManager defaultManager] createDirectoryAtPath:thePath withIntermediateDirectories:YES attributes:NULL error:&theError] == NO)
    {
    NSLog(@"%@", theError);
    }
return(thePath);
}

- (void)hibernate
{
BOOL theIsSuspendedFlag = [self isSuspended];
[self setSuspended:YES];
//
for (NSOperation *theOperation in self.operations)
    {
    if ([theOperation isFinished] == YES)
        continue;
    if ([theOperation isCancelled] == YES)
        continue;
    if ([theOperation isExecuting] == YES)
        continue;
    if ([theOperation conformsToProtocol:@protocol(CHibernating)])
        {
        NSData *theData = [NSKeyedArchiver archivedDataWithRootObject:(id <CHibernating>)theOperation];
        
        if ([self.delegate respondsToSelector:@selector(persistentOperationQueue:willHibernateOperation:)])
            {
            [self.delegate persistentOperationQueue:self willHibernateOperation:theOperation];
            }
        
        NSString *thePath = [self.hibernationPath stringByAppendingPathComponent:[NSString stringWithFormat:@"hibernation_%u.keyedarchive", arc4random()]];
        NSError *theError = NULL;
        if ([theData writeToFile:thePath options:NSDataWritingAtomic error:&theError] == NO)
            {
            NSLog(@"%@", theError);
            }
        }
    else
        {
        NSLog(@"Cannot hibernate operation: %@", theOperation);
        }
    }
//
[self setSuspended:theIsSuspendedFlag];
}

- (void)unhibernate
{
NSError *theError = NULL;
for (NSString *theFilename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.hibernationPath error:&theError])
    {
    NSString *thePath = [self.hibernationPath stringByAppendingPathComponent:theFilename];
    NSData *theData = [NSData dataWithContentsOfFile:thePath options:0 error:&theError];
    NSOperation *theOperation = [NSKeyedUnarchiver unarchiveObjectWithData:theData];

    if ([self.delegate respondsToSelector:@selector(persistentOperationQueue:didUnhibernateOperation:)])
        {
        [self.delegate persistentOperationQueue:self didUnhibernateOperation:theOperation];
        }
//    theOperation.completionBlock = ^(void) { NSLog(@"HIBERNATED DONE"); };

    [self addOperation:theOperation];
    
    if ([[NSFileManager defaultManager] removeItemAtPath:thePath error:&theError] == NO)
        {
        NSLog(@"%@", theError);
        }
    }
}

@end
