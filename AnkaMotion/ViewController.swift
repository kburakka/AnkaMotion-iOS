//
//  ViewController.swift
//  AnkaMotion
//
//  Created by burak kaya on 16/01/2020.
//  Copyright © 2020 burak kaya. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation
import Charts
import MBRadioButton

struct DataType {
    let x : Double
    let y : Double
    let z : Double
    
    init(x : Double, y:Double , z:Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

class ViewController: UIViewController , ChartViewDelegate{

    let motion = CMMotionManager()
    var timer : Timer?
    var isChartWorking = true
    let locationManager = CLLocationManager()

    @IBOutlet weak var speedLabel: UILabel!
    var currentLoc : CLLocation?
    var lastLoc : CLLocation?
    var timerForCheckLocUpdate : Timer? = nil
    @IBOutlet weak var accLabel: UILabel!
    @IBOutlet weak var gyroLabel: UILabel!
    @IBOutlet weak var radioButtonContainer: RadioButtonContainerView!
    @IBOutlet weak var gyroButton: RadioButton!
    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet weak var chartStateLabel: UIButton!
    @IBOutlet weak var AccButton: RadioButton!
    @IBOutlet weak var locLabel: UILabel!
    
    var gyroDatas = [DataType]()
    var accDatas = [DataType]()
    let color = UIColor(red: 250/255, green: 255/255, blue: 255/255, alpha: 0.5)
    var selectedButton = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startMeasurement()
        setLoc()
        gyroLabel.numberOfLines = 0
        accLabel.numberOfLines = 0
        locLabel.numberOfLines = 0

        gyroButton.delegate = self
        AccButton.delegate = self
        gyroButton.isOn = true
        selectedButton = "gyro"
        
        let dataAcc = dataWithCount(datas: accDatas)
        let dataGyro = dataWithCount(datas: gyroDatas)

        setupChart(lineChart, data: dataAcc, color: color)
        setupChart(lineChart, data: dataGyro, color: color)
        
        let _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
    }
    
    @objc func fireTimer() {
        if let currentLoc = currentLoc , let lastLoc = lastLoc{
            
            let distance = currentLoc.distance(from: lastLoc)
            let time = currentLoc.timestamp.timeIntervalSince(lastLoc.timestamp)
            
            var speed = (distance / time) * 3.6
            speed = roundTo(digit: 2, value: speed)
            
            speedLabel.text = "\(speed) km/h"
        }else{
            speedLabel.text = "0 km/h"
        }
    }
    
    @objc func fireForCheckLocUpdate(){
        speedLabel.text = "0 km/h"
    }
    
    func setLoc(){
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func dataWithCount(datas : [DataType]) -> LineChartData {
        var Valx = [ChartDataEntry]()
        var Valy = [ChartDataEntry]()
        var Valz = [ChartDataEntry]()

        for index in 0..<datas.count{
            Valx.append(ChartDataEntry(x: Double(index), y: datas[index].x))
            Valy.append(ChartDataEntry(x: Double(index), y: datas[index].y))
            Valz.append(ChartDataEntry(x: Double(index), y: datas[index].z))
        }
        
        let set1 = LineChartDataSet(entries: Valx, label: "X")
        set1.lineWidth = 1.75
        set1.circleRadius = 2
        set1.circleHoleRadius = 1
        set1.setColor(.red)
        set1.setCircleColor(.red)
        set1.highlightColor = .red
        set1.drawValuesEnabled = false

        
        let set2 = LineChartDataSet(entries: Valy, label: "Y")
        set2.lineWidth = 1.75
        set2.circleRadius = 2
        set2.circleHoleRadius = 1
        set2.setColor(.white)
        set2.setCircleColor(.white)
        set2.highlightColor = .white
        set2.drawValuesEnabled = false

        let set3 = LineChartDataSet(entries: Valz, label: "Z")
        set3.lineWidth = 1.75
        set3.circleRadius = 2
        set3.circleHoleRadius = 1
        set3.setColor(.blue)
        set3.setCircleColor(.blue)
        set3.highlightColor = .blue
        set3.drawValuesEnabled = false

        return LineChartData(dataSets: [set1,set2,set3])
    }
    
    @IBAction func chartState(_ sender: Any) {
        isChartWorking = !isChartWorking
        if isChartWorking == true{
            startMeasurement()
            chartStateLabel.setTitle("Durdur", for: .normal)
        }else{
            stopMeasurement()
            chartStateLabel.setTitle("Başlat", for: .normal)
        }
    }
    
    func setupChart(_ chart: LineChartView, data: LineChartData, color: UIColor) {
        (data.getDataSetByIndex(0) as! LineChartDataSet).circleHoleColor = color
        
        chart.delegate = self
        chart.backgroundColor = color
        
        chart.chartDescription?.enabled = true
        
        chart.dragEnabled = true
        chart.setScaleEnabled(true)
        chart.pinchZoomEnabled = false
        chart.setViewPortOffsets(left: 40, top: 0, right: 10, bottom: 0)
        
        chart.legend.enabled = true
        chart.leftAxis.enabled = true
        chart.leftAxis.spaceTop = 0.4
        chart.leftAxis.spaceBottom = 0.4
        chart.rightAxis.enabled = false
        chart.xAxis.enabled = false
        chart.data = data
        
        chart.animate(xAxisDuration: 0.1)
    }
    
    func roundTo(digit: Int, value: Double) -> Double{
        let power = Double(pow(10.0, Double(digit)))
        let y = Double(round(power*value)/power)
        return y
    }

    
   func getAverage(nums: [Double]) ->Double
    {
        var temp = 0.0
        for num in nums
        {
            temp+=num
        }
        let div = Double(nums.count)
        let average = temp/div
        return average
    }
    
    var allGyros = [DataType]()
    var allAccs = [DataType]()

    func getGyros(){
        if motion.isGyroAvailable{
            if let data = self.motion.gyroData {
                var x = roundTo(digit: 5, value: data.rotationRate.x)
                var y = roundTo(digit: 5, value: data.rotationRate.y)
                var z = roundTo(digit: 5, value: data.rotationRate.z)
                                
                if gyroDatas.count>99{
                    gyroDatas.remove(at: 0)
                }
                allGyros.append(DataType(x: x, y: y, z: z))

                if allGyros.count % 10 == 0 {
                    if allGyros.count > 9{
                        x = roundTo(digit: 5, value: getAverage(nums: allGyros.map({$0.x}).suffix(10)))
                        y = roundTo(digit: 5, value: getAverage(nums: allGyros.map({$0.y}).suffix(10)))
                        z = roundTo(digit: 5, value: getAverage(nums: allGyros.map({$0.z}).suffix(10)))
                        gyroDatas.append(DataType(x: x, y: y, z: z))
                    }
                }

                if selectedButton == "gyro" && isChartWorking{
                    lineChart.data = dataWithCount(datas: gyroDatas)
                }
        
                self.gyroLabel.text = "GYRO \n\nX: \(x) \nY: \(y) \nZ: \(z)"
                
                if allGyros.count == 20{
                    allGyros.remove(at: 0)
                }
            }
        }
    }
    
    func getAcc(){
        if motion.isAccelerometerAvailable{
            if let data = self.motion.accelerometerData {
                var x = roundTo(digit: 5, value: data.acceleration.x - getGravity()[0])
                var y = roundTo(digit: 5, value: data.acceleration.y - getGravity()[1])
                var z = roundTo(digit: 5, value: data.acceleration.z - getGravity()[2])
                
                if accDatas.count > 99{
                    accDatas.remove(at: 0)
                }
                allAccs.append(DataType(x: x, y: y, z: z))
                
                if allAccs.count % 10 == 0 {
                    if allAccs.count > 9{
                        x = roundTo(digit: 5, value: getAverage(nums: allAccs.map({$0.x}).suffix(10)))
                        y = roundTo(digit: 5, value: getAverage(nums: allAccs.map({$0.y}).suffix(10)))
                        z = roundTo(digit: 5, value: getAverage(nums: allAccs.map({$0.z}).suffix(10)))
                        accDatas.append(DataType(x: x, y: y, z: z))
                    }
                }
                                
                if selectedButton == "acc" && isChartWorking{
                    lineChart.data = dataWithCount(datas: accDatas)
                }
                self.accLabel.text = "İVME \n\nX: \(x) \nY: \(y) \nZ: \(z)"
                
                if allAccs.count == 20{
                    allAccs.remove(at: 0)
                }
            }
        }
    }
    
    func getGravity() -> [Double]{
        if motion.isDeviceMotionAvailable{
            if let gravity = self.motion.deviceMotion?.gravity{
                return [gravity.x,gravity.y,gravity.z]
            }else{
                return [0.0,0.0,0.0]
            }
        }else{
            return [0.0,0.0,0.0]
        }
    }
    
    func startMeasurement() {
        if motion.isGyroAvailable || motion.isAccelerometerAvailable || motion.isDeviceMotionAvailable{
            if motion.isGyroAvailable{
                self.motion.gyroUpdateInterval = 0.01
                self.motion.startGyroUpdates()
            }
            if motion.isAccelerometerAvailable{
                self.motion.accelerometerUpdateInterval = 0.01
                self.motion.startAccelerometerUpdates()
            }
            if motion.isDeviceMotionAvailable{
                self.motion.deviceMotionUpdateInterval = 0.01
                self.motion.startDeviceMotionUpdates()
            }
            
            self.timer = Timer(fire: Date(), interval: (0.01),
                               repeats: true, block: { (timer) in
                                self.getGyros()
                                self.getAcc()
            })
            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.default)
        }
    }
    
    func stopMeasurement() {
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
            
            self.motion.stopGyroUpdates()
            self.motion.stopDeviceMotionUpdates()
            self.motion.stopAccelerometerUpdates()
        }
    }
}
extension ViewController : RadioButtonDelegate{
    func radioButtonDidDeselect(_ button: RadioButton) {
        
    }
    
    func radioButtonDidSelect(_ button: RadioButton) {
        if button.title(for: .normal) == "Gyro"{
            setupChart(lineChart, data: dataWithCount(datas: gyroDatas), color: color)
            selectedButton = "gyro"
        }else if button.title(for: .normal) == "Acc"{
            setupChart(lineChart, data: dataWithCount(datas: accDatas), color: color)
            selectedButton = "acc"
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last{
            if let timerForCheckLocUpdate = timerForCheckLocUpdate{
                timerForCheckLocUpdate.invalidate()
            }
            timerForCheckLocUpdate = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(fireForCheckLocUpdate), userInfo: nil, repeats: false)
            
            lastLoc = currentLoc
            currentLoc = location
            
            let latitude = roundTo(digit: 5, value: location.coordinate.latitude)
            let longitude = roundTo(digit: 5, value: location.coordinate.longitude)

            locLabel.text = "KONUM \n\nLat: \(latitude) \nLng: \(longitude) \n - \(location.horizontalAccuracy) m -"
        }
    }
}
