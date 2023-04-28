//
//  KKStatement.m
//  SQLiteDemo
//
//  Created by Sands on 2023/4/19.
//

#import "KKStatement.h"
#import <sqlite3.h>

@implementation KKStatement

- (void)reset {
    if (_statement) {
        sqlite3_reset((sqlite3_stmt *)_statement);
    }
    _inUse = NO;
}

- (void)close {
    if (_statement) {
        sqlite3_finalize((sqlite3_stmt *)_statement);
        _statement = NULL;
    }
    _inUse = NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %ld hit(s) for query %@", [super description], _useCount, _query];
}

- (void)dealloc {
    [self close];
}

@end
