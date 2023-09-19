//
//  MemoryViewController.swift
//  GoYo
//
//  Created by 方品中 on 2023/5/25.
//
import UIKit
import FSCalendar
import Firebase

struct Memory {
    var documentId: String
    var color: String
    var title: String
    var time: TimeInterval
    
    // 0: 不重複
    // 1: 每天
    // 2: 每週
    // 3: 每月
    // 4: 每年
    var repeatType: Int
    
    // repeatType = 0, 0
    // repeatType = 1, 0
    // repeatType = 2, 星期
    // repeatType = 3, 日
    // repeatType = 4, 月日
    var repeatValue: String
}

class MemoryViewController: UIViewController {
    var today: Date? {
        didSet {
            // 要重新撈資料顯示給TableView
            self.setMemoriesForTableView()
        }
    }

    var memories = [Memory]()
    var memoriesForCalender = [Memory]()
    var selectedMemory: Memory?
    
    @IBAction func goAdd(_ sender: UIButton) {
        self.selectedMemory = nil
        
        self.performSegue(withIdentifier: "goAdd", sender: self)
    }
    
    @IBSegueAction func presentSegue(_ coder: NSCoder) -> AddMemoryViewController? {
        let controller = AddMemoryViewController(coder: coder)

        controller?.getMemories = self.getMemories
        controller?.setMemoriesForTableView = self.setMemoriesForTableView
        controller?.memory = self.selectedMemory

        if let sheetPresentationController = controller?.sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
        }

        return controller
    }
    
    @IBOutlet weak var fsCalendar: FSCalendar! {
        didSet {
            self.fsCalendar.dataSource = self
            self.fsCalendar.delegate = self
        }
    }
    
    @IBOutlet weak var memoryTableView: UITableView! {
        didSet {
            self.memoryTableView.delegate = self
            self.memoryTableView.dataSource = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.fsCalendar.select(self.fsCalendar.today)
        self.getMemories { [weak self] in
            self?.today = self?.getLocalDate(date: (self?.fsCalendar.today)!)
        }
    }
    
    private func getMemories(completion: @escaping () -> Void) {
        let memories = Firestore.firestore().collection("memories")
        
        memories.whereField("creator", isEqualTo: Auth.auth().currentUser!.uid).getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print(error)
            } else {
                self?.memories = []

                snapshot?.documents.forEach { document in
                    let memory = document.data()

                    if let color = memory["color"] as? String,
                       let title = memory["title"] as? String,
                       let time = memory["time"] as? TimeInterval,
                       let repeatType = memory["repeatType"] as? Int,
                       let repeatValue = memory["repeatValue"] as? String {
                        self?.memories.append(
                            Memory(
                                documentId: document.documentID,
                                color: color,
                                title: title,
                                time: time,
                                repeatType: repeatType,
                                repeatValue: repeatValue
                            )
                        )
                    }
                }

                completion()
                self?.fsCalendar.reloadData()
            }
        }
    }

    private func setMemoriesForTableView() {
        let todayCalendar = Calendar.current.dateComponents([.day, .year, .month, .weekday], from: self.today!)
        let todayInt = todayCalendar.year! * 10000 + todayCalendar.month! * 100 + todayCalendar.day!

        let tomorrowCalendar = Calendar.current.date(byAdding: .day, value: 1, to: self.today!)!
        
        self.memoriesForCalender = []
        
        self.memories.forEach { memory in
            let calendar = Calendar.current.dateComponents([.day, .year, .month, .weekday], from: Date(timeIntervalSince1970: memory.time))
            let memoryInt = calendar.year! * 10000 + calendar.month! * 100 + calendar.day!
            
            // 0: 不重複
            if memory.repeatType == 0 &&
                memory.time > self.today!.timeIntervalSince1970 &&
                memory.time < tomorrowCalendar.timeIntervalSince1970 {
                self.memoriesForCalender.append(memory)
            }
            
            // 1: 每天
            if memory.repeatType == 1 && todayInt >= memoryInt {
                self.memoriesForCalender.append(memory)
            }
            
            // 2: 每週
            if memory.repeatType == 2 &&
                todayCalendar.weekday == calendar.weekday {
                self.memoriesForCalender.append(memory)
            }
            
            // 3: 每月
            if memory.repeatType == 3 &&
                todayCalendar.day == calendar.day {
                self.memoriesForCalender.append(memory)
            }
            
            // 4: 每年
            if memory.repeatType == 4 &&
                todayCalendar.day == calendar.day &&
                todayCalendar.month == calendar.month {
                self.memoriesForCalender.append(memory)
            }
        }
        
        self.memoryTableView.reloadData()
    }
}

extension MemoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.memoriesForCalender.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MemoryTableViewCell", for: indexPath) as? MemoryTableViewCell else { return UITableViewCell() }
        
        let memory = self.memoriesForCalender[indexPath.row]

        cell.timeLabel.text = Date(timeIntervalSince1970: memory.time).date2String(dateFormat: "HH:mm")
        cell.titleLabel.text = memory.title
        cell.colorView.backgroundColor = UIColor(hex: memory.color)
        cell.memory = memory
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? MemoryTableViewCell {
            self.selectedMemory = cell.memory
            self.performSegue(withIdentifier: "goAdd", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) as? MemoryTableViewCell else { return UISwipeActionsConfiguration() }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completionHandler) in

            let ref = Firestore.firestore().collection("memories").document(cell.memory.documentId)

            ref.delete { error in
                if let error = error {
                    print(error)
                } else {
                    self.getMemories { [weak self] in
                        self?.today = self?.getLocalDate(date: (self?.fsCalendar.today)!)
                    }
                    completionHandler(true)
                }
            }
        }

        deleteAction.backgroundColor = .red

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
}

extension MemoryViewController: FSCalendarDataSource, FSCalendarDelegate {
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        self.setMemoriesForTableView()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        self.today = self.getLocalDate(date: date)
    }
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let dateCalendar = Calendar.current.dateComponents([.day, .year, .month, .weekday], from: self.getLocalDate(date: date))
        var numberOfEvent = 0
        
        self.memories.forEach { memory in
            let calendar = Calendar.current.dateComponents([.day, .year, .month, .weekday], from: Date(timeIntervalSince1970: memory.time))

            // 0: 不重複
            if memory.repeatType == 0 &&
                dateCalendar.year == calendar.year &&
                dateCalendar.month == calendar.month &&
                dateCalendar.day == calendar.day {
                numberOfEvent = 1
            }

            // 2: 每週
            if memory.repeatType == 2 &&
                dateCalendar.weekday == calendar.weekday {
                numberOfEvent = 1
            }
            
            // 3: 每月
            if memory.repeatType == 3 &&
                dateCalendar.day == calendar.day {
                numberOfEvent = 1
            }
            
            // 4: 每年
            if memory.repeatType == 4 &&
                dateCalendar.month == calendar.month &&
                dateCalendar.day == calendar.day {
                numberOfEvent = 1
            }
        }
        
        return numberOfEvent
    }
    
    func getLocalDate(date: Date) -> Date {
        let calendar = Calendar.current
        
        let localTimeZone = TimeZone.current
        guard let localDate = calendar.date(byAdding: .second, value: localTimeZone.secondsFromGMT(), to: date) else { return Date() }
        
        return localDate
    }
}
