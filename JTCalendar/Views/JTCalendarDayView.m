//
//  JTCalendarDayView.m
//  JTCalendar
//
//  Created by Jonathan Tribouharet
//

#import "JTCalendarDayView.h"

#import "JTCalendarManager.h"

@implementation JTCalendarDayView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (void)commonInit
{
    self.clipsToBounds = YES;
    
    _circleRatio = .9;
    _dotRatio = 1. / 9.;
    
    {
        _circleView = [UIView new];
        [self addSubview:_circleView];
        
        _circleView.backgroundColor = [UIColor colorWithRed:0x33/256. green:0xB3/256. blue:0xEC/256. alpha:.5];
        _circleView.hidden = YES;

        _circleView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        _circleView.layer.shouldRasterize = YES;
    }
    
    {
        _dotLeftView = [UIView new];
        [self addSubview:_dotLeftView];
        
        _dotLeftView.backgroundColor = [UIColor redColor];
        _dotLeftView.hidden = YES;

        _dotLeftView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        _dotLeftView.layer.shouldRasterize = YES;

        _dotMidView = [UIView new];
        [self addSubview:_dotMidView];
        
        _dotMidView.backgroundColor = [UIColor greenColor];
        _dotMidView.hidden = YES;
        
        _dotMidView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        _dotMidView.layer.shouldRasterize = YES;

        _dotRightView = [UIView new];
        [self addSubview:_dotRightView];

        _dotRightView.backgroundColor = [UIColor blueColor];
        _dotRightView.hidden = YES;

        _dotRightView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        _dotRightView.layer.shouldRasterize = YES;
    }

    {
        _textLabel = [UILabel new];
        [self addSubview:_textLabel];
        
        _textLabel.textColor = [UIColor blackColor];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    
    {
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTouch)];
        
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:gesture];
    }
}

- (void)layoutSubviews
{
    if (_isTextAlignToTop) {
        CGSize textSize = [_textLabel sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
        _textLabel.frame = CGRectMake(.0, 2., self.frame.size.width, textSize.height);
    } else {
        _textLabel.frame = self.bounds;
    }
    
    CGFloat sizeCircle = MIN(self.frame.size.width, self.frame.size.height);
    CGFloat sizeDot = sizeCircle;
    
    sizeCircle = sizeCircle * _circleRatio;
    sizeDot = sizeDot * _dotRatio;
    
    sizeCircle = roundf(sizeCircle);
    sizeDot = roundf(sizeDot);
    
    _circleView.frame = CGRectMake(0, 0, sizeCircle, sizeCircle);
    _circleView.center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
    _circleView.layer.cornerRadius = sizeCircle / 2.;
    
    CGFloat dotShift = self.frame.size.width / 4.;
    CGFloat dotYCenter = _isTextAlignToTop ? CGRectGetMaxY(_textLabel.frame) +sizeDot : (self.frame.size.height / 2.) +sizeDot * 2.5;
    
    _dotLeftView.frame = CGRectMake(0, 0, sizeDot, sizeDot);
    _dotLeftView.center = CGPointMake(dotShift, dotYCenter);
    _dotLeftView.layer.cornerRadius = sizeDot / 2.;
    
    _dotMidView.frame = CGRectMake(0, 0, sizeDot, sizeDot);
    _dotMidView.center = CGPointMake(self.frame.size.width / 2., dotYCenter);
    _dotMidView.layer.cornerRadius = sizeDot / 2.;

    _dotRightView.frame = CGRectMake(0, 0, sizeDot, sizeDot);
    _dotRightView.center = CGPointMake(self.frame.size.width - dotShift, dotYCenter);
    _dotRightView.layer.cornerRadius = sizeDot / 2.;

}

- (void)setDate:(NSDate *)date
{
    NSAssert(date != nil, @"date cannot be nil");
    NSAssert(_manager != nil, @"manager cannot be nil");
    
    self->_date = date;
    [self reload];
}

- (void)setIsTextAlignToTop:(BOOL)isTextAlignToTop {
    self->_isTextAlignToTop = isTextAlignToTop;
//    [self reload];
}

- (void)reload
{
    static NSDateFormatter *dateFormatter = nil;
    if(!dateFormatter){
        dateFormatter = [_manager.dateHelper createDateFormatter];
        [dateFormatter setDateFormat:@"dd"];
    }
    
    _textLabel.text = [dateFormatter stringFromDate:_date];
        
    [_manager.delegateManager prepareDayView:self];
}

- (void)didTouch
{
    [_manager.delegateManager didTouchDayView:self];
}

@end
