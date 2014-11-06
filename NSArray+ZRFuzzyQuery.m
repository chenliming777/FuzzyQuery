//
//  NSArray+ZRFuzzyQuery.m
//  Greentown
//
//  Created by Chenlm on 7/22/14.
//  Copyright (c) 2014 DL. All rights reserved.
//

#import "NSArray+ZRFuzzyQuery.h"
#import "objc/runtime.h"

static char jianPinyinKey;//简拼例如clm
static char allPinyinKey;//全拼例如chenliming

@implementation NSArray (ZRFuzzyQuery)

/**
 *  初始化搜索数据（包含简拼与全拼）
 *
 *  @param model id类型
 *  @param searchUserName 需要处理的搜索名称
 */
- (void)initSearchData:(id)model searchUserName:(NSString*)searchUserName
{
    //及时释放初始化字符串，节省内存
    @autoreleasepool
    {
        //去除两端的空格
        NSString* userName = [searchUserName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if(userName && userName.length > 0)
        {
            //判断是否为中文的正则表达式
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"[\u4e00-\u9fa5]"];
            NSString* jianPinKey = @"";//简写拼音
            NSString* allPinKey = @"";//全写拼音
            //遍历名称
            for(int idx = 0; idx < userName.length;idx++)
            {
                //首字母
                NSString* name = [userName substringWithRange:NSMakeRange(idx, 1)];
                //此项非中文
                if(![predicate evaluateWithObject:name])
                {
                    jianPinKey = [jianPinKey stringByAppendingString:name];
                    allPinKey = [allPinKey stringByAppendingString:name];
                }
                else//中文（转换拼音）
                {
                    NSMutableString *ms = [[NSMutableString alloc] initWithString:name];
                    if (CFStringTransform((__bridge CFMutableStringRef)ms, 0, kCFStringTransformMandarinLatin, NO))
                    {
                        //第一步转换为带声调的拼音
                        if (CFStringTransform((__bridge CFMutableStringRef)ms, 0, kCFStringTransformStripDiacritics, NO))
                        {
                            //去除声调
                            allPinKey = [allPinKey stringByAppendingString:ms];
                            jianPinKey = [jianPinKey stringByAppendingString:[NSString stringWithFormat:@"%c",[ms characterAtIndex:0]]];
                            
                        }
                    }
                    
                }
            }
            //简拼存在即关联
            objc_setAssociatedObject(model, &jianPinyinKey, jianPinKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            //全拼存在即关联
            objc_setAssociatedObject(model, &allPinyinKey, allPinKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    };
    
}


/**
 *  模糊搜索
 *
 *  @param searchText           搜索内容
 *  @param searchNameSelector   名字属性字段(get方法)
 *  @param selectSelector       标识字段(由于搜索分为2种，1种为标记搜索，即对象中的查询字段为true代表搜索，显示只显示为true的元素，返回结果没用，另一种通过查询结果进行显示，返回结果有用（为set方法）)
 *  @param ...       扩展字段，可随意传入SEL类型，必须为NSString的属性，当需要多个搜索项时即传入（例如基本支持搜索名称，数据处理后会生成简写拼音与全拼，当扩展字段传入例如电话号码或者用户Id等，都可以进行搜索，可传可不传）
 *  模糊查询结果
 *  例如“图书馆” 查询：(1).汉字：图书馆 图书  书馆 图 书 管 即可查到  图管即查询不到 （2).全拼：tushuguan  tushu  shuguan tu shu guan即可查到 tuguan即查询不到 (3).简拼:tsg
 ts sg t s g即可查到 tg即查询不到
 *  @return NSMutableArray（搜索不到即为空数组）
 */
- (NSMutableArray*)getSearchContentList:(NSString*)searchText searchNameSelector:(SEL)searchNameSelector selectSelector:(SEL)selectSelector, ...

{
    NSMutableArray* result = [[NSMutableArray alloc] init];
    if(self.count == 0 || searchText.length == 0)//个数为空或者搜索内容为空 返回空数组
    {
        NSLog(@"列表数据为空或者搜索字段为空");
        return result;
    }
    
    for(int index = 0;index < self.count;index++)
    {
        id model = [self objectAtIndex:index];//数组每一项内容
        NSString* searchUserName = nil;//搜索名字属性字段
        
        if(model && [model isKindOfClass:[NSString class]])//分为2种（1.数组中为字符串）
        {
            searchUserName = [self objectAtIndex:index];//获取名字
        }
        else if(model && [model respondsToSelector:searchNameSelector])//(2.其它类型)
        {
            searchUserName = objc_msgSend(model,searchNameSelector);//获取名字
        }
        
        //获取插入的2个关联的属性
        NSString* jianKeyName = objc_getAssociatedObject(model, &jianPinyinKey);
        NSString* allKeyName = objc_getAssociatedObject(model, &allPinyinKey);
        
        if(!jianKeyName || !allKeyName)
        {
            //model里面没有关联简拼，则进行数据处理
            [self initSearchData:model searchUserName:searchUserName];
            jianKeyName = objc_getAssociatedObject(model, &jianPinyinKey);
            allKeyName = objc_getAssociatedObject(model, &allPinyinKey);
        }
        
        //转为小写（大小写匹配）
        NSString* lowerSearchText = [searchText lowercaseString];
        searchUserName = searchUserName ? [searchUserName lowercaseString] : nil;
        jianKeyName = jianKeyName ? [jianKeyName lowercaseString] : nil;
        allKeyName = allKeyName ? [allKeyName lowercaseString] : nil;
        
        //此为模糊查询，搜索子串
        if((searchUserName && jianKeyName && allKeyName) &&
           ([searchUserName rangeOfString:lowerSearchText].location != NSNotFound
            || [jianKeyName rangeOfString:lowerSearchText].location != NSNotFound
            || [allKeyName rangeOfString:lowerSearchText].location != NSNotFound)
           )
        {
            //设置标识删除项为YES
            if(selectSelector && [model respondsToSelector:selectSelector])
            {
                objc_msgSend(model, selectSelector,YES);
            }
            [result addObject:model];
        }
        else
        {
            BOOL isFind = NO;//是否找到
            va_list args;//可变参数列表
            va_start(args, selectSelector);//查询selectSelector后得参数
            
            SEL selector;
            while((selector = va_arg(args, SEL)))//获取每一项参数
            {
                if(selector && [model respondsToSelector:selector])
                {
                    NSString* other = objc_msgSend(model, selector);
                    if(other && [other rangeOfString:lowerSearchText].location != NSNotFound)
                    {
                        //找到
                        if(selectSelector && [model respondsToSelector:selectSelector])
                        {
                            objc_msgSend(model, selectSelector,YES);
                        }
                        [result addObject:model];
                        isFind = YES;
                        break;
                    }
                }
                else
                {
                    break;
                }
            }
            
            va_end(args);
            
            //没有找到
            if(!isFind)
            {
                if(selectSelector && [model respondsToSelector:selectSelector])
                {
                    objc_msgSend(model, selectSelector,NO);
                }
            }
            
        }
        
    }
    return result;
}

@end
