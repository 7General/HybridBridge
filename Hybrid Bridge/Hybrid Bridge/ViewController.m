//
//  ViewController.m
//  Hybrid Bridge
//
//  Created by zzg on 2019/7/11.
//  Copyright © 2019 zzg. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "MsgObject.h"


@interface ViewController ()<WKUIDelegate,WKScriptMessageHandler,WKNavigationDelegate>

@property (nonatomic, strong) MsgObject * msgObject;

@property (nonatomic, strong) WKUserContentController * userContentController;
@property (nonatomic, strong) WKWebView *wkWebView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebViewConfiguration * configuration = [[WKWebViewConfiguration alloc]init];
    self.userContentController =[[WKUserContentController alloc]init];
    configuration.userContentController = self.userContentController;
    
    
    self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height) configuration:configuration];
    self.wkWebView.UIDelegate = self;
    self.wkWebView.navigationDelegate = self;
    [self.view addSubview:self.wkWebView];
    
    
    self.msgObject = [[MsgObject alloc] init];
    self.msgObject.weakWKWebView = self.wkWebView;
    
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSURL *baseUrl = [NSURL fileURLWithPath:bundlePath isDirectory:YES];
    NSString * path = [[NSBundle mainBundle] pathForResource:@"bridge.html" ofType:nil];
    NSString *indexContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    [self.wkWebView loadHTMLString:indexContent baseURL:baseUrl];
    
    [self.userContentController addScriptMessageHandler:self name:@"WKJSBridge"];
    

    [self.msgObject registerHandler:@"common" Action:@"nativeLog" handler:^(MsgObject * _Nonnull msg) {
        NSLog(@"js call oc Success  nativeLog");
    }];
    
    [self.msgObject registerHandler:@"common" Action:@"nativeParams" handler:^(MsgObject * _Nonnull msg) {
        NSLog(@"js call oc Success  nativeParams");
        [msg callback:@{@"city":@"bj",@"domain":@"gj"}];
    }];
    
    UIButton *occalljs = [UIButton buttonWithType:UIButtonTypeCustom];
    occalljs.frame = CGRectMake(0, 200, 200, 50);
    occalljs.backgroundColor = [UIColor grayColor];
    [occalljs setTitle:@"oc call js 无回调" forState:UIControlStateNormal];
    [occalljs addTarget:self action:@selector(ocCallJs) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:occalljs];
    
    UIButton *occalljsPar = [UIButton buttonWithType:UIButtonTypeCustom];
    occalljsPar.frame = CGRectMake(0, 260, 200, 50);
    occalljsPar.backgroundColor = [UIColor grayColor];
    [occalljsPar setTitle:@"oc call js 有回调" forState:UIControlStateNormal];
    [occalljsPar addTarget:self action:@selector(ocCallJspars) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:occalljsPar];
}

- (void)ocCallJs {
    [self.msgObject sendEventName:@"ocWakeJS" withParams:@{@"CITY":@"BEIJING",@"AGES":@"IO"} withCallback:nil];
}

- (void)ocCallJspars {
    [self.msgObject sendEventName:@"ocwakejsparams" withParams:@{@"CITY":@"henan",@"AGES":@"IO"} withCallback:^(id _Nullable resoult, NSError * _Nullable error) {
        NSLog(@"----oc  call  js  有回调函数：%@",resoult);
    }];
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认"style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary * msgBody = message.body;
    if (msgBody) {
        MsgObject * msg = [[MsgObject alloc] initWithDictionary:msgBody];
        [self.msgObject userContentControllerDidReceiveScriptMessage:msg];
    }
}

@end


