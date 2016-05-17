//
//  JTCalendarPageView.m
//  JTCalendar
//
//  Created by Jonathan Tribouharet
//

#import "JTCalendarPageView.h"

#import "JTCalendarManager.h"

#define MAX_WEEKS_BY_MONTH 6

@interface JTCalendarPageView () {
	UIView<JTCalendarWeekDay> *_weekDayView;
	NSMutableArray *_weeksViews;
	NSUInteger _numberOfWeeksDisplayed;
//	UIView *_dayContentView;
	BOOL _isAnimating;
	NSUInteger _activeWeekIndex;
}

@end

@implementation JTCalendarPageView
@synthesize dayContentView = _dayContentView;

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (!self) {
		return nil;
	}

	[self commonInit];

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (!self) {
		return nil;
	}

	[self commonInit];

	return self;
}

- (void)commonInit {
	// Maybe used in future
}

- (void)setDate:(NSDate *)date {
	NSAssert(_manager != nil, @"manager cannot be nil");
	NSAssert(date != nil, @"date cannot be nil");

	self->_date = date;

	[self reload];
}

- (void)reload {
	if (_manager.settings.pageViewHaveWeekDaysView && !_weekDayView) {
		_weekDayView = [_manager.delegateManager buildWeekDayView];
		[self addSubview:_weekDayView];

		_weekDayView.manager = _manager;
		[_weekDayView reload];
	}

	if (!_weeksViews) {
		_weeksViews = [NSMutableArray new];

		for (int i = 0; i < MAX_WEEKS_BY_MONTH; ++i) {
			UIView<JTCalendarWeek> *weekView = [_manager.delegateManager buildWeekView];
			[_weeksViews addObject:weekView];
//            weekView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1.0];
			[self addSubview:weekView];

			weekView.manager = _manager;
		}
	}

	NSDate *weekDate = nil;

	if (_manager.settings.weekModeEnabled) {
		_numberOfWeeksDisplayed = MIN(MAX(_manager.settings.pageViewWeekModeNumberOfWeeks, 1), MAX_WEEKS_BY_MONTH);
		weekDate                = [_manager.dateHelper firstWeekDayOfWeek:_date];
	}
	else{
		_numberOfWeeksDisplayed = MIN(_manager.settings.pageViewNumberOfWeeks, MAX_WEEKS_BY_MONTH);
		if (_numberOfWeeksDisplayed == 0) {
			_numberOfWeeksDisplayed = [_manager.dateHelper numberOfWeeks:_date];
		}

		weekDate = [_manager.dateHelper firstWeekDayOfMonth:_date];
	}

	for (NSUInteger i = 0; i < _numberOfWeeksDisplayed; i++) {
		UIView<JTCalendarWeek> *weekView = _weeksViews[i];

		weekView.hidden = NO;

		// Process the check on another month for the 1st, 4th and 5th weeks
		if (i == 0 || i >= 4) {
			[weekView setStartDate:weekDate updateAnotherMonth:YES monthDate:_date];
		}
		else{
			[weekView setStartDate:weekDate updateAnotherMonth:NO monthDate:_date];
		}

		weekDate = [_manager.dateHelper addToDate:weekDate weeks:1];
	}

	for (NSUInteger i = _numberOfWeeksDisplayed; i < MAX_WEEKS_BY_MONTH; i++) {
		UIView<JTCalendarWeek> *weekView = _weeksViews[i];

		weekView.hidden = YES;
	}
}

