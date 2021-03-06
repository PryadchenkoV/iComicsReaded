//
//  Unarchiver.h
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 05/11/2018.
//  Copyright © 2018 MIEM. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Unarchiver : NSObject

+ (Unarchiver*) sharedInstance;

- (void) cancelTask;
- (void) readArchiveForPath:(NSURL*)url withUUID:(NSUUID*)uuid withComplitionBlock:(void (NSArray*, NSUUID*))complitionBlock;


@end

NS_ASSUME_NONNULL_END
