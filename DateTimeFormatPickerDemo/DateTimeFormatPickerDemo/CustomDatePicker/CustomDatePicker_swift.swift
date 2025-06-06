import UIKit

@objc enum VVDateFormat_: Int {
    case ddMMyyyy = 0
    case MMddyyyy
    case yyyyMMdd
    case ddMMyyyyHHmm
    case MMddyyyyHHmm
    case yyyyMMddHHmm
    case ddMMyyyyhhmmA
    case MMddyyyyhhmmA
    case yyyyMMddhhmmA
    
    var calendar_components:Set<Calendar.Component>{
        switch self {
        case .ddMMyyyy,.MMddyyyy,.yyyyMMdd:
            return [.year,.month,.day]
        case .ddMMyyyyHHmm,.ddMMyyyyhhmmA,
                .MMddyyyyHHmm,.MMddyyyyhhmmA,
                .yyyyMMddHHmm,.yyyyMMddhhmmA:
            return [.year,.month,.day,.hour,.minute,]
        }
    }
    var formatString: String {
        switch self {
        case .ddMMyyyy: return "dd/MM/yyyy"
        case .MMddyyyy: return "MM/dd/yyyy"
        case .yyyyMMdd: return "yyyy/MM/dd"
        case .ddMMyyyyHHmm: return "dd/MM/yyyy HH:mm"
        case .MMddyyyyHHmm: return "MM/dd/yyyy HH:mm"
        case .yyyyMMddHHmm: return "yyyy/MM/dd HH:mm"
        case .ddMMyyyyhhmmA: return "dd/MM/yyyy hh:mm a"
        case .MMddyyyyhhmmA: return "MM/dd/yyyy hh:mm a"
        case .yyyyMMddhhmmA: return "yyyy/MM/dd hh:mm a"
        }
    }
    
    var hasTime: Bool {
        return self.rawValue >= VVDateFormat_.ddMMyyyyHHmm.rawValue
    }
    
    var hasAMPM: Bool {
        return self.rawValue >= VVDateFormat_.ddMMyyyyhhmmA.rawValue
    }
}

@objcMembers
class CustomDatePickerView: UIView {
    
    // MARK: - Public Properties (Objective-C accessible)
    private var min_date: Date?
    private var max_date: Date?
    
    @objc var selectedDate: Date {
        didSet {
            updateDateSelection()
            if let min = min_date, selectedDate < min {
                selectedDate = min
            } else if let max = max_date, selectedDate > max {
                selectedDate = max
            }
        }
    }
    
    @objc private(set) var dateFormat: VVDateFormat_ {
        didSet {
            configureComponentOrder()
            reloadAllComponents()
        }
    }
    
    typealias SelectedDateBlock = ((_ dateComponents: DateComponents, _ date: Date, _ date_str:String)-> ())
    private var confirm_action: SelectedDateBlock? = nil
    
    // MARK: - Private Properties
    private let pickerView = UIPickerView()
    private let calendar = Calendar.current
    
    private var years: [Int] = []
    private var months: [Int] = []
    private var days: [Int] = []
    private var hours24: [Int] = []
    private var hours12: [Int] = []
    private var minutes: [Int] = []
    private var ampm: [String] = ["AM", "PM"]
    
    private(set) var componentOrder: [DateComponentType] = []
    enum DateComponentType: Int {
        case day = 0
        case month
        case year
        case hour
        case minute
        case ampm
    }
    
