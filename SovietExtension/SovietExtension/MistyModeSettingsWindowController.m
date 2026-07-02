//
//  MistyModeSettingsWindowController.m
//  SovietExtension
//
//  Created by MustangYM on 2026/7/2.
//

#import "MistyModeSettingsWindowController.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import "MenuManager.h"

static const CGFloat kYMColorfulBlurRadiusMinValue = 40.0f;
static const CGFloat kYMColorfulBlurRadiusMaxValue = 160.0f;

@interface MistyModeSettingsWindowController ()
@property (nonatomic, strong) NSSlider *alphaSlider;
@property (nonatomic, strong) NSTextField *alphaValueLabel;
@property (nonatomic, strong) NSSlider *blurRadiusSlider;
@property (nonatomic, strong) NSTextField *blurRadiusValueLabel;
@property (nonatomic, strong) NSButton *enableBlurCheckbox;
@property (nonatomic, strong) NSButton *colorfulCheckbox;
@property (nonatomic, strong) NSSlider *colorfulOpacitySlider;
@property (nonatomic, strong) NSTextField *colorfulOpacityValueLabel;
@property (nonatomic, strong) NSSlider *colorfulBlurRadiusSlider;
@property (nonatomic, strong) NSTextField *colorfulBlurRadiusValueLabel;
@property (nonatomic, strong) NSSlider *colorfulAnimationDurationSlider;
@property (nonatomic, strong) NSTextField *colorfulAnimationDurationValueLabel;
@property (nonatomic, strong) NSPopUpButton *carrierStylePopup;
@property (nonatomic, strong) NSButton *keepAliveCheckbox;
@end

@implementation MistyModeSettingsWindowController

#pragma mark - Defaults

+ (void)registerDefaults
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        kThemeMistyMode: @(NO),
        kThemeMistyQNSAlpha: @(0.90),
        kThemeMistyWindowBlurEnabled: @(YES),
        kThemeMistyWindowBlurRadius: @(10),
        kThemeMistyColorful: @(NO),
        kThemeMistyColorfulOpacity: @(0.42),
        kThemeMistyColorfulBlurRadius: @(70.0),
        kThemeMistyColorfulAnimationDuration: @(10.0),
        kThemeMistyCarrierStyle: kThemeMistyCarrierStyleDark,
        kThemeMistyKeepAlive: @(YES),
    }];
}

#pragma mark - Init

- (instancetype)init
{
    NSPanel *panel = [MistyModeSettingsWindowController ym_createPanel];
    self = [super initWithWindow:panel];
    if (self) {
        [self ym_buildInterfaceInView:panel.contentView];
        [self loadSettingsToControls];
    }
    return self;
}

+ (NSPanel *)ym_createPanel
{
    NSRect frame = NSMakeRect(0, 0, 560, 760);
    NSWindowStyleMask styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;

    NSPanel *panel = [[NSPanel alloc] initWithContentRect:frame
                                                 styleMask:styleMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
    panel.title = @"迷离模式";
    panel.releasedWhenClosed = NO;
    panel.movableByWindowBackground = YES;
    panel.level = NSFloatingWindowLevel;
    panel.backgroundColor = [NSColor colorWithCalibratedWhite:0.08 alpha:0.96];
    panel.opaque = NO;

    NSView *contentView = [[NSView alloc] initWithFrame:frame];
    contentView.wantsLayer = YES;
    contentView.layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.06 alpha:0.96].CGColor;
    panel.contentView = contentView;

    return panel;
}

#pragma mark - Public

- (void)showWindowCentered
{
    [MistyModeSettingsWindowController registerDefaults];
    [self loadSettingsToControls];

    if (!self.window.isVisible) {
        [self.window center];
    }

    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:nil];
}

#pragma mark - UI

