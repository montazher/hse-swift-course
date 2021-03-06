//
//  NewFlightViewController.swift
//  HSEProject
//
//  Created by Sergey Pronin on 3/27/15.
//  Copyright (c) 2015 Sergey Pronin. All rights reserved.
//

import UIKit

class NewFlightViewController: UIViewController {

    @IBOutlet weak var textFieldAirline: UITextField!
    @IBOutlet weak var textFieldNumber: UITextField!
    @IBOutlet weak var pickerAirline: UIPickerView!
    @IBOutlet weak var constraintPickerBottom: NSLayoutConstraint!
    
    var airlines = [Airline]()
    
    var selectedAirline: Airline?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        pickerAirline.delegate = self
        pickerAirline.dataSource = self
        
        textFieldAirline.delegate = self
        textFieldNumber.delegate = self
        
        pickerAirline.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        airlines = Airline.allAirlines()
        //!! перезагрузить picker
        pickerAirline.reloadAllComponents()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //при переходе будем скрывать picker
        pickerAirline.hidden = true
        
        //!! подписываемся на события NewAirlineController, если переходим на него
        //первым там всё равно будет navigation controller
        if let navController = segue.destinationViewController as? UINavigationController {
            if let airlineController = navController.viewControllers.first as? NewAirlineViewController {
                airlineController.delegate = self
            }
        }
    }
    
    ///нажатие на "Создать"
    @IBAction func clickCreate(sender: AnyObject) {
        if selectedAirline == nil {
            return
        }
        
        //!! берем текст и обрезаем с обеих сторон переносы строки и проблемы
        let number = textFieldNumber.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if count(number) == 0 {
            return
        }
        
        let flight = Flight()
        flight.number = number
        flight.airline = selectedAirline!
        
        CoreDataHelper.instance.save()
        
        //!! возвращаемся на экран списка рейсов
        self.navigationController!.popViewControllerAnimated(true)  //!! переход на один экран "вверх" в стеке Navigation Controller
    }
    
    func showPicker() {
        constraintPickerBottom.constant = -pickerAirline.frame.height
        
        pickerAirline.hidden = false
        pickerAirline.layoutIfNeeded()
        
        UIView.animateWithDuration(0.3, animations: {
            self.constraintPickerBottom.constant = 0
            self.pickerAirline.layoutIfNeeded()
        })
    }
    
    func hidePicker() {
        
        UIView.animateWithDuration(0.3, animations: {
                self.constraintPickerBottom.constant =
                    -self.pickerAirline.frame.height
                self.pickerAirline.layoutIfNeeded()
            },
            completion: { finished in
                self.pickerAirline.hidden = true

                //убрать из иерархии
//                self.pickerAirline.removeFromSuperview()
            })
    }
}

extension NewFlightViewController: UIPickerViewDelegate {
    ///выделение заданной строчки в picker-е
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedAirline = airlines[row]
        textFieldAirline.text = selectedAirline!.name
    }
}

extension NewFlightViewController: UIPickerViewDataSource {
    ///количество разделов (вертикальных) в picker
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    ///количество строчек в каждом разделе
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return airlines.count
    }
    
    ///заголовок заданной строчки
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        let airline = airlines[row]
        
        return airline.name
    }
}


extension NewFlightViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        //поле авиалинии нельзя редактировать вручную
        if textField == textFieldAirline {
            //но следует показать picker
            pickerAirline.hidden ? showPicker() : hidePicker()
            
            //!! выберем первую авиалинию, если она есть, т.к. didSelect не сработает
            //TODO: попробуйте убрать это и посмотреть, что будет
            if let airline = airlines.first where selectedAirline == nil {
                selectedAirline = airline
                textFieldAirline.text = airline.name
            }
            return false
        } else {
            return true
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField == textFieldNumber {
            //скрываем при выборе номера
            pickerAirline.hidden = true
        }
    }
}

extension NewFlightViewController: NewAirlineViewControllerDelegate {
    func airlineController(controller: NewAirlineViewController, didCreateAirline airline: Airline) {
        //!! убираем модальный контроллер
        dismissViewControllerAnimated(true, completion: nil)
        //на самом деле с airline нам здесь делать нечего, т.к. она уже сохранена
        //lifecycle нашего контроллера вызовет viewWillAppear
        //и airlines заполнится всеми авиалиниями из базы
    }
    
    func airlineControllerDidCancel(controller: NewAirlineViewController) {
        //!! убираем модальный контроллер
        dismissViewControllerAnimated(true, completion: nil)
    }
}