    convenience init(formatType: VVDateFormat_,
                     date: Date,
                     maxDate:Date?,
                     minDate:Date?,
               confirmAction: SelectedDateBlock?) {
        self.init(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        confirm_action = confirmAction
        selectedDate = date
        dateFormat = formatType
        max_date = maxDate
        min_date = minDate
        
        commonInit()
    }
    
    override init(frame: CGRect) {
        selectedDate = Date()
        dateFormat = .ddMMyyyy
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        selectedDate = Date()
        dateFormat = .ddMMyyyy
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        setupPickerView()
        generateData()
        configureComponentOrder()
        updateDateSelection()
    }
    
    private func setupPickerView() {
        pickerView.delegate = self
        pickerView.dataSource = self
        
        addSubview(pickerView)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        pickerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pickerView.frame = bounds
    }
    
    // MARK: - Public Methods (Objective-C accessible)
    @objc func setMinDate(_ minDate: Date?, maxDate: Date?) {
        min_date = minDate
        max_date = maxDate
        validateSelectedDate()
    }
    
    private func reloadAllComponents() {
        generateDays(for: selectedDate)
        pickerView.reloadAllComponents()
        updateDateSelection()
    }
    
    // MARK: - Private Methods
    private func generateData() {
        // Generate years
        let current_year = calendar.component(.year, from: selectedDate)
        var min_year = current_year-100
        var max_year = current_year+100
        if let min = min_date {
            min_year = calendar.component(.year, from: min)
        }
        
        if let max = max_date {
            max_year = calendar.component(.year, from: max)
        }
        
        if min_year < max_year {
            years = Array(min_year...max_year)
        }else if min_year == max_year{
            years = [min_year]
        }
        
        
        // Months 1-12
        months = Array(1...12)
        
        // Hours 0-23 for 24h format
        hours24 = Array(0...23)
        
        // Hours 1-12 for 12h format
        hours12 = Array(1...12)
        
        // Minutes 0-59
        minutes = Array(0...59)
        
        // Generate initial days
        generateDays(for: selectedDate)
    }
    
    private func generateDays(for date: Date) {
        let range = calendar.range(of: .day, in: .month, for: date)!
        let upper = range.upperBound
        
        days = Array(range.lowerBound..<upper)
    }
    
    private func configureComponentOrder() {
        switch dateFormat {
        case .ddMMyyyy:
            componentOrder = [.day, .month, .year]
        case .MMddyyyy:
            componentOrder = [.month, .day, .year]
        case .yyyyMMdd:
            componentOrder = [.year, .month, .day]
        case .ddMMyyyyHHmm:
            componentOrder = [.day, .month, .year, .hour, .minute]
        case .MMddyyyyHHmm:
            componentOrder = [.month, .day, .year, .hour, .minute]
        case .yyyyMMddHHmm:
            componentOrder = [.year, .month, .day, .hour, .minute]
        case .ddMMyyyyhhmmA:
            componentOrder = [.day, .month, .year, .hour, .minute, .ampm]
        case .MMddyyyyhhmmA:
            componentOrder = [.month, .day, .year, .hour, .minute, .ampm]
        case .yyyyMMddhhmmA:
            componentOrder = [.year, .month, .day, .hour, .minute, .ampm]
        }
    }
    
    private func validateSelectedDate() {
        if let min = min_date, selectedDate < min {
            selectedDate = min
        } else if let max = max_date, selectedDate > max {
            selectedDate = max
        }
    }
    
    private func updateDateSelection() {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: selectedDate)
        
        for (componentIndex, componentType) in componentOrder.enumerated() {
            var row = 0
            
            switch componentType {
            case .day:
                if let day = components.day, let index = days.firstIndex(of: day) {
                    row = index
                }
            case .month:
                if let month = components.month, let index = months.firstIndex(of: month) {
                    row = index
                }
            case .year:
                if let year = components.year, let index = years.firstIndex(of: year) {
                    row = index
                }
            case .hour:
                if dateFormat.hasAMPM {
                    // For 12-hour format
                    if let hour = components.hour {
                        var displayHour = hour
                        if displayHour == 0 || displayHour == 12 {
                            displayHour = 12
                        } else if displayHour > 12 {
                            displayHour -= 12
                        }
                        if let index = hours12.firstIndex(of: displayHour) {
                            row = index
                        }
                    }
                } else {
                    // For 24-hour format
                    if let hour = components.hour, let index = hours24.firstIndex(of: hour) {
                        row = index
                    }
                }
            case .minute:
                if let minute = components.minute, let index = minutes.firstIndex(of: minute) {
                    row = index
                }
            case .ampm:
                if let hour = components.hour {
                    row = hour < 12 ? 0 : 1 // 0: AM, 1: PM
                }
            }
            
            pickerView.selectRow(row, inComponent: componentIndex, animated: false)
        }
    }
    