- (void)ym_buildInterfaceInView:(NSView *)contentView
{
    NSVisualEffectView *effect = [[NSVisualEffectView alloc] initWithFrame:contentView.bounds];
    effect.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    effect.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    effect.material = NSVisualEffectMaterialUnderWindowBackground;
    effect.state = NSVisualEffectStateActive;
    [contentView addSubview:effect];

    NSTextField *titleLabel = [self ym_labelWithFrame:NSMakeRect(32, 704, 300, 28)
                                                text:@"迷离模式"
                                                font:[NSFont systemFontOfSize:22 weight:NSFontWeightSemibold]
                                               color:[NSColor colorWithCalibratedWhite:0.98 alpha:1.0]];
    [contentView addSubview:titleLabel];

    NSTextField *subtitleLabel = [self ym_labelWithFrame:NSMakeRect(32, 676, 460, 20)
                                                   text:@"调节透明、模糊与流光氛围，保存后即时生效"
                                                   font:[NSFont systemFontOfSize:12 weight:NSFontWeightRegular]
                                                  color:[NSColor colorWithCalibratedWhite:0.72 alpha:1.0]];
    [contentView addSubview:subtitleLabel];

    NSView *colorfulCard = [self ym_cardViewWithFrame:NSMakeRect(24, 394, 512, 252)];
    [contentView addSubview:colorfulCard];

    self.colorfulCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(26, 208, 220, 24)];
    self.colorfulCheckbox.buttonType = NSSwitchButton;
    self.colorfulCheckbox.title = @"启用流光氛围";
    self.colorfulCheckbox.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
    self.colorfulCheckbox.target = self;
    self.colorfulCheckbox.action = @selector(liveThemeControlChanged:);
    [colorfulCard addSubview:self.colorfulCheckbox];
    [colorfulCard addSubview:[self ym_labelWithFrame:NSMakeRect(48, 186, 420, 18)
                                                text:@"在玻璃模糊层中加入缓慢流动的柔和彩色光晕，增强空间层次。"
                                                font:[NSFont systemFontOfSize:11 weight:NSFontWeightRegular]
                                               color:[NSColor colorWithCalibratedWhite:0.62 alpha:1.0]]];

    [colorfulCard addSubview:[self ym_labelWithFrame:NSMakeRect(26, 150, 160, 20)
                                                text:@"流光强度"
                                                font:[NSFont systemFontOfSize:13 weight:NSFontWeightMedium]
                                               color:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]]];
    self.colorfulOpacityValueLabel = [self ym_labelWithFrame:NSMakeRect(430, 150, 52, 20)
                                                       text:@"42%"
                                                       font:[NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightMedium]
                                                      color:[NSColor colorWithCalibratedWhite:0.86 alpha:1.0]];
    self.colorfulOpacityValueLabel.alignment = NSTextAlignmentRight;
    [colorfulCard addSubview:self.colorfulOpacityValueLabel];

    self.colorfulOpacitySlider = [[NSSlider alloc] initWithFrame:NSMakeRect(26, 124, 456, 24)];
    self.colorfulOpacitySlider.minValue = 0.0;
    self.colorfulOpacitySlider.maxValue = 1.0;
    self.colorfulOpacitySlider.target = self;
    self.colorfulOpacitySlider.action = @selector(colorfulSliderChanged:);
    [colorfulCard addSubview:self.colorfulOpacitySlider];
    [colorfulCard addSubview:[self ym_labelWithFrame:NSMakeRect(26, 104, 456, 18)
                                                text:@"控制流光背景的整体存在感；数值越高，彩色光晕越明显。"
                                                font:[NSFont systemFontOfSize:11 weight:NSFontWeightRegular]
                                               color:[NSColor colorWithCalibratedWhite:0.62 alpha:1.0]]];

    [colorfulCard addSubview:[self ym_labelWithFrame:NSMakeRect(26, 72, 160, 20)
                                                text:@"流光大小"
                                                font:[NSFont systemFontOfSize:13 weight:NSFontWeightMedium]
                                               color:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]]];
    self.colorfulBlurRadiusValueLabel = [self ym_labelWithFrame:NSMakeRect(430, 72, 52, 20)
                                                          text:@"70"
                                                          font:[NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightMedium]
                                                         color:[NSColor colorWithCalibratedWhite:0.86 alpha:1.0]];
    self.colorfulBlurRadiusValueLabel.alignment = NSTextAlignmentRight;
    [colorfulCard addSubview:self.colorfulBlurRadiusValueLabel];

    self.colorfulBlurRadiusSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(26, 46, 456, 24)];
    self.colorfulBlurRadiusSlider.minValue = kYMColorfulBlurRadiusMinValue;
    self.colorfulBlurRadiusSlider.maxValue = kYMColorfulBlurRadiusMaxValue;
    self.colorfulBlurRadiusSlider.target = self;
    self.colorfulBlurRadiusSlider.action = @selector(colorfulSliderChanged:);
    [colorfulCard addSubview:self.colorfulBlurRadiusSlider];

    [colorfulCard addSubview:[self ym_labelWithFrame:NSMakeRect(26, 16, 160, 20)
                                                text:@"流动速度"
                                                font:[NSFont systemFontOfSize:13 weight:NSFontWeightMedium]
                                               color:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]]];
    self.colorfulAnimationDurationValueLabel = [self ym_labelWithFrame:NSMakeRect(430, 16, 52, 20)
                                                                 text:@"10s"
                                                                 font:[NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightMedium]
                                                                color:[NSColor colorWithCalibratedWhite:0.86 alpha:1.0]];
    self.colorfulAnimationDurationValueLabel.alignment = NSTextAlignmentRight;
    [colorfulCard addSubview:self.colorfulAnimationDurationValueLabel];

    self.colorfulAnimationDurationSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(150, 12, 270, 24)];
    self.colorfulAnimationDurationSlider.minValue = 2.0;
    self.colorfulAnimationDurationSlider.maxValue = 60.0;
    self.colorfulAnimationDurationSlider.target = self;
    self.colorfulAnimationDurationSlider.action = @selector(colorfulSliderChanged:);
    [colorfulCard addSubview:self.colorfulAnimationDurationSlider];

    NSView *basicCard = [self ym_cardViewWithFrame:NSMakeRect(24, 86, 512, 288)];
    [contentView addSubview:basicCard];

    self.enableBlurCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(26, 244, 220, 24)];
    self.enableBlurCheckbox.buttonType = NSSwitchButton;
    self.enableBlurCheckbox.title = @"启用背景模糊";
    self.enableBlurCheckbox.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
    self.enableBlurCheckbox.target = self;
    self.enableBlurCheckbox.action = @selector(liveThemeControlChanged:);
    [basicCard addSubview:self.enableBlurCheckbox];
    [basicCard addSubview:[self ym_labelWithFrame:NSMakeRect(48, 222, 420, 18)
                                            text:@"开启后让窗口背后的桌面产生柔和虚化；关闭后仅保留界面透明。"
                                            font:[NSFont systemFontOfSize:11 weight:NSFontWeightRegular]
                                           color:[NSColor colorWithCalibratedWhite:0.62 alpha:1.0]]];

    [basicCard addSubview:[self ym_labelWithFrame:NSMakeRect(26, 186, 120, 20)
                                            text:@"界面透明度"
                                            font:[NSFont systemFontOfSize:13 weight:NSFontWeightMedium]
                                           color:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]]];
    self.alphaValueLabel = [self ym_labelWithFrame:NSMakeRect(430, 186, 52, 20)
                                             text:@"90%"
                                             font:[NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightMedium]
                                            color:[NSColor colorWithCalibratedWhite:0.86 alpha:1.0]];
    self.alphaValueLabel.alignment = NSTextAlignmentRight;
    [basicCard addSubview:self.alphaValueLabel];

    self.alphaSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(26, 160, 456, 24)];
    self.alphaSlider.minValue = 0.60;
    self.alphaSlider.maxValue = 1.00;
    self.alphaSlider.target = self;
    self.alphaSlider.action = @selector(alphaSliderChanged:);
    [basicCard addSubview:self.alphaSlider];
    [basicCard addSubview:[self ym_labelWithFrame:NSMakeRect(26, 140, 456, 18)
                                            text:@"数值越低，底部模糊与流光越明显；推荐 85% ~ 95%。"
                                            font:[NSFont systemFontOfSize:11 weight:NSFontWeightRegular]
                                           color:[NSColor colorWithCalibratedWhite:0.62 alpha:1.0]]];

    [basicCard addSubview:[self ym_labelWithFrame:NSMakeRect(26, 106, 120, 20)
                                            text:@"桌面模糊"
                                            font:[NSFont systemFontOfSize:13 weight:NSFontWeightMedium]
                                           color:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]]];
    self.blurRadiusValueLabel = [self ym_labelWithFrame:NSMakeRect(430, 106, 52, 20)
                                                  text:@"10"
                                                  font:[NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightMedium]
                                                 color:[NSColor colorWithCalibratedWhite:0.86 alpha:1.0]];
    self.blurRadiusValueLabel.alignment = NSTextAlignmentRight;
    [basicCard addSubview:self.blurRadiusValueLabel];

    self.blurRadiusSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(26, 80, 456, 24)];
    self.blurRadiusSlider.minValue = 0;
    self.blurRadiusSlider.maxValue = 80;
    self.blurRadiusSlider.target = self;
    self.blurRadiusSlider.action = @selector(blurRadiusSliderChanged:);
    [basicCard addSubview:self.blurRadiusSlider];
    [basicCard addSubview:[self ym_labelWithFrame:NSMakeRect(26, 60, 456, 18)
                                            text:@"控制真实桌面背景的虚化程度；推荐 10，过高会丢失背景细节。"
                                            font:[NSFont systemFontOfSize:11 weight:NSFontWeightRegular]
                                           color:[NSColor colorWithCalibratedWhite:0.62 alpha:1.0]]];

    [basicCard addSubview:[self ym_labelWithFrame:NSMakeRect(26, 28, 120, 22)
                                            text:@"承载风格"
                                            font:[NSFont systemFontOfSize:13 weight:NSFontWeightMedium]
                                           color:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]]];
    self.carrierStylePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(150, 23, 180, 30) pullsDown:NO];
    [self.carrierStylePopup addItemsWithTitles:@[@"深色", @"浅色"]];
    self.carrierStylePopup.target = self;
    self.carrierStylePopup.action = @selector(liveThemeControlChanged:);
    [basicCard addSubview:self.carrierStylePopup];

    self.keepAliveCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(330, 27, 160, 24)];
    self.keepAliveCheckbox.buttonType = NSSwitchButton;
    self.keepAliveCheckbox.title = @"自动保持";
    self.keepAliveCheckbox.font = [NSFont systemFontOfSize:12 weight:NSFontWeightRegular];
    self.keepAliveCheckbox.target = self;
    self.keepAliveCheckbox.action = @selector(liveThemeControlChanged:);
    [basicCard addSubview:self.keepAliveCheckbox];

    NSButton *cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(326, 28, 88, 34)];
    cancelButton.title = @"关闭主题";
    cancelButton.bezelStyle = NSBezelStyleRounded;
    cancelButton.target = self;
    cancelButton.action = @selector(cancelMistySettings:);
    [contentView addSubview:cancelButton];

    NSButton *confirmButton = [[NSButton alloc] initWithFrame:NSMakeRect(424, 28, 88, 34)];
    confirmButton.title = @"确定配置";
    confirmButton.bezelStyle = NSBezelStyleRounded;
    confirmButton.keyEquivalent = @"\r";
    confirmButton.target = self;
    confirmButton.action = @selector(confirmMistySettings:);
    [contentView addSubview:confirmButton];
}

