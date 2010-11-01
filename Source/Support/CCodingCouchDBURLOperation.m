//
//  CCodingCouchDBURLOperation.m
//  TouchMetricsTest
//
//  Created by Jonathan Wight on 08/21/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CCodingCouchDBURLOperation.h"


@implementation CCodingCouchDBURLOperation

- (id)initWithCoder:(NSCoder *)aDecoder
    {
    NSURLRequest *theRequest = [aDecoder decodeObjectForKey:@"request"];
    id theJSON = [aDecoder decodeObjectForKey:@"JSON"];

    if ((self = [self initWithRequest:theRequest]) != NULL)
        {
        self.JSON = theJSON;
        }
    return(self);
    }

- (void)encodeWithCoder:(NSCoder *)aCoder
    {
    [aCoder encodeObject:self.request forKey:@"request"];
    [aCoder encodeObject:self.JSON forKey:@"JSON"];
    }

@end