    private func updateSelectedDate(from pickerView: UIPickerView) {
        var components = DateComponents()
        
        for (componentIndex, componentType) in componentOrder.enumerated() {
            let row = pickerView.selectedRow(inComponent: componentIndex)
            
            switch componentType {
            case .day:
                components.day = days[row]
            case .month:
                components.month = months[row]
            case .year:
                components.year = years[row]
            case .hour:
                if dateFormat.hasAMPM {
                    // For 12-hour format
                    var hour = hours12[row]
                    
                    // Get AM/PM selection
                    if let ampmIndex = componentOrder.firstIndex(of: .ampm) {
                        let ampmRow = pickerView.selectedRow(inComponent: ampmIndex)
                        if ampmRow == 1 && hour < 12 { // PM
                            hour += 12
                        } else if ampmRow == 0 && hour == 12 { // Midnight
                            hour = 0
                        }
                    }
                    components.hour = hour
                } else {
                    // For 24-hour format
                    components.hour = hours24[row]
                }
            case .minute:
                components.minute = minutes[row]
            case .ampm:
                // Already handled in hour component
                break
            }
        }
        
        // Create date from components
        if let newDate = calendar.date(from: components) {
            // Check if newDate is within min/max range
            if let minDate = min_date, newDate < minDate {
                selectedDate = minDate
            } else if let maxDate = max_date, newDate > maxDate {
                selectedDate = maxDate
            } else {
                selectedDate = newDate
            }
            
            // Check if day component changed (month/year change might affect days count)
            
            let currentDay = calendar.component(.day, from: selectedDate)
            if let dayComponent = components.day,
               dayComponent != currentDay {
                generateDays(for: selectedDate)
                //                if let dayIndex = componentOrder.firstIndex(of: .day) {
                //                    pickerView.reloadComponent(dayIndex)
                //
                //                }
            }
            pickerView.reloadAllComponents()
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = dateFormat.formatString
            let date_str = dateFormatter.string(from: selectedDate)
            
            confirm_action?(components,selectedDate,date_str)
        }
    }
}