- (NSView *)ym_cardViewWithFrame:(NSRect)frame
{
    NSView *view = [[NSView alloc] initWithFrame:frame];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 18.0;
    view.layer.masksToBounds = YES;
    view.layer.borderWidth = 1.0;
    view.layer.borderColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.10].CGColor;
    view.layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.12 alpha:0.78].CGColor;
    return view;
}

- (NSTextField *)ym_labelWithFrame:(NSRect)frame
                              text:(NSString *)text
                              font:(NSFont *)font
                             color:(NSColor *)color
{
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    label.stringValue = text ?: @"";
    label.font = font;
    label.textColor = color;
    label.bezeled = NO;
    label.drawsBackground = NO;
    label.editable = NO;
    label.selectable = NO;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    return label;
}

#pragma mark - Settings

- (void)loadSettingsToControls
{
    [MistyModeSettingsWindowController registerDefaults];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    self.enableBlurCheckbox.state = [defaults boolForKey:kThemeMistyWindowBlurEnabled] ? NSControlStateValueOn : NSControlStateValueOff;
    self.colorfulCheckbox.state = [defaults boolForKey:kThemeMistyColorful] ? NSControlStateValueOn : NSControlStateValueOff;
    self.alphaSlider.doubleValue = [defaults doubleForKey:kThemeMistyQNSAlpha];
    self.blurRadiusSlider.integerValue = [defaults integerForKey:kThemeMistyWindowBlurRadius];
    self.colorfulOpacitySlider.doubleValue = [defaults doubleForKey:kThemeMistyColorfulOpacity];
    CGFloat colorfulBlurRadius = [defaults doubleForKey:kThemeMistyColorfulBlurRadius];
    colorfulBlurRadius = MAX(kYMColorfulBlurRadiusMinValue, MIN(kYMColorfulBlurRadiusMaxValue, colorfulBlurRadius));
    self.colorfulBlurRadiusSlider.doubleValue = colorfulBlurRadius;
    self.colorfulAnimationDurationSlider.doubleValue = [defaults doubleForKey:kThemeMistyColorfulAnimationDuration];
    self.keepAliveCheckbox.state = [defaults boolForKey:kThemeMistyKeepAlive] ? NSControlStateValueOn : NSControlStateValueOff;

    NSString *carrierStyle = [defaults stringForKey:kThemeMistyCarrierStyle];
    if ([carrierStyle isEqualToString:kThemeMistyCarrierStyleLight]) {
        [self.carrierStylePopup selectItemAtIndex:1];
    } else {
        [self.carrierStylePopup selectItemAtIndex:0];
    }

    [self updateValueLabels];
}

