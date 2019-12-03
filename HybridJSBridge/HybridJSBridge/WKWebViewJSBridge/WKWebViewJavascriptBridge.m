//
//  WKWebViewJavascriptBridge.m
//  HybridJSBridge
//
//  Created by zzg on 2019/11/30.
//  Copyright © 2019 zzg. All rights reserved.
//

#import "WKWebViewJavascriptBridge.h"
#import "WebViewJavascriptBridgeBase.h"


@interface WKWebViewJavascriptBridge ()
@property (nonatomic, weak) WKWebView * webView;
@property (nonatomic, strong) WebViewJavascriptBridgeBase * base;

@property (nonatomic, weak) id<WKNavigationDelegate>  webViewDelegate;

@end

@implementation WKWebViewJavascriptBridge

+ (instancetype)bridgeForWebView:(WKWebView*)webView {
    WKWebViewJavascriptBridge * bridge = [[self alloc] init];
    [bridge setupInstance:webView];
    
    return bridge;
}

+ (void)enableLogging {
    [WebViewJavascriptBridgeBase enableLogging];
}

- (void)setupInstance:(WKWebView *)webView {
    self.webView = webView;
    self.webView.navigationDelegate = self;
    self.base = [[WebViewJavascriptBridgeBase alloc] init];
    self.base.delegate = self;
}

- (void)setWebViewDelegate:(id<WKNavigationDelegate>)webViewDelegate {
    _webViewDelegate = webViewDelegate;
}

- (void)registerHandler:(NSString*)handlerName handler:(WVJBHandler)handler {
    self.base.messageHandlers[handlerName] = [handler copy];
}

- (void)callHandler:(NSString*)handlerName {
    [self callHandler:handlerName data:nil responseCallback:nil];
}

- (void)callHandler:(NSString*)handlerName data:(id)data {
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void)callHandler:(NSString*)handlerName data:(id)data responseCallback:(WVJBResponseCallback)responseCallback {
     [self.base sendData:data responseCallback:responseCallback handlerName:handlerName];
}




-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (webView != _webView) { return; }
    NSURL *url = navigationAction.request.URL;
//    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    
    if ([_base isWebViewJavascriptBridgeURL:url]) {
        if ([_base isBridgeLoadedURL:url]) {
            [_base injectJavascriptFile:url];
        } else if ([_base isQueueMessageURL:url]) {
            [self WKFlushMessageQueue];
        } else {
            [_base logUnkownMessage:url];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
//    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
//        [_webViewDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
//    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
//    }
}


- (void)WKFlushMessageQueue {
    [_webView evaluateJavaScript:[_base webViewJavascriptFetchQueyCommand] completionHandler:^(NSString* result, NSError* error) {
        if (error != nil) {
            NSLog(@"WebViewJavascriptBridge: WARNING: Error when trying to fetch data from WKWebView: %@", error);
        }
        [_base flushMessageQueue:result];
    }];
}

#pragma mark WebViewJavascriptBridgeBaseDelegate
- (NSString *)_evaluateJavascript:(NSString *)javascriptCommand {
    [self.webView evaluateJavaScript:javascriptCommand completionHandler:nil];
    return NULL;
}

@end
