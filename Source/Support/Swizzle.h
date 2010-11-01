//
//  Swizzle.h
//  BattleMat
//
//  Created by Jonathan Wight on 07/10/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#include <objc/runtime.h>

extern void Swizzle(Class inClass, SEL inOldSelector, SEL inNewSelector, IMP *outOldImplementation);
