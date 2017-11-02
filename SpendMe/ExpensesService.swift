//
//  ExpensesService.swift
//  SpendMe
//
//  Created by Max Guzman on 6/14/16.
//  Copyright © 2016 Robot Dream. All rights reserved.
//

import Foundation

class ExpensesService {
    let isLocalHostTesting = false // for local testing
    let localHostRpcUrl = "http://localhost:8080/_ah/api/"
    var service: GTLRSpendmeService {
        if _service != nil {
            return _service!
        }
        _service = GTLRSpendmeService()
        if isLocalHostTesting {
            _service?.rootURLString = localHostRpcUrl
            _service?.fetcherService.allowLocalhostRequest = true
        }
        _service?.isRetryEnabled = true
        return _service!
    }
    var _service: GTLRSpendmeService?
    var expenses = [GTLRSpendme_Expense]()
}