- (void)saveSettings:(BOOL)isOpen
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // 点击确定后即认为用户启用迷离模式，菜单打勾。
    [defaults setBool:isOpen forKey:kThemeMistyMode];
    [defaults setDouble:self.alphaSlider.doubleValue forKey:kThemeMistyQNSAlpha];
    [defaults setBool:(self.enableBlurCheckbox.state == NSControlStateValueOn) forKey:kThemeMistyWindowBlurEnabled];
    [defaults setInteger:self.blurRadiusSlider.integerValue forKey:kThemeMistyWindowBlurRadius];
    [defaults setBool:(self.colorfulCheckbox.state == NSControlStateValueOn) forKey:kThemeMistyColorful];
    [defaults setDouble:self.colorfulOpacitySlider.doubleValue forKey:kThemeMistyColorfulOpacity];
    CGFloat colorfulBlurRadius = MAX(kYMColorfulBlurRadiusMinValue, MIN(kYMColorfulBlurRadiusMaxValue, self.colorfulBlurRadiusSlider.doubleValue));
    [defaults setDouble:colorfulBlurRadius forKey:kThemeMistyColorfulBlurRadius];
    [defaults setDouble:self.colorfulAnimationDurationSlider.doubleValue forKey:kThemeMistyColorfulAnimationDuration];
    [defaults setBool:(self.keepAliveCheckbox.state == NSControlStateValueOn) forKey:kThemeMistyKeepAlive];

    NSString *carrierStyle = self.carrierStylePopup.indexOfSelectedItem == 1 ? kThemeMistyCarrierStyleLight : kThemeMistyCarrierStyleDark;
    [defaults setObject:carrierStyle forKey:kThemeMistyCarrierStyle];
    [defaults synchronize];
}

