//
//  InsertExpenseViewController.swift
//  SpendMe
//
//  Created by Max Guzman on 6/16/16.
//  Copyright © 2016 Robot Dream. All rights reserved.
//

import UIKit

class InsertExpenseViewController: UIViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var date: Date!
    
    @IBOutlet weak var expenseTextField: UITextField!
    @IBOutlet weak var whenTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var addExpenseButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBAction func addExpenseButton(_ sender: UIButton) {
        let expense = GTLRSpendme_Expense()
        expense.expense = Int(expenseTextField.text!)! as NSNumber
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        expense.when = dateFormatter.string(from: date!)
        expense.category = categoryTextField.text
        expense.comment = commentTextField.text
        // send the quote to the backend
        if expenseTextField.text != "" {
            self._insertexpense(expense)
            if insertFromTableView {
                dismiss(animated: true, completion: nil)
            } else {
                let alertController = UIAlertController(title: "Registro agregado", message: "Qué deseas hacer ahora?", preferredStyle: .alert)
                let goToListAction = UIAlertAction(title: "Ir al listado", style: UIAlertActionStyle.cancel) { (_) in
                    self.tabBarController?.selectedIndex = 0
                }
                let addAnotherExpenseAction = UIAlertAction(title: "Ingresar otro registro", style: UIAlertActionStyle.default) { (_) in
                    self.date = Date()
                    self.newExpense(self.date)
                }
                alertController.addAction(goToListAction)
                alertController.addAction(addAnotherExpenseAction)
                present(alertController, animated: true, completion: nil)
            }
        }
        insertFromTableView = false
    }
    
    @IBAction func cancelButton(_ sender: UIButton) {
        insertFromTableView = false
        self.view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Textfields delegates
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == whenTextField {
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .date
            textField.inputView = datePicker
            datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
        }
    }
    
    func datePickerChanged(_ sender: UIDatePicker) {
        displayDate(sender.date)
    }
    
    func displayDate(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        whenTextField.text = formatter.string(from: date)
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
        addExpenseButton.tintColor = mainColor
        expenseTextField.delegate = self
        whenTextField.delegate = self
        categoryTextField.delegate = self
        commentTextField.delegate = self
        
        cancelButton.tintColor = mainColor
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        categoryTextField.inputView = pickerView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        date = Date()
        newExpense(date)
        if insertFromTableView {
            cancelButton.isHidden = false
        } else {
            cancelButton.isHidden = true
        }
    }
    
    func newExpense(_ date: Date) {
        self.expenseTextField.becomeFirstResponder()
        displayDate(date)
        expenseTextField.text = ""
        expenseTextField.placeholder = "0"
        // TODO: add category
        categoryTextField.text = ""
        commentTextField.text = ""
        commentTextField.placeholder = "Comentario opcional..."
    }
    
    // MARK: - Supporting functions
    
    func _insertexpense(_ newExpense: GTLRSpendme_Expense) {
        let query = GTLRSpendmeQuery_SpendmeInsert.query(withObject: newExpense)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        service.service.executeQuery(query) { (ticket, response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if error != nil {
                self._showErrorDialog(error! as NSError)
                return
            }
            // Add to the newExpense the entitiKey from the response (for deleting or updating)
            newExpense.entityKey = ((response as! GTLRObject).json!)["entityKey"] as? String
        }
    }
    
    func _showErrorDialog(_ error: NSError) {
        let alertController = UIAlertController(title: "Endpoints error", message: error.localizedDescription, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }

}