// MARK:
extension CustomDatePickerView: UIPickerViewDataSource,UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return componentOrder.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let componentType = componentOrder[component]
        
        switch componentType {
        case .day: return days.count
        case .month: return months.count
        case .year: return years.count
        case .hour:
            return dateFormat.hasAMPM ? hours12.count : hours24.count
        case .minute: return minutes.count
        case .ampm: return ampm.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let componentType = componentOrder[component]
        
        switch componentType {
        case .day: return String(format: "%02d", days[row])
        case .month: return String(format: "%02d", months[row])
        case .year: return String(years[row])
        case .hour:
            if dateFormat.hasAMPM {
                return String(hours12[row])
            } else {
                return String(format: "%02d", hours24[row])
            }
        case .minute: return String(format: "%02d", minutes[row])
        case .ampm: return ampm[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let componentType = componentOrder[component]
        
        // If month or year changed, regenerate days
        if componentType == .month || componentType == .year {
            updateSelectedDate(from: pickerView)
            generateDays(for: selectedDate)
            
            // Reload day component
            if let dayIndex = componentOrder.firstIndex(of: .day) {
                pickerView.reloadComponent(dayIndex)
            }
        } else {
            updateSelectedDate(from: pickerView)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        let componentType = componentOrder[component]
        
        switch componentType {
        case .year: return 100
        case .month, .day, .hour, .minute: return 50
        case .ampm: return 60
        }
    }
}




/// MARK: BottomSheetVC
@objcMembers
class BottomSheetVC: UIViewController {
    
    typealias ConfirmAction = ((_ dateComponents: DateComponents, _ date:Date, _ date_str:String) ->())
    // 确认按钮回调
    @objc var onConfirm:ConfirmAction? = nil //((_ dateComponents: DateComponents, _ date: Date, _ date_str:String)-> ())?
    
    @objc var toolBarBGColor:UIColor = .brown
    
    @objc var cancel_title:String? = "  取消"{
        didSet{
            let title = "  " + (cancel_title ?? "")
            self.cancelButton.setTitle(title, for: .normal)
        }
    }
    @objc var confirm_title:String? = "确定  "{
        didSet{
            let title = (confirm_title ?? "")+"  "
            self.confirmButton.setTitle(title, for: .normal)
        }
    }
    
    public func showIn(vc: UIViewController){
        self.modalPresentationStyle = .overFullScreen
        vc.present(self, animated: false)
    }
    
    convenience init(formatType: VVDateFormat_,
                     date: Date,
                     maxDate:Date?,
                     minDate:Date?,
         confirmAction: ConfirmAction?){
        
        let mypicker = CustomDatePickerView(formatType: formatType, date: date, maxDate: maxDate, minDate: minDate, confirmAction: nil)
        self.init(contentView: mypicker, confirmAction: confirmAction)
    }
    
    convenience init(contentView:UIView, confirmAction:ConfirmAction?){
        self.init(contentView: contentView, cancelTitle: nil, confirmTitle: nil, confirmAction: confirmAction)
    }
    
    init(contentView:UIView, cancelTitle:String?, confirmTitle:String?, confirmAction:ConfirmAction?){
        infoView = contentView
        onConfirm = confirmAction
        cancel_title = cancelTitle
        confirm_title = confirmTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // 内容视图
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        //        view.layer.cornerRadius = 16
        ////        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        //        view.clipsToBounds = true
        return view
    }()
    
    // 取消按钮
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        
        button.setTitle("  取消", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(dismissSheet), for: .touchUpInside)
        return button
    }()
    
    // 确认按钮
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("确认  ", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        return button
    }()
    
    // 信息视图
    private var infoView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // 半透明背景
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        
        // 添加点击背景手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSheet))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        // 内容视图布局
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 280)
        ])
        
        // 初始位置在屏幕下方
        contentBottomConstraint = contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 280)
        contentBottomConstraint?.isActive = true
        
        // 添加按钮
        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, confirmButton])
        buttonStack.backgroundColor = toolBarBGColor
        buttonStack.axis = .horizontal
        buttonStack.distribution = .equalSpacing
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            buttonStack.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // 添加信息视图
        infoView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoView)
        
        NSLayoutConstraint.activate([
            infoView.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 1),
            infoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            infoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            infoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    // 内容视图底部约束（用于动画）
    private var contentBottomConstraint: NSLayoutConstraint?
    
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        animatePresentation()
    }
    
    // 显示动画
    private func animatePresentation() {
        contentBottomConstraint?.constant = 0
        UIView.animate(withDuration: 0.1) {
            self.view.layoutIfNeeded()
        }
    }
    
    // 消失动画
    private func animateDismissal(completion: (() -> Void)? = nil) {
        contentBottomConstraint?.constant = 280
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
            self.view.backgroundColor = .clear
        }) { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }
    
    // 取消按钮动作
    @objc private func dismissSheet() {
        animateDismissal()
    }
    
    // 确认按钮动作
    @objc private func confirmAction() {
        animateDismissal {
            if let myPicker = self.infoView as? CustomDatePickerView {
                
                let date = myPicker.selectedDate
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = myPicker.dateFormat.formatString
                let date_str = dateFormatter.string(from: date)
                
                let comps = myPicker.dateFormat.calendar_components
                let dateComponents = Calendar.current.dateComponents(comps, from: date)
                self.onConfirm?(dateComponents,date,date_str)
            }
            
        }
    }
}

// 手势代理（防止点击内容视图触发消失）
extension BottomSheetVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
    
}


