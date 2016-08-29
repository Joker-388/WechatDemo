//
//  ViewController.m
//  JKRWechatPayDemo
//
//  Created by tronsis_ios on 16/8/29.
//  Copyright © 2016年 tronsis_ios. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (NSString *)generateTradeNO {
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand((unsigned)time(0));
    for (int i = 0; i < kNumber; i++) {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}

- (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

- (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSString *tradeNO = [self generateTradeNO];
    NSString *addressIP = [self getIPAddress:YES];
    NSString *orderno = [NSString stringWithFormat:@"%ld",time(0)];
    DataMD5 *data = [[DataMD5 alloc] initWithAppid:WX_APPID mch_id:MCH_ID nonce_str:tradeNO partner_id:WX_PartnerKey body:@"充值" out_trade_no:orderno total_fee:PRICE spbill_create_ip:addressIP notify_url:NOTIFY_URL trade_type:TRADE_TYPE];
    NSString *string = [[data dic] XMLString];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
    [manager.requestSerializer setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [manager.requestSerializer setValue:WXUNIFIEDORDERURL forHTTPHeaderField:@"SOAPAction"];
    [manager.requestSerializer setQueryStringSerializationWithBlock:^NSString * _Nonnull(NSURLRequest * _Nonnull request, id  _Nonnull parameters, NSError * _Nullable __autoreleasing * _Nullable error) {
        return string;
    }];
    [manager POST:WXUNIFIEDORDERURL parameters:string progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSDictionary *dic = [NSDictionary dictionaryWithXMLString:responseString];
        if ([[dic objectForKey:@"result_code"] isEqualToString:@"SUCCESS"] && [[dic objectForKey:@"return_code"] isEqualToString:@"SUCCESS"]) {
            PayReq *request = [[PayReq alloc] init];
            request.openID = [dic objectForKey:WXAPPID];
            request.partnerId = [dic objectForKey:WXMCHID];
            request.prepayId = [dic objectForKey:WXPREPAYID];
            request.package = @"Sign=WXPay";
            request.nonceStr = [dic objectForKey:WXNONCESTR];
            NSDate *datenow = [NSDate date];
            NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];
            UInt32 timeStamp = [timeSp intValue];
            request.timeStamp = timeStamp;
            DataMD5 *md5 = [[DataMD5 alloc] init];
            request.sign = [md5 createMD5SingForPay:request.openID partnerid:request.partnerId prepayid:request.prepayId package:request.package noncestr:request.nonceStr timestamp:request.timeStamp];
            [WXApi sendReq:request];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
    
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];  // 向服务器请求订单信息的参数
//    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
//    parameters[@"token"] = @"app登录帐户的token";
//    parameters[@"order_id"] = @"要下单的商品id";
//    [manager POST:@"向服务器获取订单信息的url" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        NSDictionary *dic = responseObject[@"data"];    // 服务器返回的订单数据
//        // 通过服务器返回的订单数据创建请求参数
//        PayReq *request = [[PayReq alloc] init];
//        request.openID = [dic objectForKey:@"appid"];
//        request.partnerId = [dic objectForKey:@"partenerId"];
//        request.prepayId = [dic objectForKey:@"prepayId"];
//        request.package = [dic objectForKey:@"packageValue"];
//        request.nonceStr = [dic objectForKey:@"nonceStr"];
//        request.timeStamp = (UInt32)[[dic objectForKey:@"timeStamp"] integerValue];
//        request.sign = [dic objectForKey:@"sign"];
//        // 调起微信客户端发起支付
//        [WXApi sendReq:request];
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        
//    }];
}

@end
