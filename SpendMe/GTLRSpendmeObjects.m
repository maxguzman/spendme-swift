// NOTE: This file was generated by the ServiceGenerator.

// ----------------------------------------------------------------------------
// API:
//   spendme/v1
// Description:
//   SpendMe API

#import "GTLRSpendmeObjects.h"

// ----------------------------------------------------------------------------
//
//   GTLRSpendme_Expense
//

@implementation GTLRSpendme_Expense
@dynamic category, comment, entityKey, expense, lastTouchDateTime, when;

+ (NSDictionary<NSString *, NSString *> *)propertyToJSONKeyMap {
  return @{ @"lastTouchDateTime" : @"last_touch_date_time" };
}

@end


// ----------------------------------------------------------------------------
//
//   GTLRSpendme_ExpenseCollection
//

@implementation GTLRSpendme_ExpenseCollection
@dynamic items, nextPageToken;

+ (NSDictionary<NSString *, Class> *)arrayPropertyToClassMap {
  NSDictionary<NSString *, Class> *map = @{
    @"items" : [GTLRSpendme_Expense class]
  };
  return map;
}

@end