- (void)applyThemeSettingsImmediately
{
    Class themeHookClass = NSClassFromString(@"ThemeHook");

    SEL startSelector = @selector(start);
    if (themeHookClass && [themeHookClass respondsToSelector:startSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [themeHookClass performSelector:startSelector];
#pragma clang diagnostic pop
    }

    SEL refreshSelector = @selector(refreshAllQNSViews);
    if (themeHookClass && [themeHookClass respondsToSelector:refreshSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [themeHookClass performSelector:refreshSelector];
#pragma clang diagnostic pop
    }
}

- (void)saveOpenSettingsAndApplyImmediately
{
    [self saveSettings:YES];
    [self applyThemeSettingsImmediately];
}

#pragma mark - Actions

- (void)updateValueLabels
{
    NSInteger alphaPercent = (NSInteger)lround(self.alphaSlider.doubleValue * 100.0);
    self.alphaValueLabel.stringValue = [NSString stringWithFormat:@"%ld%%", (long)alphaPercent];
    self.blurRadiusValueLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)self.blurRadiusSlider.integerValue];

    NSInteger colorfulOpacityPercent = (NSInteger)lround(self.colorfulOpacitySlider.doubleValue * 100.0);
    self.colorfulOpacityValueLabel.stringValue = [NSString stringWithFormat:@"%ld%%", (long)colorfulOpacityPercent];
    self.colorfulBlurRadiusValueLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)lround(self.colorfulBlurRadiusSlider.doubleValue)];
    self.colorfulAnimationDurationValueLabel.stringValue = [NSString stringWithFormat:@"%.0fs", self.colorfulAnimationDurationSlider.doubleValue];
}

