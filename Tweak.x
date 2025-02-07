#import <YouTubeHeader/YTColor.h>
#import <YouTubeHeader/YTIPlayerBarDecorationModel.h>
#import <YouTubeHeader/YTMainAppVideoPlayerOverlayViewController.h>
#import <YouTubeHeader/YTPlayerBarController.h>
#import <YouTubeHeader/YTPlayerBarRectangleDecorationView.h>
#import <YouTubeHeader/YTPlayerBarSegmentView.h>
#import <YouTubeHeader/YTSegmentableInlinePlayerBarView.h>
#import <YouTubeHeader/UIColor+YouTube.h>
#import <UIKit/UIImage+Private.h>
#import "Settings.h"

@interface YTModularPlayerBarView (Addition)
@property (retain, nonatomic) UIImageView *tweakCustomScrubberImageView;
@end

@interface YTInlinePlayerBarView (Addition)
@property (retain, nonatomic) UIImageView *tweakCustomScrubberImageView;
@end

@interface YTSegmentableInlinePlayerBarView (Addition)
@property (retain, nonatomic) UIImageView *tweakCustomScrubberImageView;
@end

#define DEFAULT_SCRUBBER_SIZE 12
#define YOUTUBE_SCRUBBER_SCALE 6

extern BOOL IsEnabled(NSString *key);
extern NSString *GetScrubberColor();
extern UIImage *GetScrubberImage();
extern NSString *GetSliderColor();
extern int GetSelection(NSString *key);

static UIColor *sliderUIColor() {
    NSString *color = GetSliderColor();
    return color ? [UIColor LOT_colorWithHexString:color] : nil;
}

UIColor *scrubberUIColor() {
    NSString *color = GetScrubberColor();
    return color ? [UIColor LOT_colorWithHexString:color] : nil;
}

static CGFloat getBaseScrubberScale() {
    int scrubberSize = GetSelection(ScrubberSizeKey);
    if (scrubberSize == 0 && !IsEnabled(ScrubberImageKey)) return -1;
    return 1 + (scrubberSize / 100.0);;
}

static void initScrubberCircle(UIView *self) {
    CGFloat scrubberScale = getBaseScrubberScale();
    if (scrubberScale == -1) return;
    UIView *scrubberCircle = [self valueForKey:@"_scrubberCircle"];
    CGFloat size = DEFAULT_SCRUBBER_SIZE * scrubberScale;
    scrubberCircle.frame = CGRectMake(0, 0, size, size);
}

static void updateScrubberColor(UIView *self) {
    UIView *scrubberCircle = [self valueForKey:@"_scrubberCircle"];
    if (IsEnabled(ScrubberImageKey))
        scrubberCircle.backgroundColor = nil;
    else if (IsEnabled(ScrubberImageColorKey)) {
        UIColor *scrubberColor = scrubberUIColor();
        if (!scrubberColor) return;
        scrubberCircle.backgroundColor = scrubberColor;
    }
}

static CGFloat getScrubberScale(CGFloat scale) {
    CGFloat scrubberScale = getBaseScrubberScale();
    if (scrubberScale == -1) return scale;
    return scrubberScale * scale / YOUTUBE_SCRUBBER_SCALE + 0.001;
}

static void setTweakCustomScrubberIcon(id self_) {
    YTModularPlayerBarView *self = self_;
    UIImageView *imageView = self.tweakCustomScrubberImageView;
    UIView *scrubberCircle = [self valueForKey:@"_scrubberCircle"];
    if (IsEnabled(ScrubberImageKey)) {
        UIImage *image = GetScrubberImage();
        if (!image) return;
        [imageView removeFromSuperview];
        self.tweakCustomScrubberImageView = [[UIImageView alloc] initWithImage:image];
        self.tweakCustomScrubberImageView.contentMode = UIViewContentModeScaleAspectFit;
        CGFloat scrubberScale = getBaseScrubberScale();
        CGFloat size = DEFAULT_SCRUBBER_SIZE * scrubberScale;
        self.tweakCustomScrubberImageView.frame = CGRectMake(0, 0, size, size);
        scrubberCircle.backgroundColor = [UIColor clearColor];
        [scrubberCircle addSubview:self.tweakCustomScrubberImageView];
    } else {
        [imageView removeFromSuperview];
        self.tweakCustomScrubberImageView = nil;
        updateScrubberColor(self);
    }
}

