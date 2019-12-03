//
//  MsgObject.m
//  Hybrid Bridge
//
//  Created by zzg on 2019/7/11.
//  Copyright © 2019 zzg. All rights reserved.
//

#import "MsgObject.h"

@interface MsgObject()
@property (nonatomic, copy) NSString * handler;
@property (nonatomic, copy) NSString * action;
@property (nonatomic, copy) NSDictionary * paramters;
@property (nonatomic, copy) NSString * callbackID;
@property (nonatomic, copy) NSString * callbackFunction;

@property (nonatomic, strong) NSMutableDictionary * handlerMap;

@property (nonatomic, strong) NSDictionary * paramtersDictionary;

@property (nonatomic, copy) void(^callHandler)(NSDictionary* responseData);

@end

@implementation MsgObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.handlerMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        self.handler = dict[@"handler"];
        self.action = dict[@"action"];
        self.paramters = dict[@"params"];
        
        self.callbackID = [dict[@"callbackId"] stringValue];
        self.callbackFunction = dict[@"callbackFunction"];
    }
    return self;
}


- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
}

-(void)setWeakWKWebView:(WKWebView *)weakWKWebView {
    _weakWKWebView = weakWKWebView;
}


- (void)registerHandler:(NSString *)handlerName Action:(NSString *)actionName handler:(HandlerBlock)handler {
    if (handlerName && actionName && handler) {
        NSMutableDictionary *handlerDic = [self.handlerMap objectForKey:handlerName];
        if (!handlerDic) {
            handlerDic = [[NSMutableDictionary alloc]init];
        }
        [self.handlerMap setObject:handlerDic forKey:handlerName];
        [handlerDic setObject:handler forKey:actionName];
    }
}

-(void)sendEventName:(NSString *)event withParams:(NSDictionary *)params withCallback:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))handler{
    NSString *jsFunction = @"window.eventDispatcher";
    [self injectMessageFuction:jsFunction withActionId:event withParams:params withCallback:handler];
}


- (void)removehandler:(NSString *)handlerName {
    if (handlerName) {
        [self.handlerMap removeObjectForKey:handlerName];
    }
}

- (void)userContentControllerDidReceiveScriptMessage:(MsgObject *)message {
    NSLog(@"userContentControllerDidReceiveScriptMessage");
    NSDictionary *handlerDic = [self.handlerMap objectForKey:message.handler];
    HandlerBlock handler = [handlerDic objectForKey:message.action];
    // 处理回调
    if (message.callbackID && message.callbackID.length > 0) {
        // oc call js
        JSResponseCallback callback = ^(id responseData){
            [self injectMessageFuction:message.callbackFunction withActionId:message.callbackID withParams:responseData withCallback:nil];
        };
        [message setCallback:callback];
    }
    if (handler) {
        handler(message);
    }
}

- (void)setCallback:(JSResponseCallback)callback {
    _callHandler = callback;
}

- (void)callback:(NSDictionary *)result {
    self.paramtersDictionary = result;
    if (_callHandler) {
        _callHandler(self.paramtersDictionary);
    }
}

// 通信回调
-(void)injectMessageFuction:(NSString *)msg withActionId:(NSString *)actionId withParams:(NSDictionary *)params withCallback:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))handler{
    if (!params) {
        params = @{};
    }
    NSString *paramsString = [self _serializeMessageData:params];
    NSString *paramsJSString = [self _transcodingJavascriptMessage:paramsString];
    NSString* javascriptCommand = [NSString stringWithFormat:@"%@('%@', '%@');", msg,actionId,paramsJSString];
    if ([[NSThread currentThread] isMainThread]) {
        [self.weakWKWebView evaluateJavaScript:javascriptCommand completionHandler:handler];
    } else {
        __strong typeof(self)strongSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [strongSelf.weakWKWebView evaluateJavaScript:javascriptCommand completionHandler:handler];
        });
    }
}
// 字典JSON化
- (NSString *)_serializeMessageData:(id)message{
    if (message) {
        return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
    }
    return nil;
}
// JSON Javascript编码处理
- (NSString *)_transcodingJavascriptMessage:(NSString *)message
{
    //NSLog(@"dispatchMessage = %@",message);
    message = [message stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    message = [message stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    message = [message stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    message = [message stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    message = [message stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    message = [message stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    message = [message stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    message = [message stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    return message;
}
@end
