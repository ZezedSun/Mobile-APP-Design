//
//  ViewController.swift
//  ExampleRedBearChat
//
//  Created by Eric Larson on 9/26/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

import UIKit
import Charts
//if it shows the error that the Charts module is not install, please ignore it and build anyway.

// MARK: CHANGE 2: No longer should this view be a BLE delegate
class ViewController: UIViewController{
    
    // MARK: ====== VC Properties ======
    // MARK: CHANGE 3: No longer have BLE instantiate itself. Instead: Add support for lazy instantiation (like we did in the table view controller)
    lazy var bleShield:BLE = (UIApplication.shared.delegate as! AppDelegate).bleShield
    //var bleShield = BLE()
    var rssiTimer = Timer()
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    //@IBOutlet weak var buttonConnect: UIButton!
    @IBOutlet weak var labelText: UILabel!
   // @IBOutlet weak var textBox: UITextField!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var digitLabelText: UILabel!
    
    @IBOutlet weak var sliderConnect: UISlider!
    @IBOutlet weak var sliderValue: UILabel!
    @IBOutlet weak var AnalogChartView: LineChartView!
    var dataEntries: [ChartDataEntry] = []
    var chartData:[Int]=[]
    var analogValue = 0
    var digitValue = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // MARK: CHANGE 1.a: change this as you no longer need to instantiate the BLE Object like this
        //   you should not let this ViewController be the BLE delegate
        //bleShield.delegate = self
        self.spinner.startAnimating()
        // MARK: CHANGE 4: Nothing to actually change here, just get familiar with
        //  the code below and what the notificaitons mean.
        // These selector functions should be created from the old BLEDelegate functions
        // One example has already been completed for you on the receiving of data function
        
        // BLE Connect Notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onBLEDidConnectNotification),
                                               name: NSNotification.Name(rawValue: kBleConnectNotification),
                                               object: nil)
        
        // BLE Disconnect Notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onBLEDidDisconnectNotification),
                                               name: NSNotification.Name(rawValue: kBleDisconnectNotification),
                                               object: nil)
        
        // BLE Recieve Data Notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onBLEDidRecieveDataNotification),
                                               name: NSNotification.Name(rawValue: kBleReceivedDataNotification),
                                               object: nil)
        
        
    }
    
    func readRSSITimer(timer:Timer){
        bleShield.readRSSI { (number, error) in
            // when RSSI read is complete, display it
            self.rssiLabel.text = String(format: "%.1f",(number?.floatValue)!)
        }
    }

    // MARK: ====== BLE Delegate Methods ======
    func bleDidUpdateState() {
        
    }
    
    
    // MARK: CHANGE 7: use function from "BLEDidConnect" notification
    // in this function, update a label on the UI to have the name of the active peripheral
    // you might be interested in the following method (from objective C):
    // NSString *deviceName =[notification.userInfo objectForKey:@"deviceName"];
    // NEW  CONNECT FUNCTION
    @objc func onBLEDidConnectNotification(notification:Notification){
        let deviceName = notification.userInfo!["name"] as! String
        self.deviceName.text = deviceName
        self.spinner.stopAnimating()
        rssiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: self.readRSSITimer)
        print("Notification arrived that BLE Connected")
    }
    
    // OLD DELEGATION CONNECT FUNCTION (for your reference in creating new method)
    func bleDidConnectToPeripheral() {
        self.spinner.stopAnimating()
        //self.buttonConnect.setTitle("Disconnect", for: .normal)
        
        // Schedule to read RSSI every 1 sec.
        rssiTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                         repeats: true,
                                         block: self.readRSSITimer)

    }
    
    
    // NEW  DISCONNECT FUNCTION
    @objc func onBLEDidDisconnectNotification(notification:Notification){
        rssiTimer.invalidate()
        print("Notification arrived that BLE Disconnected a Peripheral")
    }
    
    // OLD DELEGATION DISCONNECT FUNCTION (for your reference in creating new method)