- (void)updateContentViewWithDate:(NSDate *)contentDate {
    if (!_manager.settings.weekModeEnabled) {
        [_dayContentView removeFromSuperview];
        _dayContentView = [_manager.delegateManager buildDayContentView];
        if (_dayContentView)
            [self addSubview:_dayContentView];
        [self layoutSubviews];
        
        _activeWeekIndex = 0;
        _isAnimating     = YES;
        
        for (UIView<JTCalendarWeek> *view in _weeksViews) {
            _activeWeekIndex++;
            if ([_manager.dateHelper date:view.startDate isTheSameWeekThan:contentDate]) {
                _activeWeekIndex--;
                [view removeFromSuperview];
                [self addSubview:view];
                break;
            }
        }
        
        [UIView transitionWithView:self duration:.5 options:0 animations:^{
            NSUInteger counter = 0;
            CGFloat dayContentTop = .0;
            for (UIView<JTCalendarWeek> *view in _weeksViews) {
                BOOL isActiveWeek = [_manager.dateHelper date:view.startDate isTheSameWeekThan:contentDate];
                BOOL isNeedShift = [_manager.dateHelper date:view.startDate isEqualOrBefore:contentDate];
                if (isActiveWeek) {
                    counter = 0;
                    dayContentTop = _weekDayView.frame.size.height + view.frame.size.height;
                }
                if (isNeedShift) {
                    CGRect frameRect = CGRectMake(isActiveWeek ? .0 : -view.frame.size.width - (_activeWeekIndex - counter) * view.frame.size.width * .5,
                                                  isActiveWeek ? _weekDayView.frame.size.height : view.frame.origin.y * .5,
                                                  view.frame.size.width,
                                                  view.frame.size.height
                                                  );
                    view.frame = frameRect;
                }
                else {
                    view.frame = CGRectMake(view.frame.size.width + counter * view.frame.size.width * .5,
                                            view.frame.size.height * 1.5,
                                            view.frame.size.width,
                                            view.frame.size.height
                                            );
                    [view layoutIfNeeded];
                }
                counter++;
            }
            if (_dayContentView)
                _dayContentView.frame = CGRectMake(.0, dayContentTop, self.frame.size.width, self.frame.size.height - dayContentTop);
        } completion:^(BOOL finished) {
            [_weeksViews exchangeObjectAtIndex:0 withObjectAtIndex:_activeWeekIndex];
            _isAnimating = NO;
            _manager.settings.weekModeEnabled = YES;
//            [_manager reload];
            [_manager setDate:contentDate];
        }];
    }
    else {
        [_weeksViews exchangeObjectAtIndex:0 withObjectAtIndex:_activeWeekIndex];
        _manager.settings.weekModeEnabled = NO;
        UIView *contentView = _dayContentView;
        _dayContentView = nil;
        [_manager reload];
        [UIView transitionWithView:self duration:.5 options:0 animations:^{
            [self layoutSubviews];
            CGFloat dayContentTop = .0;
            for (UIView<JTCalendarWeek> *view in _weeksViews) {
                CGFloat viewBottom = CGRectGetMaxY(view.frame);
                if (dayContentTop < viewBottom) {
                    dayContentTop = viewBottom;
                }
                view.alpha = 1.0;
                [view layoutIfNeeded];
            }
            if (contentView)
                contentView.frame = CGRectMake(.0, dayContentTop, self.frame.size.width, self.frame.size.height - dayContentTop);
        }
         
                        completion:nil];
    }
}

- (void)layoutSubviews {
	if (!_weeksViews || _isAnimating) {
		return;
	}

	CGFloat y         = 0;
	CGFloat weekWidth = self.frame.size.width;

	if (_manager.settings.pageViewHaveWeekDaysView) {
		CGFloat weekDayHeight = _weekDayView.frame.size.height; // Force use default height

		if (weekDayHeight == 0) { // Or use the same height than weeksViews
			weekDayHeight = self.frame.size.height / (_numberOfWeeksDisplayed + 1);
		}

		_weekDayView.frame = CGRectMake(0, 0, weekWidth, weekDayHeight);
		y                  = weekDayHeight;
	}

	CGFloat weekHeight = (self.frame.size.height - y) / _numberOfWeeksDisplayed;

	for (UIView *weekView in _weeksViews) {
		weekView.frame = CGRectMake(0, y, weekWidth, weekHeight);
		y             += weekHeight;
	}
	if (_dayContentView)
		_dayContentView.frame = CGRectMake(.0, y, weekWidth, self.frame.size.height - y);
}

@end
