//
//  ViewController.swift
//  deblock
//
//  Created by alexma on 26/06/2017.
//  Copyright © 2017 alexma. All rights reserved.
//
//
import UIKit
import CoreMotion
import CoreML

protocol GGViewdelegate: NSObjectProtocol {
    @available(iOS 11.0, *)
    func viewtouchEnd(_ view: GGView)
}

func getTodayString() -> String{
    
    let date = Date()
    let calender = Calendar.current
    let components = calender.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
    
    let year = components.year
    let month = components.month
    let day = components.day
    let hour = components.hour
    let minute = components.minute
    let second = components.second
    
    let today_string = String(year!) + "-" + String(month!) + "-" + String(day!) + "-" + String(hour!)  + ":" + String(minute!) + ":" +  String(second!)
    
    return today_string
    
}

@available(iOS 11.0, *)
func argmax(array: MLMultiArray) -> Int{
    var max : Double = -1
    var arg = 0
    for i in 0..<array.count {
        if Double(array[i]) > max {
            max = Double(array[i])
            arg = i
        }
    }
    return arg
}

struct mobileData {
    var accData:[Double] = []
    var gyroData:[Double] = []
    var magData:[Double] = []
    var motData:[Double] = []
    
    mutating func clear() {
        self.accData = []
        self.gyroData = []
        self.magData = []
        self.motData = []
    }
}

@available(iOS 11.0, *)
class GGView: UIView,UITextFieldDelegate {
    //定义按钮来记录被选中的按钮
    
    
    weak var delegate: GGViewdelegate?
    private var buttons = [UIButton]()
    var numbers:[Int] = [Int]()
    let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    var docurl : URL = URL(string: "/")!
    var motionurl : URL = URL(string: "/")!
    var currentPoint = CGPoint.zero
    var textView : UITextField!
    var predView : UITextField!
    var input_data = (try? MLMultiArray(shape:[24], dataType:MLMultiArrayDataType.double))!
    var h_data = (try? MLMultiArray(shape:[10], dataType:MLMultiArrayDataType.double))!
    var c_data = (try? MLMultiArray(shape:[10], dataType:MLMultiArrayDataType.double))!
    
    let motionManager = CMMotionManager()
    var timer: Timer!
    
    var all_motion_data:[Double] = []
    var save_data:[Double] = []
    var one_line:String = ""
    var show:String = ""
    
    var inbutton = false

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        docurl = path.appendingPathComponent(getTodayString())
        motionurl = path.appendingPathComponent(getTodayString()+"_motion")
        
        do{
            try "".write(to: docurl, atomically: false, encoding: String.Encoding.utf8)
            try "".write(to: motionurl, atomically: false, encoding: String.Encoding.utf8)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
        print(docurl)
        print(motionurl)
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
        //        motionManager.startMagnetometerUpdates()
        motionManager.startDeviceMotionUpdates()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(GGView.update), userInfo: nil, repeats: true)
        
        
            for i in 0..<10 {
                    //创建按钮
                let btn = UIButton()
                addSubview(btn)
                //设置frame
                //设置背景图片
                btn.setBackgroundImage(UIImage(named: "gesture_node_normal"), for: .normal)
                btn.setBackgroundImage(UIImage(named: "gesture_node_highlighted"), for: .selected)
                //设置禁用状态下的图片
                btn.setBackgroundImage(UIImage(named: "gesture_node_error"), for: .disabled)
                btn.isUserInteractionEnabled = false
                btn.tag = i
                btn.setTitle(String((btn.tag + 1) % 10),for: .normal)
                btn.setTitle(String((btn.tag + 1) % 10),for: .selected)
            }
        
        
        textView = UITextField(frame: CGRect(x: 0 , y: 0, width: 0.8 * bounds.size.width, height: 0.08 * bounds.size.height))
        textView.backgroundColor = UIColor.lightGray
        textView.font = UIFont.boldSystemFont(ofSize: 20)
        textView.textAlignment = NSTextAlignment.center
        