//    func bleDidDisconnectFromPeripheral() {
//        // MARK: CHANGE 5.b: remove all accesses of the "connect button"
//        //self.buttonConnect.setTitle("Connect", for: .normal)
//        rssiTimer.invalidate()
//    }
    
    
    
    // NEW FUNCTION EXAMPLE: this was written for you to show how to change to a notification based model
    @objc func onBLEDidRecieveDataNotification(notification:Notification){
        let d = notification.userInfo?["data"] as! Data?
        let s = String(bytes: d!, encoding: String.Encoding.utf8)
        //self.labelText.text = s
        let parts = s?.components(separatedBy: " ")
        self.labelText.text = parts?[1]
        self.digitLabelText.text = parts?[0]
        //self.analogValue = Int(parts![1])!
       // print(self.analogValue)
        
        //self.digitValue = Int(parts[1])!
        
        self.analogValue = Int(atoi(parts![1]))
         print(self.analogValue)
         setChart()
    }
    
    // OLD FUNCTION: parse the received data using BLEDelegate protocol
    func bleDidReceiveData(data: Data?) {
        // this data could be anything, here we know its an encoded string
        let s = String(bytes: data!, encoding: String.Encoding.utf8)
        labelText.text = s
        
    }
    
    // MARK: ====== User initiated Functions ======
    // MARK: CHANGE 1.b: change this as you no longer need to search for perpipherals in this view controller
    /*@IBAction func buttonScanForDevices(_ sender: UIButton) {
        
        // disconnect from any peripherals
        var didDisconnect = false
        for peripheral in bleShield.peripherals {
            if(peripheral.state == .connected){
                if(bleShield.disconnectFromPeripheral(peripheral: peripheral)){
                    didDisconnect = true
                }
            }
        }
        // if we disconnected anything, return from button
        if(didDisconnect){
            return
        }
        
        //start search for peripherals with a timeout of 3 seconds
        // this is an asynchronous call and will return before search is complete
        if(bleShield.startScanning(timeout: 3.0)){
            // after three seconds, try to connect to first peripheral
            Timer.scheduledTimer(withTimeInterval: 3.0,
                                 repeats: false,
                                 block: self.connectTimer)
        }
        
        // give connection feedback to the user
        self.spinner.startAnimating()
    }*/
    
    // MARK: CHANGE 1.c: change this as you no longer need to create the connection in this view controller
    // Called when scan period is over to connect to the first found peripheral
    /*func connectTimer(timer:Timer){
        
        if(bleShield.peripherals.count > 0) {
            // connect to the first found peripheral
            bleShield.connectToPeripheral(peripheral: bleShield.peripherals[0])
        }
        else {
            self.spinner.stopAnimating()
        }
    }
    */
    // MARK: CHANGE: this function only needs a name change, the BLE writing does not change
//    @IBAction func sendDataButton(_ sender: UIButton) {
//
//        let s = textBox.text!
//        let d = s.data(using: String.Encoding.utf8)!
//        bleShield.write(d)
//        // if (self.textField.text.length > 16)
//    }
   
    @IBAction func sendDataSlider(_ sender: UISlider) {
        self.sliderValue.text = String(Int(sender.value))
        let s = sliderValue.text!
        let d = s.data(using: String.Encoding.utf8)!
        bleShield.write(d)
    }
    
    func setChart() {
        DispatchQueue.main.async{
            self.AnalogChartView.setVisibleXRangeMaximum(200)
            self.AnalogChartView.setScaleEnabled(true)
            self.chartData.append(self.analogValue)
            let dataEntry = ChartDataEntry(x:Double(self.chartData.count),y:Double(self.analogValue))
            self.dataEntries.append(dataEntry)
            let lineChartDataSet = LineChartDataSet(values: self.dataEntries, label: "Photonic signal")
            lineChartDataSet.drawCirclesEnabled=false
            lineChartDataSet.fillColor=UIColor.blue
            lineChartDataSet.drawValuesEnabled=false
            let lineChartData = LineChartData(dataSet: lineChartDataSet)

            self.AnalogChartView.data = lineChartData

            self.AnalogChartView.autoScaleMinMaxEnabled=true

            self.AnalogChartView.notifyDataSetChanged()
            self.AnalogChartView.moveViewToX(Double(self.chartData.count)+1)
        }
  }
    
}

