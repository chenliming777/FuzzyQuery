//
//  NSArray+ZRFuzzyQuery.h
//  Greentown
//
//  Created by Chenlm on 7/22/14.
//  Copyright (c) 2014 DL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (ZRFuzzyQuery)


/**
 *  模糊搜索
 *
 *  @param searchText           搜索内容
 *  @param searchNameSelector   名字属性字段(get方法，不传时为nil)
 *  @param selectSelector       标识字段(selectSelector代表查询的标识字段，例如10个元素，查询到3个，会将其字段自动置为true，其它7项均为false，返回结果也包含这3个元素，此时结果可用可不用。可传可不传，set方法，不传时为nil)
 *  @param ...       扩展字段，可随意传入SEL类型，必须为NSString的属性，当需要多个搜索项时即传入（例如基本支持搜索名称，当扩展字段传入例如电话号码或者用户Id等，都可以进行搜索，可传可不传）
 *  @return NSMutableArray（搜索不到即为空数组）
 */
- (NSMutableArray*)getSearchContentList:(NSString*)searchText searchNameSelector:(SEL)searchNameSelector selectSelector:(SEL)selectSelector, ...;

@end
