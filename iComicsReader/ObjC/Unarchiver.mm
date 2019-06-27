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

@implementation Unarchiver
{
    BOOL* cancelledPtr;
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
    }
    return self;
}

-(void) cancelTask
{
    *cancelledPtr = YES;
}

- (void) readArchiveForPath:(NSURL*)url withUUID:(NSUUID*)uuid withComplitionBlock:(void (NSArray*, NSUUID*))complitionBlock
{
    __block BOOL cancelled = NO;
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSMutableArray* arrayOfComics = [NSMutableArray new];
        const char *pathString = [url.path cStringUsingEncoding:NSASCIIStringEncoding];
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
                if (pageData)
                {
                    [arrayOfComics addObject: pageData];
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
        complitionBlock(arrayOfComics, uuid);
        
    });
    cancelledPtr = &cancelled;
}

@end
