#import <UIKit/UIColor.h>
#import <UIKit/UIViewController.h>

@protocol HBColorPickerDelegate <NSObject>
@optional
- (void)colorPicker:(id)colorPicker didSelectColor:(UIColor *)color;
@end

@interface HBColorPickerConfiguration : NSObject
@property (nonatomic, assign) BOOL supportsAlpha;
- (instancetype)initWithColor:(UIColor *)color;
@end

@interface HBColorPickerViewController : UIViewController
@property (strong, nonatomic) NSObject <HBColorPickerDelegate> *delegate;
@property (strong, nonatomic) HBColorPickerConfiguration *configuration;
@end
