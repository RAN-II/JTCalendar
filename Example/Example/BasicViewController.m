//
//  BasicViewController.m
//  Example
//
//  Created by Jonathan Tribouharet.
//

#import "BasicViewController.h"


@interface BasicViewController (){
    NSMutableDictionary *_eventsByDate;
    
    NSDate *_todayDate;
    NSDate *_minDate;
    NSDate *_maxDate;
    
    NSDate *_dateSelected;
    
    __weak IBOutlet NSLayoutConstraint *calendarHeightConstraint;
    BOOL _isShortMode;
    
}

@end

@implementation BasicViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(!self){
        return nil;
    }
    
    self.title = @"Basic";
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _calendarManager = [JTCalendarManager new];
    _calendarManager.delegate = self;
    
    // Generate random events sort by date using a dateformatter for the demonstration
    [self createRandomEvents];
    
    // Create a min and max date for limit the calendar, optional
    [self createMinAndMaxDate];
    
    [_calendarManager setMenuView:_calendarMenuView];
    [_calendarManager setContentView:_calendarContentView];
    [_calendarManager setDate:_todayDate];
}

#pragma mark - Buttons callback

- (IBAction)didGoTodayTouch
{
    [_calendarManager setDate:_todayDate];
}

- (IBAction)didChangeModeTouch
{
    _calendarManager.settings.weekModeEnabled = !_calendarManager.settings.weekModeEnabled;
    [_calendarManager reload];
}

#pragma mark - CalendarManager delegate

// Exemple of implementation of prepareDayView method
// Used to customize the appearance of dayView
- (void)calendar:(JTCalendarManager *)calendar prepareDayView:(JTCalendarDayView *)dayView
{
    dayView.circleRatio = 2.;
    dayView.dotRatio = 0.175;
    dayView.isTextAlignToTop = YES;
    // Today
    if([_calendarManager.dateHelper date:[NSDate date] isTheSameDayThan:dayView.date]){
        dayView.circleView.hidden = NO;
        dayView.circleView.backgroundColor = [UIColor colorWithRed:.0 green:1.0 blue:.0 alpha:.075];
        dayView.textLabel.textColor = [UIColor darkGrayColor];
    }
    // Selected date
    else if(_dateSelected && [_calendarManager.dateHelper date:_dateSelected isTheSameDayThan:dayView.date]){
        dayView.circleView.hidden = NO;
        dayView.circleView.backgroundColor = [UIColor colorWithRed:.0 green:.0 blue:.0 alpha:.025];
        dayView.textLabel.textColor = [UIColor darkGrayColor];
    }
    // Other month
    else if(![_calendarManager.dateHelper date:_calendarContentView.date isTheSameMonthThan:dayView.date]){
        dayView.circleView.hidden = YES;
        dayView.textLabel.textColor = [UIColor lightGrayColor];
    }
    // Another day of the current month
    else{
        dayView.circleView.hidden = YES;
        dayView.textLabel.textColor = [UIColor blackColor];
    }
    
    if([self haveEventForDay:dayView.date]){
        dayView.dotLeftView.hidden = NO;
        dayView.dotMidView.hidden = NO;
        dayView.dotRightView.hidden = NO;
    }
    else{
        dayView.dotLeftView.hidden = YES;
        dayView.dotMidView.hidden = YES;
        dayView.dotRightView.hidden = YES;
    }
}

- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(JTCalendarDayView *)dayView
{
    if (_dateSelected) {
        _dateSelected = nil;
        [_calendarManager.delegateManager updateDayContentWithDate:dayView.date];
        return;
    } else {
        _dateSelected = dayView.date;
    }
    
    // Load the previous or next page if touch a day from another month
    
    if(![_calendarManager.dateHelper date:_calendarContentView.date isTheSameMonthThan:dayView.date]){
        if([_calendarContentView.date compare:dayView.date] == NSOrderedAscending){
            [_calendarContentView loadNextPageWithAnimation];
        }
        else{
            [_calendarContentView loadPreviousPageWithAnimation];
        }
        _dateSelected = nil;
        
    } else {
        dayView.circleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
        [UIView transitionWithView:dayView
                          duration:.3
                           options:0
                        animations:^{
                            dayView.circleView.transform = CGAffineTransformIdentity;
                            [_calendarManager reload];
                        } completion:nil];
        [_calendarManager.delegateManager updateDayContentWithDate:dayView.date];
    }
}

#pragma mark - CalendarManager delegate - Page mangement

// Used to limit the date for the calendar, optional
- (BOOL)calendar:(JTCalendarManager *)calendar canDisplayPageWithDate:(NSDate *)date
{
//    return !_calendarManager.settings.weekModeEnabled;
    return [_calendarManager.dateHelper date:date isEqualOrAfter:_minDate andEqualOrBefore:_maxDate];
}

- (void)calendarDidLoadNextPage:(JTCalendarManager *)calendar
{
    //    NSLog(@"Next page loaded");
}

- (void)calendarDidLoadPreviousPage:(JTCalendarManager *)calendar
{
    //    NSLog(@"Previous page loaded");
}

- (UIView *)calendarBuildDayContentView:(JTCalendarManager *)calendar {
    UIView *contentView = [UIView new];
    contentView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:.5];
    return contentView;
}


#pragma mark - Fake data

- (void)createMinAndMaxDate
{
    _todayDate = [NSDate date];
    
    // Min date will be 2 month before today
    _minDate = [_calendarManager.dateHelper addToDate:_todayDate months:-2];
    
    // Max date will be 2 month after today
    _maxDate = [_calendarManager.dateHelper addToDate:_todayDate months:2];
}

// Used only to have a key for _eventsByDate
- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"dd-MM-yyyy";
    }
    
    return dateFormatter;
}

- (BOOL)haveEventForDay:(NSDate *)date
{
    NSString *key = [[self dateFormatter] stringFromDate:date];
    
    if(_eventsByDate[key] && [_eventsByDate[key] count] > 0){
        return YES;
    }
    
    return NO;
    
}

- (void)createRandomEvents
{
    _eventsByDate = [NSMutableDictionary new];
    
    for(int i = 0; i < 30; ++i){
        // Generate 30 random dates between now and 60 days later
        NSDate *randomDate = [NSDate dateWithTimeInterval:(rand() % (3600 * 24 * 60)) sinceDate:[NSDate date]];
        
        // Use the date as key for eventsByDate
        NSString *key = [[self dateFormatter] stringFromDate:randomDate];
        
        if(!_eventsByDate[key]){
            _eventsByDate[key] = [NSMutableArray new];
        }
        
        [_eventsByDate[key] addObject:randomDate];
    }
}

- (IBAction)testAction:(id)sender {
    CGFloat height = 85.0 + 215.0 * _isShortMode;
    if (_isShortMode) {
        _calendarManager.settings.weekModeEnabled = NO;
    }
    [_calendarManager reload];
    [UIView animateWithDuration:.25 animations:^{
        _calendarContentViewHeight.constant = height;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (!_isShortMode) {
            _calendarManager.settings.weekModeEnabled = YES;
            [_calendarManager reload];
            _calendarContentViewHeight.constant = height;
            [self.view layoutIfNeeded];
        }
        _isShortMode = !_isShortMode;
    }];
}

//- (void)changeModeTouch
//{
//    _calendarManager.settings.weekModeEnabled = !_calendarManager.settings.weekModeEnabled;
////    [_calendarManager reload];
//    
////    CGFloat newHeight = 400;
////    if(_calendarManager.settings.weekModeEnabled){
////        newHeight = 85.;
////    }
////    
////    self.calendarContentViewHeight.constant = newHeight;
////    [self.view layoutIfNeeded];
//}

@end
