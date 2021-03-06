/*
 The MIT License
 
 Copyright (c) 2013 Mashape (http://mashape.com)
 
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "HttpClientHelper.h"

@interface HttpClientHelper()
+ (NSString*) encodeURI:(NSString*)value;
+ (NSString*) dictionaryToQuerystring:(NSDictionary*) parameters order:(NSArray*) parametersOrder;
+ (BOOL) hasBinaryParameters:(NSDictionary*) parameters;
@end

@implementation HttpClientHelper

+ (BOOL) hasBinaryParameters:(NSDictionary*) parameters {
    for(id key in parameters) {
        id value = [parameters objectForKey:key];
        if ([value isKindOfClass:[NSURL class]]) {
            return true;
        }
    }
    return false;
}

+ (NSString*) encodeURI:(NSString*)value {
	NSString* result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                           NULL,
                                                                           (CFStringRef)value,
                                                                           NULL,
                                                                           (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                           kCFStringEncodingUTF8));
	return result;
}

+ (NSString*) dictionaryToQuerystring:(NSDictionary*) parameters order:(NSArray*) parametersOrder{
    NSString* result = @"";
    
    BOOL firstParameter = YES;
    
    id<NSFastEnumeration> enumerator = parameters;
    if (parametersOrder != nil) {
        enumerator = parametersOrder;
    }
    
    for(id key in enumerator) {
        id value = [parameters objectForKey:key];
        if (!([value isKindOfClass:[NSURL class]] || value == nil)) { // Don't encode files and null values
            NSString* parameter = [NSString stringWithFormat:@"%@%@%@", [HttpClientHelper encodeURI:key], @"=", [HttpClientHelper encodeURI:value]];
            if (firstParameter) {
                result = [NSString stringWithFormat:@"%@%@", result, parameter];
            } else {
                result = [NSString stringWithFormat:@"%@&%@", result, parameter];
            }
            firstParameter = NO;
        }
    }
    
    return result;
}

+(HttpResponse*) request:(HttpRequest*) request {
    
    NSMutableDictionary* headers = [[request headers] mutableCopy];
    
    [headers setValue:@"unirest-objc/1.0" forKey:@"user-agent"];
    
    // Add cookies to the headers
    [headers setValuesForKeysWithDictionary:[NSHTTPCookie requestHeaderFieldsWithCookies:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:[request url]]]]];
    
    NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[request url]]];
    
    HttpMethod httpMethod = [request httpMethod];

    switch ([request httpMethod]) {
        case GET:
            [requestObj setHTTPMethod:@"GET"];
            break;
        case POST:
            [requestObj setHTTPMethod:@"POST"];
            break;
        case PUT:
            [requestObj setHTTPMethod:@"PUT"];
            break;
        case DELETE:
            [requestObj setHTTPMethod:@"DELETE"];
            break;
        case PATCH:
            [requestObj setHTTPMethod:@"PATCH"];
            break;
    }
    
    NSMutableData* body = [[NSMutableData alloc] init];
    
    // Add body
    if (httpMethod != GET) {
        HttpRequestWithBody* requestWithBody = (HttpRequestWithBody*) request;
        
        if ([requestWithBody body] == nil) {
            // Has parameters
            NSDictionary* parameters = [requestWithBody parameters];
            NSArray* parametersOrder = [requestWithBody parametersOrder];
            
            //bool isBinary = [HttpClientHelper hasBinaryParameters:parameters];
            //if (isBinary) {
                
                [headers setObject:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", BOUNDARY] forKey:@"Content-Type"];
                
                id<NSFastEnumeration> enumerator = parameters;
                if (parametersOrder != nil) {
                    enumerator = parametersOrder;
                }
                
                for(id key in enumerator) {
                    id value = [parameters objectForKey:key];
                    if ([value isKindOfClass:[NSURL class]] && value != nil) { // Don't encode files and null values
                        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", BOUNDARY] dataUsingEncoding:NSASCIIStringEncoding]];
                        NSString* filename = [[value absoluteString] lastPathComponent];
                        
                        NSData* data = [NSData dataWithContentsOfURL:value];
                        
                        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, filename] dataUsingEncoding:NSASCIIStringEncoding]];
                        [body appendData:[[NSString stringWithFormat:@"Content-Length: %lu\r\n", (unsigned long)data.length] dataUsingEncoding:NSASCIIStringEncoding]];
                        [body appendData:[@"Content-Type: image/jpg\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
                        [body appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
                        [body appendData:data];
                    } else {
                        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", BOUNDARY] dataUsingEncoding:NSASCIIStringEncoding]];
                        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", key] dataUsingEncoding:NSASCIIStringEncoding]];
                        [body appendData:[@"Content-Type: text/plain; charset=utf-8\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
                        [body appendData:[[NSString stringWithFormat:@"%@", value] dataUsingEncoding:NSUTF8StringEncoding]];
                    }
                }
                
                // Close
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", BOUNDARY] dataUsingEncoding:NSASCIIStringEncoding]];
            //} else {
            //    NSString* querystring = [HttpClientHelper dictionaryToQuerystring:parameters order:parametersOrder];
            //   body = [NSMutableData dataWithData:[querystring dataUsingEncoding:NSUTF8StringEncoding]];
            //}
        } else {
            // Has a body
            body = [NSMutableData dataWithData:[requestWithBody body]];
        }
        
        [requestObj setHTTPBody:body];
    }
    
    // Add headers
    for (NSString *key in headers) {
        NSString *value = [headers objectForKey:key];
        [requestObj addValue:value forHTTPHeaderField:key];
    }
    
    NSHTTPURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:requestObj returningResponse:&response error:&error];
    
    HttpResponse* res = [[HttpResponse alloc] init];
    [res setCode:[response statusCode]];
    [res setHeaders:[response allHeaderFields]];
    [res setRawBody:data];
    [res setError:error];
    
    return res;
}

@end
