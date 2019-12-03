//
//  WebViewJavascriptBridgeBase.m
//  HybridJSBridge
//
//  Created by zzg on 2019/11/30.
//  Copyright © 2019 zzg. All rights reserved.
//

#import "WebViewJavascriptBridgeBase.h"

static bool logging = false;
static int logMaxLength = 500;

#define kOldProtocolScheme @"wvjbscheme"
#define kNewProtocolScheme @"https"
#define kQueueHasMessage   @"__wvjb_queue_message__"
#define kBridgeLoaded      @"__bridge_loaded__"


#define kRESPONSEID @"responseId"
#define kRESPONSEDATA @"responseData"

@interface WebViewJavascriptBridgeBase()
@property (nonatomic, assign) long  _uniqueId;

@end

@implementation WebViewJavascriptBridgeBase

+ (void)enableLogging {
    logging = YES;
}

+ (void)setLogMaxLength:(int)length {
    logMaxLength = length;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.startupMessageQueue = [NSMutableArray array];
        self.responseCallbacks = [NSMutableDictionary dictionary];
        self.messageHandlers = [NSMutableDictionary dictionary];
        __uniqueId = 0;
    }
    return self;
}



- (BOOL)isWebViewJavascriptBridgeURL:(NSURL*)url {
    if (![self isSchemeMatch:url]) {
        return NO;
    }
    return [self isBridgeLoadedURL:url] || [self isQueueMessageURL:url];
}

- (BOOL)isSchemeMatch:(NSURL*)url {
    NSString* scheme = url.scheme.lowercaseString;
    return [scheme isEqualToString:kNewProtocolScheme] || [scheme isEqualToString:kOldProtocolScheme];
}

- (BOOL)isQueueMessageURL:(NSURL*)url {
    NSString* host = url.host.lowercaseString;
    return [self isSchemeMatch:url] && [host isEqualToString:kBridgeLoaded];
}

- (BOOL)isBridgeLoadedURL:(NSURL*)url {
    NSString* host = url.host.lowercaseString;
    return [self isSchemeMatch:url] && [host isEqualToString:kQueueHasMessage];
}

- (void)injectJavascriptFile:(NSURL *)url {
    NSDictionary * dict = [self parameterWithURL:url];
    NSString * responseId = [dict objectForKey:kRESPONSEID];
    if (responseId.length > 0) {
        WVJBResponseCallback callBack = [self.responseCallbacks objectForKey:responseId];
        NSString * responseData = [dict objectForKey:kRESPONSEDATA];
        if (callBack) {
            callBack(responseData);
        }
    }
}

- (void)flushMessageQueue:(NSString *)messageQueueStrin {
    if (messageQueueStrin == nil || messageQueueStrin.length == 0) {
        return;
    }
    id messages = [self _deserializeMessageJSON:messageQueueStrin];
    
    for (WVJBMessage * message in messages) {
        if (![message isKindOfClass:[WVJBMessage class]]) {
            return;
        }
        NSString * responeId = message[@"responseId"];
        if (responeId) {

        } else {
            WVJBResponseCallback responseCallBack = NULL;
            NSString * callbackId = message[@"callbackId"];
            if (callbackId) {
                responseCallBack = ^(id responseData){
                    if (responseData == nil) {
                        responseData = [NSNull null];
                    }
                    WVJBMessage * msg = @{@"responseId":callbackId,@"responseData":responseData};
                    [self _queueMessage:msg];
                };
            } else {
                
            }
            WVJBHandler handler = self.messageHandlers[message[@"handlerName"]];
            if (!handler) {
                continue;
            }
            handler(message[@"data"],responseCallBack);
        }
    }
}

- (NSArray*)_deserializeMessageJSON:(NSString *)messageJSON {
    return [NSJSONSerialization JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
}

/**
 获取url的所有参数
 @param url 需要提取参数的url
 @return NSDictionary
 */
- (NSDictionary *)parameterWithURL:(NSURL *)url {
    NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithCapacity:2];
    
    //传入url创建url组件类
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:url.absoluteString];
    
    //回调遍历所有参数，添加入字典
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [params setObject:obj.value forKey:obj.name];
    }];
    
    return params;
}



- (void)sendData:(id)data responseCallback:(WVJBResponseCallback)responseCallback handlerName:(NSString*)handlerName {
    NSMutableDictionary * message = [NSMutableDictionary dictionary];
    if (data) {
        message[@"data"] = data;
    }
    if (responseCallback) {
        NSString * callbackId = [NSString stringWithFormat:@"objc_cb_%ld",++__uniqueId];
        self.responseCallbacks[callbackId] = [responseCallback copy];
        message[@"callbackId"] = callbackId;
    }
    
    if (handlerName) {
        message[@"handlerName"] = handlerName;
    }
    [self _queueMessage:message];
}

- (void)logUnkownMessage:(NSURL*)url {
    NSLog(@"WebViewJavascriptBridge: WARNING: Received unknown WebViewJavascriptBridge command %@", [url absoluteString]);
}

- (NSString *)webViewJavascriptFetchQueyCommand {
    return @"WebViewJavascriptBridge._fetchQueue();";
}

- (void)_queueMessage:(WVJBMessage*)message {
//    if (self.startupMessageQueue) {
//        [self.startupMessageQueue addObject:message];
//    } else {
//    [self _dispatchMessage:message];
//    }
    
    if (self.startupMessageQueue) {
        [self.startupMessageQueue addObject:message];
    }
    [self _dispatchMessage:message];
}



- (void)_dispatchMessage:(WVJBMessage*)message {
    NSString *messageJSON = [self _serializeMessage:message pretty:NO];
//    [self _log:@"SEND" json:messageJSON];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    NSString* javascriptCommand = [NSString stringWithFormat:@"WebViewJavascriptBridge._handleMessageFromObjC('%@');", messageJSON];
    if ([[NSThread currentThread] isMainThread]) {
        [self _evaluateJavascript:javascriptCommand];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self _evaluateJavascript:javascriptCommand];
        });
    }
}

- (void) _evaluateJavascript:(NSString *)javascriptCommand {
    [self.delegate _evaluateJavascript:javascriptCommand];
}


- (NSString *)_serializeMessage:(id)message pretty:(BOOL)pretty{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:(NSJSONWritingOptions)(pretty ? NSJSONWritingPrettyPrinted : 0) error:nil] encoding:NSUTF8StringEncoding];
}
@end