static void findViewAndSetScrubberIcon(YTMainAppVideoPlayerOverlayViewController *self) {
    YTInlinePlayerBarContainerView *playerBar = self.playerBarController.playerBar;
    id view;
    if ([playerBar respondsToSelector:@selector(modularPlayerBar)])
        view = playerBar.modularPlayerBar.view;
    else if ([playerBar respondsToSelector:@selector(segmentablePlayerBar)]) {
        id segmentablePlayerBar = playerBar.segmentablePlayerBar;
        if ([segmentablePlayerBar isKindOfClass:%c(YTModularPlayerBarController)])
            view = ((YTModularPlayerBarController *)segmentablePlayerBar).view;
        else
            view = segmentablePlayerBar; // YTSegmentableInlinePlayerBarView
    } else
        view = playerBar.playerBar;
    setTweakCustomScrubberIcon(view);
}

%hook YTModularPlayerBarView

%property (retain, nonatomic) UIImageView *tweakCustomScrubberImageView;

- (id)initWithModel:(id)model delegate:(id)delegate {
    self = %orig;
    if (self)
        initScrubberCircle(self);
    return self;
}

- (void)transformScrubberScale:(CGFloat)scale {
    %orig(getScrubberScale(scale));
}

- (void)setCustomScrubberIcon:(UIImage *)image {
    if (IsEnabled(ScrubberImageKey)) return;
    %orig;
}

- (void)layoutSubviews {
    %orig;
    updateScrubberColor(self);
}

%end

%hook YTSegmentableInlinePlayerBarView

%property (retain, nonatomic) UIImageView *tweakCustomScrubberImageView;

- (id)init {
    self = %orig;
    if (self)
        initScrubberCircle(self);
    return self;
}

- (void)transformScrubberScale:(CGFloat)scale {
    %orig(getScrubberScale(scale));
}

- (void)setMode:(int)mode {
    %orig;
    updateScrubberColor(self);
}

- (void)resetPlayerBarModeColors {
    %orig;
    if (IsEnabled(SliderColorKey)) {
        UIColor *color = sliderUIColor();
        if (!color) return;
        [self setValue:color forKey:@"_progressBarColor"];
        [self setValue:color forKey:@"_userIsScrubbingProgressBarColor"];
    }
    updateScrubberColor(self);
}

%end

%hook YTPlayerBarSegmentView

- (void)drawHighlightedChapter:(CGRect)rect {
    %orig;
    if (!IsEnabled(SliderColorKey)) return;
    UIColor *color = sliderUIColor();
    if (!color) return;
    CGFloat playingProgress = [[self valueForKey:@"_playingProgress"] doubleValue];
    CGRect fillRect = CGRectMake(0, 0, rect.size.width * playingProgress, rect.size.height);
    [color setFill];
    UIRectFill(fillRect);
}

- (void)drawUnhighlightedChapter:(CGRect)rect {
    %orig;
    if (!IsEnabled(SliderColorKey)) return;
    UIColor *color = sliderUIColor();
    if (!color) return;
    CGFloat playingProgress = [[self valueForKey:@"_playingProgress"] doubleValue];
    CGRect fillRect = CGRectMake(0, 0, rect.size.width * playingProgress, rect.size.height);
    [color setFill];
    UIRectFill(fillRect);
}

%end

%hook YTPlayerBarRectangleDecorationView

- (void)drawRectangleDecorationWithSideMasks:(CGRect)rect {
    if (IsEnabled(SliderColorKey)) {
        YTIPlayerBarDecorationModel *model = [self valueForKey:@"_model"];
        YTIPlayerBarPlayingStateOverlayMode overlayMode = model.playingState.overlayMode;
        model.playingState.overlayMode = PLAYER_BAR_OVERLAY_MODE_DEFAULT;
        if ([model respondsToSelector:@selector(style)])
            model.style.gradientColor = nil;
        %orig;
        model.playingState.overlayMode = overlayMode;
    } else
        %orig;
}

- (void)drawProgressRect:(CGRect)rect withColor:(UIColor *)color {
    %orig(rect, IsEnabled(SliderColorKey) ? sliderUIColor() : color);
}

%end

%hook YTProgressView

- (void)setProgressBarColor:(UIColor *)color {
    %orig(IsEnabled(SliderColorKey) ? sliderUIColor() : color);
}

- (void)setBrandGradientEnabled:(BOOL)enabled {
    %orig(IsEnabled(SliderColorKey) ? NO : enabled);
}

%end

%hook YTMainAppVideoPlayerOverlayViewController

- (void)setWatchNextResponse:(id)response loading:(bool)loading {
    findViewAndSetScrubberIcon(self);
    %orig;
}

- (void)setWatchNextResponse:(id)response {
    findViewAndSetScrubberIcon(self);
    %orig;
}

%end

%ctor {
    if (!IsEnabled(EnabledKey)) return;
    %init;
}
