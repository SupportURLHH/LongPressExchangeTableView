//
//  LongPressTableView.h
//  JYJSLongPressSequenceTableView
//
//  Created by DEVP-IOS-03 on 16/8/21.
//  Copyright © 2016年 Hangzhou Jiyuan Jingshe Trade Co,. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

//自动滚动方向
typedef enum {
    AutoScrollUp,
    AutoScrollDown
}  AutoScroll;


@class  LongPressTableView;

@protocol LongPressTableViewDelegate <NSObject>

@optional
-(void)tableView:(LongPressTableView *)tableView didBeganLongPressCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;

-(void)tableViewDidExchange:(LongPressTableView *)tableView ;

-(void)tableViewDidEndLongPress:(LongPressTableView *)tableView;

@end

/**
 长按cell,cell可滑动切换顺序
 */
@interface LongPressTableView : UITableView

@property (nonatomic, weak) id <LongPressTableViewDelegate> longPressDelegate;
/**
 *  tableView的数据源，必须跟外界的数据源一致
 *  不能是外界数据源copy出来的，也必须是可变的
 *
 */
@property (nonatomic, strong) NSMutableArray *dataArray;

/**
 *  当cell拖拽到tableView边缘时,tableView的滚动速度
 *  每个时间单位滚动多少距离，默认为3
 */
@property (nonatomic, assign) CGFloat scrollSpeed;

/**
 *  所有cell恢复到拖动之前的位置
 */
- (void)resetCellLocation;
@end
