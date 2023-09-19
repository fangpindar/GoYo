//
//  Date+extension.swift
//  Publisher
//
//  Created by 方品中 on 2023/5/17.
//
import UIKit

extension Date {
    func date2String(dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        formatter.locale = Locale.init(identifier: "zh_Hant_TW")
        formatter.dateFormat = dateFormat
        let date = formatter.string(from: self)
        return date
    }
}
