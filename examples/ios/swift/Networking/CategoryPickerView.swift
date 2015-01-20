//
//  CategoryPickerView.swift
//  RealmExamples
//
//  Created by Samuel Giddins on 1/19/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import RealmSwift
import UIKit

class CategoryPickerView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    let pickerView = UIPickerView()
    let toolbar = UIToolbar()
    var categories = objects(Category)
    var selectionBlock: (Category -> Void) = { _ in }

    override init(frame: CGRect) {
        super.init(frame: frame)

        pickerView.backgroundColor = UIColor.whiteColor()
        pickerView.delegate = self
        pickerView.dataSource = self
        addSubview(pickerView)

        toolbar.translucent = true
        toolbar.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.75)
        let separator = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let doneButtone = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneButtonPressed:")
        toolbar.items = [separator, doneButtone]
        addSubview(toolbar)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        let toolbarHeight: CGFloat = 44
        toolbar.frame = CGRect(x: 0, y: 0, width: CGRectGetWidth(bounds), height: toolbarHeight)
        pickerView.frame = CGRect(x: 0, y: CGRectGetMaxY(toolbar.frame), width: CGRectGetWidth(bounds), height: CGRectGetHeight(bounds) - toolbarHeight)
    }

    func doneButtonPressed(button: UIButton) {
        let selectedRow = pickerView.selectedRowInComponent(0)
        if selectedRow != -1 {
            selectionBlock(categories[selectedRow])
        }
    }

    func reload() {
        pickerView.reloadAllComponents()
    }

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Int(categories.count)
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return categories[row].name
    }
}