- (void)alphaSliderChanged:(NSSlider *)sender
{
    (void)sender;
    [self updateValueLabels];
    [self saveOpenSettingsAndApplyImmediately];
}

- (void)blurRadiusSliderChanged:(NSSlider *)sender
{
    (void)sender;
    [self updateValueLabels];
    [self saveOpenSettingsAndApplyImmediately];
}

- (void)colorfulSliderChanged:(NSSlider *)sender
{
    if (sender == self.colorfulBlurRadiusSlider) {
        sender.doubleValue = MAX(kYMColorfulBlurRadiusMinValue, MIN(kYMColorfulBlurRadiusMaxValue, sender.doubleValue));
    }
    [self updateValueLabels];
    [self saveOpenSettingsAndApplyImmediately];
}

- (void)liveThemeControlChanged:(id)sender
{
    (void)sender;
    [self updateValueLabels];
    [self saveOpenSettingsAndApplyImmediately];
}

- (void)themeCheckboxChanged:(NSButton *)sender
{
    (void)sender;
    [self liveThemeControlChanged:sender];
}

- (void)cancelMistySettings:(id)sender
{
    (void)sender;
    [self saveSettings:NO];
    [self applyThemeSettingsImmediately];
    if (self.confirmHandler) {
        self.confirmHandler(NO);
    }
    [self.window close];
}

- (void)confirmMistySettings:(id)sender
{
    (void)sender;

    [self saveSettings:YES];
    [self applyThemeSettingsImmediately];

    if (self.confirmHandler) {
        self.confirmHandler(YES);
    }

    [self.window close];
}

@end
