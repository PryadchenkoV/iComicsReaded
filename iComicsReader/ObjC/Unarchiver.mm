//
//  Unarchiver.m
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 05/11/2018.
//  Copyright © 2018 MIEM. All rights reserved.
//

#import "Unarchiver.h"

#include <stdio.h>
#include <archive_entry.h>
#include <archive.h>

@interface Unarchiver()

@property NSMutableArray* arrayOfComics;

@end

@implementation Unarchiver
{
    BOOL* cancelledPtr;
    NSString* previousPath;
}

+ (Unarchiver*) sharedInstance
{
    static Unarchiver *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.arrayOfComics = [NSMutableArray new];
    }
    return self;
}

-(void) cancelTask
{
    *cancelledPtr = YES;
}

- (void) readArchiveForPath:(NSString*)path
{
    if ([previousPath isEqualToString: path])
    {
        [self willChangeValueForKey:@"arrayOfComics"];
        [self didChangeValueForKey:@"arrayOfComics"];
        return;
    }
    _arrayOfComics = [NSMutableArray new];
    __block BOOL cancelled = NO;
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        const char *pathString = [path cStringUsingEncoding:NSASCIIStringEncoding];
        struct archive* archive;
        struct archive_entry *entry;
        int readData;
        archive = archive_read_new();
        archive_read_support_filter_all(archive);
        archive_read_support_format_all(archive);
        readData = archive_read_open_filename(archive, pathString, 20480);
        if (readData != ARCHIVE_OK)
        {
            NSLog(@"Archive Is Not OK");
            return;
        }
        int page_number = 0;
        while (archive_read_next_header(archive, &entry) == ARCHIVE_OK && !cancelled) {
            size_t entry_size = archive_entry_size(entry);
            char * content;
            int readEntryData;
            content = (char*)malloc(entry_size);
            readEntryData = archive_read_data(archive, content, entry_size);
            if (readEntryData> 0) {
                NSLog(@"Read %d out of %zu", readEntryData, entry_size);
                NSData* pageData = [[NSData alloc] initWithBytes:content length: entry_size];
                NSString* pageName = [[NSString alloc] initWithCString: archive_entry_pathname(entry) encoding: NSUTF8StringEncoding];
                if (pageData)
                {
                    NSDictionary* dictionaryOfPage = @{
                                                       @"PageNumber" : [NSNumber numberWithInt:page_number],
                                                       @"PageTitle" : pageName,
                                                       @"PageData" : pageData
                                                       };
                    [self.arrayOfComics addObject:dictionaryOfPage];
                    
                }
            }
            else if (archive_errno(archive) != ARCHIVE_OK)
            {
                NSLog(@"Error: %s", archive_error_string(archive));
            }
            page_number++;
            free(content);
            archive_entry_clear(entry);
        }
        readData = archive_read_close(archive);
        if (readData != ARCHIVE_OK)
        {
            NSLog(@"Archive Is Not OK");
            return;
        }
        self->previousPath = path;
        [self willChangeValueForKey:@"arrayOfComics"];
        [self didChangeValueForKey:@"arrayOfComics"];
    });
    cancelledPtr = &cancelled;
}

@end
