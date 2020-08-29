//
//  ViewController.m
//  实现上拉和下拉刷新
//
//  Created by song jian on 2020/6/25.
//  Copyright © 2020 song jian. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic,assign) NSInteger dataCount;

/** 下拉刷新控件*/
@property (nonatomic, weak) UIView *header;
/** 下拉刷新label*/
@property (nonatomic, weak) UILabel *headerLabel;
/** 下拉刷新的h状态*/
@property (nonatomic, assign, getter=isHeaderRefreshing) BOOL headerRefreshing;

/** 上拉刷新控件*/
@property (nonatomic, weak) UIView *footer;
/** 上拉刷新label*/
@property (nonatomic, weak) UILabel *footerLabel;
/** 上拉刷新的h状态*/
@property (nonatomic, assign, getter=isFooterRefreshing) BOOL footerRefreshing;

@end

@implementation ViewController

 static CGFloat offsetY = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    NSLog(@"%@",NSStringFromCGRect(self.tableView.frame));
    self.dataCount = 20;
    [self setRefresh];
}

- (void)setRefresh{
    //通过headerview设置广告条等控件
    UILabel *adLab = [[UILabel alloc] init];
    adLab.backgroundColor = [UIColor redColor];
    adLab.text = @"我是广告";
    adLab.frame = CGRectMake(0, 0, 0, 30);
    adLab.textAlignment = NSTextAlignmentCenter;
    self.tableView.tableHeaderView = adLab;
    
    //设置下拉刷新的控件
    UIView *header = [[UIView alloc] init];
    header.frame = CGRectMake(0, -50, self.tableView.bounds.size.width, 50);
    header.backgroundColor = [UIColor blueColor];
    self.header = header;
    [self.tableView addSubview:header];
    UILabel *headerLab = [[UILabel alloc] init];
    headerLab.text = @"下拉可以刷新";
    headerLab.textAlignment = NSTextAlignmentCenter;
    headerLab.frame = header.bounds;
    self.headerLabel = headerLab;
    [self.header addSubview:headerLab];
    
    //设置上拉刷新的控件
    UIView *footer = [[UIView alloc] init];
    footer.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 35);
    footer.backgroundColor = [UIColor redColor];
    self.footer = footer;
    
    UILabel *footerLab = [[UILabel alloc] init];
    footerLab.text = @"上拉可以刷新更多";
    footerLab.textAlignment = NSTextAlignmentCenter;
    footerLab.frame = footer.bounds;
    self.footerLabel = footerLab;
    [footer addSubview:footerLab];
    self.tableView.tableFooterView = footer;
    
}

#pragma mark - 数据源方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellId = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        
    }
    cell.textLabel.text = [NSString stringWithFormat:@"第%ld条数据",(long)indexPath.row];
    if (indexPath.row == 0) {
        NSLog(@"%@",NSStringFromCGRect(cell.frame));
    }
    
    return cell;
}

#pragma mark - scrollview代理方法
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    NSLog(@"contentsize--%@",NSStringFromCGSize(self.tableView.contentSize));
    NSLog(@"frame--%@",NSStringFromCGRect(self.tableView.frame));
    NSLog(@"bounds--%@",NSStringFromCGRect(self.tableView.bounds));
    NSLog(@"contentInset--%@",NSStringFromUIEdgeInsets(self.tableView.contentInset));
    NSLog(@"contentOffset--%@",NSStringFromCGPoint(self.tableView.contentOffset));
    [self dealHeader];
    [self dealFooter];
   
}

/**
 用户松开手指时调用
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    //在header完全出现时松开了手指才会进行刷新
    if (self.tableView.contentOffset.y < offsetY) {
        [self headerBeginRefreshing];
    }
}

#pragma mark - 下拉刷新向服务器请求数据
- (void)loadNewData{
    //模拟请求数据的延迟
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.dataCount = 25;
        [self.tableView reloadData];
        //结束刷新
        [self headerEndRefreshing];
    });
}

#pragma mark - 上拉刷新向服务器请求数据
- (void)loadMoreData{
    //模拟请求数据的延迟
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.dataCount += 10;
        [self.tableView reloadData];
        //结束刷新
        [self footerEndRefreshing];
    });
}



#pragma mark - 开始下拉刷新的方法
- (void)headerBeginRefreshing{
    if (self.isHeaderRefreshing) {
        return;
    }
    self.headerLabel.text = @"正在刷新数据";
    self.header.backgroundColor = [UIColor greenColor];
    self.headerRefreshing = YES;
    [UIView animateWithDuration:0.25 animations:^{
        //修改tableview的内边距使得刷新时可以让header停留在用户视线内
        UIEdgeInsets inset = self.tableView.contentInset;
        inset.top += self.header.bounds.size.height;
        self.tableView.contentInset = inset;
    }];
    //请求数据
    [self loadNewData];
}

#pragma mark - 结束下拉刷新的方法
- (void)headerEndRefreshing{
    self.headerRefreshing = NO;
    [UIView animateWithDuration:0.25 animations:^{
        //修改tableview的内边距使得刷新时可以让header停留在用户视线内
        UIEdgeInsets inset = self.tableView.contentInset;
        inset.top -= self.header.bounds.size.height;
        self.tableView.contentInset = inset;
    }];
    //由于内边距减小会自动滚回去，调用scrollViewDidScroll方法，里面已实现改变header具体样式的方法
}

#pragma mark - 处理下拉刷新控件变化的方法
- (void)dealHeader{
   
    //如果正处于下拉刷新则直接返回
    if (self.isHeaderRefreshing) {
        return;
    }
    offsetY = -(getRectNavAndStatusHight + self.headerLabel.bounds.size.height);
    
    if (self.tableView.contentOffset.y < offsetY) {
        self.headerLabel.text = @"松开立即刷新";
        self.header.backgroundColor = [UIColor grayColor];
    } else{
        self.headerLabel.text = @"下拉可以刷新";
        self.header.backgroundColor = [UIColor blueColor];
    }
}

#pragma mark - 处理上拉刷新控件变化的方法
- (void)dealFooter{
    if (self.tableView.contentSize.height == 0) {
        return;
    }
    CGFloat footerOffset = self.tableView.contentSize.height - self.tableView.frame.size.height + kTabBarHeight_X;
    if (self.tableView.contentOffset.y >= footerOffset) {
        [self footerBeginRefreshing];
    }
}

- (void)footerBeginRefreshing{
    if (self.isFooterRefreshing) {
        return;
    }
    self.footerRefreshing = YES;
    self.footerLabel.text = @"正在加载更多数据";
    self.footer.backgroundColor = [UIColor orangeColor];
    //发送请求给服务器
    [self loadMoreData];
}

- (void)footerEndRefreshing{
    self.footerRefreshing = NO;
    self.footerLabel.text = @"上拉可以刷新更多";
    self.footer.backgroundColor = [UIColor redColor];
}


@end
