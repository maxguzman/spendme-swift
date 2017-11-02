//
//  ExpensesTableViewController.swift
//  SpendMe
//
//  Created by Max Guzman on 6/14/16.
//  Copyright © 2016 Robot Dream. All rights reserved.
//

import UIKit

// Global vars
let mainColor = UIColor(red:0.21, green:0.63, blue:0.16, alpha:1.00)
let pickerData = ["General","Comida","Salida","Compras","Bencina","Auto","Casa","Mascota","Ropa"]
var service = ExpensesService()
var insertFromTableView = false

class ExpensesTableViewController: UITableViewController {
    
    var expenses = [GTLRSpendme_Expense]()
    var initialQueryComplete = false
    
    // MARK: - Segues Identifiers
    
    let expensesCellIdentifier = "ExpenseCell"
    let noExpenseCellIdentifier = "NoExpenseCell"
    let loadingExpensesCellIdentifier = "LoadingExpensesCell"
    let showDetailSegue = "ShowDetailSegue"
    let addExpenseSegue = "AddExpenseSegue"
    
    // MARK: - Actions
    
    @IBAction func showAddExpense(_ sender: AnyObject) {
        insertFromTableView = true
        performSegue(withIdentifier: addExpenseSegue, sender: sender)
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem
        refreshControl = UIRefreshControl()
        refreshControl!.tintColor = mainColor
        refreshControl?.addTarget(self, action: #selector(_refreshExpenses), for: UIControlEvents.valueChanged)
        // change status bar to white
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _queryForExpenses()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(expenses.count, 1)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if expenses.count == 0 {
            if initialQueryComplete {
                cell = tableView.dequeueReusableCell(withIdentifier: noExpenseCellIdentifier, for: indexPath) as UITableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: loadingExpensesCellIdentifier, for: indexPath) as UITableViewCell
                let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
                cell.accessoryView = spinner
                spinner.color = mainColor
                spinner.startAnimating()
            }
        } else {
            let expenseCell = tableView.dequeueReusableCell(withIdentifier: expensesCellIdentifier, for: indexPath) as! ExpenseTableViewCell
            // configure the cell
            let expense = expenses[indexPath.row]
            expenseCell.expenseLabel?.text = String(describing: expense.expense!)
            expenseCell.whenLabel?.text = String(expense.when!)
            expenseCell.categoryLabel?.text = String(expense.category!)
            expenseCell.commentLabel?.text = String(expense.comment!)
            return expenseCell
        }
        return cell
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if expenses.count == 0 {
            super.setEditing(false, animated: false)
        } else {
            super.setEditing(editing, animated: animated)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return expenses.count > 0
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let expenseToDelete = expenses[indexPath.row]
            _deleteexpense(expenseToDelete.entityKey! as NSString)
            expenses.remove(at: indexPath.row)
            
            if expenses.count == 0 {
                tableView.reloadData()
                setEditing(false, animated: true)
            } else {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64.0
    }
    
    // MARK: - Private help methods
    
    func _refreshExpenses() {
        _queryForExpenses()
    }
    
    func _queryForExpenses(_ pageToken: NSString? = nil) {
        let query = GTLRSpendmeQuery_SpendmeList(pathURITemplate: "list", httpMethod: "GET", pathParameterNames: nil)
        // settings for query
        query.order = "last_touch_date_time"
        query.limit = 50
        query.pageToken = pageToken as String?
        
        // print(pageToken?.capitalizedString)
        if pageToken == nil {
            self.expenses.removeAll()
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        service.service.executeQuery(query) { (ticket, response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.initialQueryComplete = true
            self.refreshControl?.endRefreshing()
            if error != nil {
                self._showErrorDialog(error! as NSError)
            } else {
                if let resp = (response as! GTLRObject).json {
                    let records = resp["items"] as! [[String: AnyObject]]
                    var newexpenses = [GTLRSpendme_Expense]()
                    for record in records {
                        let exp = GTLRSpendme_Expense()
                        if let expense = record["expense"] as? NSNumber {
                            exp.expense = expense
                        }
                        if let when = record["when"] as? String {
                            exp.when = when
                        }
                        if let category = record["category"] as? String {
                            exp.category = category
                        }
                        if let comment = record["comment"] as? String {
                            exp.comment = comment
                        }
                        if let entityKey = record["entityKey"] as? String {
                            exp.entityKey = entityKey
                        }
                        newexpenses.insert(exp, at: 0)
                    }
                    self.expenses += newexpenses
                    
                    if let nextPageToken = ((response as! GTLRObject).additionalProperties())["nextPageToken"] as? NSString {
                        print("using page token to get more quotes. count = \(self.expenses.count)")
                        // recursive call until there is not more tokens
                        self._queryForExpenses(nextPageToken)
                    }
                }
            }
            self.tableView.reloadData()
        }
    }
    
    func _insertexpense(_ newQuote: GTLRSpendme_Expense) {
        let query = GTLRSpendmeQuery_SpendmeInsert.query(withObject: newQuote)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        service.service.executeQuery(query) { (ticket, response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if error != nil {
                self._showErrorDialog(error! as NSError)
                return
            }
            // Add to the newQuote the entitiKey from the response (for deleting or updating)
            newQuote.entityKey = ((response as! GTLRObject).json!)["entityKey"] as? String
        }
    }
    
    func _deleteexpense(_ entityKeyToDelete: NSString) {
        let query = GTLRSpendmeQuery_SpendmeDelete.query(withEntityKey: entityKeyToDelete as String)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        service.service.executeQuery(query) { (ticket, response, error) in
            print(response ?? "No response")
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if error != nil {
                // TODO: corregir backend
                // self._showErrorDialog(error!)
            }
        }
    }
    
    func _showErrorDialog(_ error: NSError) {
        let alertController = UIAlertController(title: "Endpoints error", message: error.localizedDescription, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showDetailSegue {
            if let indexPath = tableView.indexPathForSelectedRow {
                let expense = expenses[indexPath.row]
                (segue.destination as! ExpenseDetailViewController).expense = expense
            }
        }
    }
    
    @IBAction func cancelToExpensesTableViewController(_ segue:UIStoryboardSegue) {
    }
    
}
