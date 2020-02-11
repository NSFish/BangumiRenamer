//
//  NSFBangumiRenamer.h
//  ConanSeriesRenamer
//
//  Created by nsfish on 2020/2/6.
//  Copyright © 2020 nsfish. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFBangumiRenamer : NSObject

+ (void)renameFilesIn:(NSString *)destDirectoryPath
           withSource:(NSString *)sourceFilePath
              pattern:(NSString *)patternFilePath;

@end

NS_ASSUME_NONNULL_END
