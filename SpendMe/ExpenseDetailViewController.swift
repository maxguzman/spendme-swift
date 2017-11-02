//
//  ExpenseDetailViewController.swift
//  SpendMe
//
//  Created by Max Guzman on 6/14/16.
//  Copyright © 2016 Robot Dream. All rights reserved.
//

import UIKit

class ExpenseDetailViewController: UIViewController, UITextFieldDelegate, UIPickerViewDataSource,UIPickerViewDelegate {
    
    var expense: GTLRSpendme_Expense!
    var date: Date!
    var newDate: String?
    let deleteExpenseSegueIdentifier = "DeleteExpenseSegue"
    
    // MARK: - Outlets
    
    @IBOutlet weak var expenseTextField: UITextField!
    @IBOutlet weak var whenTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var editExpenseTextField: UIButton!
    
    // MARK: - Actions
    
    @IBAction func editExpenseAction(_ sender: UIButton) {
        self.expense.expense = Int(expenseTextField.text!)! as NSNumber       
        let formater = DateFormatter()
        formater.dateStyle = .long
        date = formater.date(from: newDate!)
        formater.dateFormat = "yyyy-MM-dd"
        newDate = formater.string(from: date)
        self.expense.when = newDate!
        self.expense.category = categoryTextField.text!
        self.expense.comment = commentTextField.text!
        if expenseTextField.text != "" {
            self._updateExpense()
            self.updateView()
        }
    }
    
    @IBAction func deleteExpenseAction(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Eliminar gasto", message: "Estás seguro que quieres borrar este registro?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel) { (_) in }
        let deleteExpenseAction = UIAlertAction(title: "Borrar", style: .destructive) { (_) in
            self._deleteexpense(self.expense.entityKey! as NSString)
            self.performSegue(withIdentifier: self.deleteExpenseSegueIdentifier, sender: self)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(deleteExpenseAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Textfields delegates & datasources
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == whenTextField {
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            date = dateFormatter.date(from: self.expense.when!)
            datePicker.date = date
            textField.inputView = datePicker
            datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
        }
    }
    
    func datePickerChanged(_ sender: UIDatePicker) {
        displayDate(sender.date)
    }
    
    func displayDate(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        newDate = formatter.string(from: date)
        whenTextField.text = newDate
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryTextField.text = pickerData[row]
    }

    
    // MARK: - Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editExpenseTextField.tintColor = mainColor
        expenseTextField.text = String(describing: self.expense.expense!)
        
        // date config
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        date = dateFormatter.date(from: self.expense.when!)
        dateFormatter.dateStyle = .long
        newDate = dateFormatter.string(from: date)
        whenTextField.text = newDate!
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        categoryTextField.inputView = pickerView
        print(pickerData.index(of: self.expense.category!)!)
        
        
        categoryTextField.text = self.expense.category
        commentTextField.text = self.expense.comment
        
        whenTextField.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.expenseTextField.becomeFirstResponder()
        updateView()
    }

    
    func updateView() {
        expenseTextField.text = String(describing: expense.expense!)
        whenTextField.text = newDate!
        categoryTextField.text = expense.category
        commentTextField.text = expense.comment
    }

    // MARK: - Supporting functions
    
    func _deleteexpense(_ entityKeyToDelete: NSString) {
        let query = GTLRSpendmeQuery_SpendmeDelete.query(withEntityKey: entityKeyToDelete as String)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        service.service.executeQuery(query) { (ticket, response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if error != nil {
                self._showErrorDialog(error! as NSError)
                return
            }
        }
    }
    
    func _updateExpense() {
        let query = GTLRSpendmeQuery_SpendmeInsert.query(withObject: expense)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        service.service.executeQuery(query) { (ticket, response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if error != nil {
                self._showErrorDialog(error! as NSError)
                return
            }
        }
    }
    
    func _showErrorDialog(_ error: NSError) {
        let alertController = UIAlertController(title: "Endpoints error", message: error.localizedDescription, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }

}
