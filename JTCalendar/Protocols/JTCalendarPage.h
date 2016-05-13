//
//  JTCalendarPage.h
//  JTCalendar
//
//  Created by Jonathan Tribouharet
//

#import <Foundation/Foundation.h>

@class JTCalendarManager;

@protocol JTCalendarPage <NSObject>

@property (nonatomic) UIView *dayContentView;

- (void)setManager:(JTCalendarManager *)manager;

- (NSDate *)date;
- (void)setDate:(NSDate *)date;

- (void)reload;
- (void)updateContentViewWithDate:(NSDate *)contentDate;

@end
