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

- (void) readArchiveForPath:(NSString*)path;

@property (readonly) NSMutableArray* arrayOfComics;

@end

NS_ASSUME_NONNULL_END
