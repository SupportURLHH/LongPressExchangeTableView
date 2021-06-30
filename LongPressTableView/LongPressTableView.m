//
//  LongPressTableView.m
//  JYJSLongPressSequenceTableView
//
//  Created by DEVP-IOS-03 on 16/8/21.
//  Copyright © 2016年 Hangzhou Jiyuan Jingshe Trade Co,. Ltd. All rights reserved.
//

#import "LongPressTableView.h"

@interface LongPressTableView()
@property (nonatomic, strong) NSMutableArray *originalArray;//初始的数据源
@property (nonatomic, strong) UIImageView *cellImageView;//cell 截图
@property (nonatomic, strong) NSIndexPath *fromIndexPath;//根据手势点击的位置，获取被点击cell所在的indexPath
@property (nonatomic, strong) NSIndexPath *toIndexPath;//根据手势的位置，获取手指移动到的cell的indexPath
@property (nonatomic, strong) CADisplayLink *displayLink;//是一个能让我们以和屏幕刷新率相同的频率将内容画到屏幕上的定时器。
@property (nonatomic, assign) AutoScroll autoScroll;
@property (nonatomic, assign) NSInteger index;
@end

@implementation LongPressTableView

//无论tableView是用代码创建还是xib创建，都会调用该方法
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    //设置默认滚动速度为3
    if (_scrollSpeed == 0) _scrollSpeed = 3;
    //给tableView添加手势
    [self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)]];
}

- (void)setDataArray:(NSMutableArray *)dataArray {
    _dataArray = dataArray;
    //将原始数组copy一份，便于以后的复原操作
    _originalArray = [dataArray mutableCopy];

}
#pragma mark - 长按拖动
-(void)longPressGestureRecognized:(UILongPressGestureRecognizer *)sender{

    UIGestureRecognizerState state = sender.state;
    CGPoint location = [sender locationInView:self];//获取点击的位置
    _toIndexPath = [self indexPathForRowAtPoint:location];

    switch (state) {
        case UIGestureRecognizerStateBegan: {
            _fromIndexPath = _toIndexPath;
            /*这里记录开始点按的位置*/
            UITableViewCell *cell = [self cellForRowAtIndexPath:_fromIndexPath];

            if ([_longPressDelegate respondsToSelector:@selector(tableView:didBeganLongPressCell:forRowAtIndexPath:)]) {
                [_longPressDelegate tableView:self didBeganLongPressCell:cell forRowAtIndexPath:_fromIndexPath];
            }

            _cellImageView = [self customCellImageViewFromView:cell];
            _cellImageView.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
            _cellImageView.alpha = 0.0;
            [UIView animateWithDuration:0.2 animations:^{
                _cellImageView.frame = CGRectMake(cell.frame.origin.x, location.y, cell.frame.size.width, cell.frame.size.height);
                _cellImageView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                _cellImageView.alpha = 0.4;
                cell.alpha = 0.0;
            } completion:^(BOOL finished) {
                cell.hidden = YES;
                //这里刷新,是为了显示点按后的效果进行刷新,
                [self reloadData];
            }];

            break;
        }

        case UIGestureRecognizerStateChanged: {
            //具体查看效果,因为点按的#(1,2,3等),大小需要保持不变,这个时候,不能用 origin.y 进行计算位置,不然手指不会处于模块#的位置,无法对齐
            CGPoint center = _cellImageView.center;
            center.y = location.y;
            _cellImageView.center = center;
            if ([self isScrollToEdge]){
                [self startTimerToScrollTableView];

            }else{
                [_displayLink invalidate];
            }

            if (_toIndexPath && ![_toIndexPath isEqual:_fromIndexPath]){
                // 交换数组数据
                [self.dataArray exchangeObjectAtIndex:_fromIndexPath.row withObjectAtIndex:_toIndexPath.row];
                // 移动cell
                [self moveRowAtIndexPath:_fromIndexPath toIndexPath:_toIndexPath];
                // 交换后,到达位置,变成开始位置
                _fromIndexPath = _toIndexPath;
                if ([_longPressDelegate respondsToSelector:@selector(tableViewDidExchange:)]) {
                    [_longPressDelegate tableViewDidExchange:self];
                }
            }
            break;
        }

        default: {

            // 停止滚动
            [_displayLink invalidate];
            if ([_longPressDelegate respondsToSelector:@selector(tableViewDidEndLongPress:)]) {
                [_longPressDelegate tableViewDidEndLongPress:self];
            }
            //将隐藏的cell显示出来，并将imageView移除掉
            UITableViewCell *cell = [self cellForRowAtIndexPath:_fromIndexPath];
            cell.hidden = NO;
            cell.alpha = 0.0;
            [UIView animateWithDuration:0.2 animations:^{
                _cellImageView.center = cell.center;
                _cellImageView.alpha = 0.0;
                cell.alpha = 1.0;

            } completion:^(BOOL finished) {
                _toIndexPath = nil;
                _cellImageView = nil;
                [self.cellImageView removeFromSuperview];
                
            }];
            [self reloadData];
            break;
        }
    }
}

