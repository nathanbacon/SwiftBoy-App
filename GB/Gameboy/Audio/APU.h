//
//  APU.h
//  GB
//
//  Created by Nathan Gelman on 9/10/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef APU_h
#define APU_h

@interface APU: NSObject
- (void) write_register:(uint32_t)time :(uint32_t)addr :(uint32_t)data;
- (int) read_register:(uint32_t)time :(uint32_t)addr;
- (long)end_frame:(uint32_t)time;
- (void)dealloc;
@end





#endif /* APU_h */