        predView = UITextField(frame: CGRect(x: 0 , y: 0.08 * bounds.size.height + 10, width: 0.8 * bounds.size.width, height: 0.08 * bounds.size.height))
        predView.backgroundColor = UIColor.lightGray
        predView.font = UIFont.boldSystemFont(ofSize: 20)
        predView.textAlignment = NSTextAlignment.center
        
        self.backgroundColor = UIColor.clear
        
        addSubview(textView)
        addSubview(predView)
        
        
        for i in 0..<10 {
            h_data[i] = 0
            c_data[i] = 0
        }
        
        
        
        
    
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        

        textView.frame = CGRect(x: 0.1 * bounds.size.width , y: 0, width: 0.8 * bounds.size.width, height: 25)
        predView.frame = CGRect(x: 0.1 * bounds.size.width , y: 30, width: 0.8 * bounds.size.width, height: 25)
        
        let colCount: Int = 3
        let rowCount: Int = 4
        let w: CGFloat = 0.25 * bounds.size.width
        let h: CGFloat = w
        let space: CGFloat = 0.1 * bounds.size.height
            //子view的横向间距  =  (父view的宽度- 3 * 子view的宽度) / 4
        let marginX: CGFloat = (bounds.size.width - CGFloat(colCount) * w) / CGFloat(colCount + 1)
        let marginY: CGFloat = (bounds.size.height - space - CGFloat(rowCount) * h) / CGFloat(rowCount + 1)
        for i in 0 ..< 10 {
            var col: Int = i % colCount
            var row: Int = i / colCount
            if i == 9 {
                col = 1
                row = 3
            }
                //        子view横坐标的公式 =  子view的横向间距  +  列号 * (子view的横向间距+ 子view的宽度)
                //        子view纵坐标的公式 = 50 + 行号 * (子view的纵向间距+ 子view的高度)
            let x: CGFloat = marginX + CGFloat(col) * (marginX + w)
            let y: CGFloat = marginY + CGFloat(row) * (marginY + h) + space
            let btn: UIButton = (subviews[i] as! UIButton)
            btn.frame = CGRect(x: x, y: y, width: w, height: h)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            //获取当前位置
        let touch: UITouch? = touches.first
        let point: CGPoint? = touch?.location(in: touch?.view)
        
        
        
        
        
        //判断当前位置是不是在按钮上
        for sview in subviews[0..<10] {
            let btn = sview as! UIButton
            if btn.frame.contains(point!) {
                inbutton = true
                btn.isSelected = true
                //定义属性来记录被选中的按钮
                buttons.append(btn)
                numbers.append((btn.tag + 1) % 10)
                //记录传感数据
                let one_line_str = self.one_line.data(using: String.Encoding.utf8)!
                
                do{
                    let fileHandle = try FileHandle(forWritingTo: self.motionurl)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(one_line_str)
                    fileHandle.closeFile()
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
                //add to model input
                for i in 0..<12 {
                    //var k : NSNumber = NSNumber(value: self.buttons.count-1)
                    //var l : NSNumber = NSNumber(value: i)
                    self.input_data[i] = NSNumber(value: self.save_data[i])
                }
            }
        }
    }
    
    @objc func update() {
        
        let acceData = motionManager.accelerometerData?.acceleration
        let gyroData = motionManager.gyroData?.rotationRate
//        let magnData = motionManager.magnetometerData?.magneticField
//        let deviceMotion_mag = motionManager.deviceMotion?.magneticField.field
        let deviceMotion_rot = motionManager.deviceMotion?.rotationRate
        let deviceMotion_acc = motionManager.deviceMotion?.userAcceleration
        
        all_motion_data += [acceData!.x,acceData!.y, acceData!.z]
        all_motion_data += [gyroData!.x, gyroData!.y, gyroData!.z]
//        all_motion_data += [magnData!.x, magnData!.y, magnData!.z]
        all_motion_data += [deviceMotion_acc!.x, deviceMotion_acc!.y, deviceMotion_acc!.z]
        all_motion_data += [deviceMotion_rot!.x, deviceMotion_rot!.y, deviceMotion_rot!.z]
//        all_motion_data += [deviceMotion_mag!.x, deviceMotion_mag!.y, deviceMotion_mag!.z]
        
        self.save_data = []
        self.save_data += self.all_motion_data
        self.one_line = all_motion_data.map({String( $0)}).joined(separator: " ")+"\n"
        all_motion_data = []
        
    }
    
    //和开始点击做的事情一样
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            //[self touchesBegan:touches withEvent:event];
            //获取当前点的坐标进行连线
        let touch: UITouch? = touches.first
        let point: CGPoint? = touch?.location(in: touch?.view)
        //记录当前点
        currentPoint = point!
        //[self setNeedsDisplay];
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentPoint = CGPoint.zero
        setNeedsDisplay()
        isUserInteractionEnabled = false
        //清空按钮的状态
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((ino64_t)(Double(NSEC_PER_SEC) / 100000)) / Double(NSEC_PER_SEC), execute: {() -> Void in
            self.isUserInteractionEnabled = true
            for btn: UIButton in self.buttons {
                // 设置不选中
                btn.isSelected = false
                //设置不禁用
                btn.isEnabled = true
            }
            var i = 0
            var s = ""
            var out = ""
            while i < self.buttons.count {
                let btn: UIButton = self.buttons[i]
                s += "\((btn.tag + 1) % 10)  "
                out += "\((btn.tag + 1) % 10)"
                i += 1
            }
            out += "\n"
            
            
            
            
//            //获取当前位置
//            let touch: UITouch? = touches.first
//            let point: CGPoint? = touch?.location(in: touch?.view)
//
//
//            //判断当前位置是不是在按钮上
//            for sview in self.subviews[0..<10] {
//                let btn = sview as! UIButton
//                if btn.frame.contains(point!) {
//
//                }
//
//
//
//            }
            
            if self.inbutton {
                self.textView.text = s
                
                //记录传感数据
                let one_line_str = self.one_line.data(using: String.Encoding.utf8)!
                
                do{
                    let fileHandle = try FileHandle(forWritingTo: self.motionurl)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(one_line_str)
                    fileHandle.closeFile()
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
                
                for i in 12..<23 {
                    //var k : NSNumber = NSNumber(value: self.buttons.count-1)
                    // var l : NSNumber = NSNumber(value: i)
                    self.input_data[i] = NSNumber(value: self.save_data[i-12])
                    
                }
                
                let model = cc()
                
                let Input = ccInput(input1: self.input_data, lstm_3_h_in: self.h_data, lstm_3_c_in: self.c_data)
                let Output = try? model.prediction(input: Input)
                self.h_data = Output!.lstm_3_h_out
                self.c_data = Output!.lstm_3_c_out
                //print(Output!.output1)
                let result = String(describing: argmax(array: Output!.output1))
                self.show += "\(result)  "
                self.predView.text = self.show
                
                if self.buttons.count == 4 {
                    let data = out.data(using: String.Encoding.utf8)!
                    
                    do{
                        let fileHandle = try FileHandle(forWritingTo: self.docurl)
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                    catch let error as NSError {
                        print("Ooops! Something went wrong: \(error)")
                    }
                    
                    // print(self.input_data[[1,]])
                    
                    for i in 0..<10 {
                        self.h_data[i] = 0
                        self.c_data[i] = 0
                    }
                    self.show = ""
                    self.buttons.removeAll()
                    self.numbers.removeAll()
                    self.setNeedsDisplay()
                }
                
            }
            
            self.inbutton = false
            
            
            
            
            
        })
    }

    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
            // Drawing code
        UIColor.white.setStroke()
    }
}