-(BOOL)isScrollToEdge {
    //imageView拖动到tableView顶部，且tableView没有滚动到最上面
    if ((CGRectGetMaxY(self.cellImageView.frame)-10 > self.contentOffset.y + self.frame.size.height - self.contentInset.bottom) && (self.contentOffset.y-10 < self.contentSize.height - self.frame.size.height + self.contentInset.bottom)) {
        self.autoScroll = AutoScrollDown;
        return YES;
    }

    //imageView拖动到tableView底部，且tableView没有滚动到最下面
    if ((self.cellImageView.frame.origin.y < self.contentOffset.y + self.contentInset.top) && (self.contentOffset.y > -self.contentInset.top)) {
        self.autoScroll = AutoScrollUp;
        return YES;
    }
    return NO;
}

-(void)startTimerToScrollTableView {
    [_displayLink invalidate];
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(scrollTableView)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)scrollTableView{
    //如果已经滚动到最上面或最下面，则停止定时器并返回,手势结束时候,定时器也要停止
    if ((_autoScroll == AutoScrollUp && self.contentOffset.y <= -self.contentInset.top)|| (_autoScroll == AutoScrollDown && self.contentOffset.y >= self.contentSize.height - self.frame.size.height + self.contentInset.bottom)) {
        [_displayLink invalidate];
        return;
    }
    /*改变tableView的contentOffset，实现自动滚动*/
    CGFloat height = _autoScroll == AutoScrollUp? -_scrollSpeed : _scrollSpeed;
    [self setContentOffset:CGPointMake(0, self.contentOffset.y + height)];
    _cellImageView.center = CGPointMake(_cellImageView.center.x, _cellImageView.center.y+height);
    /*
     滚动tableView的同时也要执行交换操作,(这里用center 是防止获取 fromIndexPath丢失)
     */
    _toIndexPath = [self indexPathForRowAtPoint:_cellImageView.center];
    //这里每次增加的值 为3,取得的到达位置(_toIndexPath),可能一样,这个时候需要判断是否交换
    if (_toIndexPath && ![_toIndexPath isEqual:_fromIndexPath]){
        [self.dataArray exchangeObjectAtIndex:_fromIndexPath.row withObjectAtIndex:_toIndexPath.row];
        [self moveRowAtIndexPath:_fromIndexPath toIndexPath:_toIndexPath];
        _fromIndexPath = _toIndexPath;
        if ([_longPressDelegate respondsToSelector:@selector(tableViewDidExchange:)]) {
            [_longPressDelegate tableViewDidExchange:self];
        }
    }
}

- (UIImageView *)customCellImageViewFromView:(UIView *)inputView {
    //截出图片
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, 0.0);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //截图试图
    UIImageView *cellImageView = [[UIImageView alloc] initWithImage:image];
    cellImageView.layer.masksToBounds = NO;
    cellImageView.layer.shadowOffset = CGSizeMake(-9.0, 0.0);
    cellImageView.layer.shadowRadius = 3.0;
    cellImageView.layer.shadowOpacity = 2.5;
    [self addSubview:cellImageView];
    return cellImageView;
}

/**
 * 所有cell恢复到拖动之前的位置
 */
- (void)resetCellLocation{
    [_dataArray removeAllObjects];
    [_dataArray addObjectsFromArray:_originalArray];
    [self reloadData];
}
@end
