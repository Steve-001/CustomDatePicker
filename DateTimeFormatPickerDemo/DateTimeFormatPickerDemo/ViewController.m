//
//  ViewController.m
//  DateTimeFormatPickerDemo
//
//  Created by vivacheck on 2025/5/29.
//

#import "ViewController.h"
#import <DateTimeFormatPickerDemo-Swift.h>


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *btn;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    [self setupBtnTitle];
}
- (void)setupBtnTitle{
    NSDateFormatter * fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"MM/dd/yyyy hh:mm a";
    NSString * date_str = [fmt stringFromDate:[NSDate date]];
    [self.btn setTitle:date_str forState:UIControlStateNormal];
    
}
- (IBAction)clickOnButton:(UIButton *)sender {
    NSDateFormatter * fmt = [NSDateFormatter new];
    fmt.dateFormat = @"MM/dd/yyyy hh:mm a";
    NSDate * date = [fmt dateFromString:sender.currentTitle];
    [self showMydatePickerWithDate:date dateFormat:VVDateFormat_MMddyyyyhhmmA];
}



-(void)showMydatePickerWithDate:(NSDate *)date dateFormat:(VVDateFormat_)dateFormat{
    NSDate * minDate = [NSDate dateWithTimeIntervalSinceNow:-30*24*60*60]; //
    NSDate * maxDate = [NSDate dateWithTimeIntervalSinceNow:30*24*60*60]; // 30天后
    BottomSheetVC * bottomVC = [[BottomSheetVC alloc] initWithFormatType:dateFormat
                                                                    date:date
                                                                 maxDate:[NSDate date]
                                                                 minDate:nil
                                                           confirmAction:^(NSDateComponents * _Nonnull dateComponents,NSDate * _Nonnull date, NSString * _Nonnull date_str) {
        NSLog(@"-- 选择了时间：%@\n date_str:%@\n year:%ld month:%ld day:%ld hour:%ld min:%ld",date,date_str,dateComponents.year,dateComponents.month,dateComponents.day,dateComponents.hour,dateComponents.minute);
        [self.btn setTitle:date_str forState:UIControlStateNormal];
    }];
    bottomVC.toolBarBGColor = [UIColor purpleColor];
    bottomVC.cancel_title = @"Cancel";
    bottomVC.confirm_title = @"Confirm";
    [bottomVC showInVc:self];
}

@end
