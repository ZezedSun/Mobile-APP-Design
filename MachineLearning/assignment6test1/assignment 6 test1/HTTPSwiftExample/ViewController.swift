//
//  ViewController.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson on 3/30/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//

// This exampe is meant to be run with the python example:
//              tornado_example.py 
//              from the course GitHub repository: tornado_bare, branch sklearn_example


// if you do not know your local sharing server name try:
//    ifconfig |grep inet   
// to see what your public facing IP address is, the ip address can be used here
//let SERVER_URL = "http://erics-macbook-pro.local:8000" // change this for your server name!!!
let SERVER_URL = "http://10.8.150.206:8000" // change this for your server name!!!

import UIKit
import CoreMotion

class ViewController: UIViewController, URLSessionDelegate {
    
    // MARK: Class Properties
    var session = URLSession()
    let operationQueue = OperationQueue()
    let motionOperationQueue = OperationQueue()
    let calibrationOperationQueue = OperationQueue()
    
    var ringBuffer = RingBuffer()
    let animation = CATransition()
    let motion = CMMotionManager()
    
    var magValue = 900.0
    var isCalibrating = false
    
    var isWaitingForMotionData = false
    var knnParameter = 1;
    var svmParameter = "linear";
    
    @IBOutlet weak var dsidLabel: UILabel!
    @IBOutlet weak var iphone1: UILabel!
    @IBOutlet weak var iphone3: UILabel!
    @IBOutlet weak var iphone4: UILabel!
    @IBOutlet weak var iphone2: UILabel!
    @IBOutlet weak var largeMotionMagnitude: UIProgressView!
    
    @IBOutlet weak var SVM: UILabel!
    @IBOutlet weak var KNN: UILabel!
    // MARK: Class Properties with Observers
    enum CalibrationStage {
        case notCalibrating
        case iphone6sp
        case iphone7p
        case iphone8
        case iphoneXr
    }
    
    var calibrationStage:CalibrationStage = .notCalibrating {
        didSet{
            switch calibrationStage {
            case .iphone6sp:
                self.isCalibrating = true
                DispatchQueue.main.async{
                    self.setAsCalibrating(self.iphone1)
                    self.setAsNormal(self.iphone2)
                    self.setAsNormal(self.iphone3)
                    self.setAsNormal(self.iphone4)
                }
                break
            case .iphone7p:
                self.isCalibrating = true
                DispatchQueue.main.async{
                    self.setAsNormal(self.iphone4)
                    self.setAsNormal(self.iphone3)
                    self.setAsCalibrating(self.iphone2)
                    self.setAsNormal(self.iphone1)
                }
                break
            case .iphoneXr:
                self.isCalibrating = true
                DispatchQueue.main.async{
                    self.setAsNormal(self.iphone3)
                    self.setAsNormal(self.iphone2)
                    self.setAsNormal(self.iphone1)
                    self.setAsCalibrating(self.iphone4)
                }
                break
                
            case .iphone8:
                self.isCalibrating = true
                DispatchQueue.main.async{
                    self.setAsNormal(self.iphone4)
                    self.setAsCalibrating(self.iphone3)
                    self.setAsNormal(self.iphone2)
                    self.setAsNormal(self.iphone1)
                }
                break
            case .notCalibrating:
                self.isCalibrating = false
                DispatchQueue.main.async{
                    self.setAsNormal(self.iphone4)
                    self.setAsNormal(self.iphone3)
                    self.setAsNormal(self.iphone2)
                    self.setAsNormal(self.iphone1)
                }
                break
            }
        }
    }
    
    var dsid:Int = 0 {
        didSet{
            DispatchQueue.main.async{
                // update label when set
                self.dsidLabel.layer.add(self.animation, forKey: nil)
                self.dsidLabel.text = "Current DSID: \(self.dsid)"
            }
        }
    }
    
    @IBAction func magnitudeChanged(_ sender: UISlider) {
        self.magValue = Double(sender.value)
    }
    
    // MARK: Core Motion Updates
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device
        
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 1.0/200
            self.motion.startMagnetometerUpdates(to: motionOperationQueue, withHandler: self.handleMotion )
        }
    }
    
    func handleMotion(_ motionData:CMMagnetometerData?, error:Error?){
        if let accel = motionData?.magneticField{
            self.ringBuffer.addNewData(xData: accel.x, yData: accel.y, zData: accel.z)
            let mag = fabs(accel.x)+fabs(accel.y)+fabs(accel.z)
            DispatchQueue.main.async{
                //show magnitude via indicator
                self.largeMotionMagnitude.progress = Float(mag)/4000
            }
            
            if mag > self.magValue {
                // buffer up a bit more data and then notify of occurrence
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                    self.calibrationOperationQueue.addOperation {
                        // something large enough happened to warrant
                        self.largeMotionEventOccurred()
                    }
                })
            }
        }
    }
    
    
    //MARK: Calibration procedure
    func largeMotionEventOccurred(){
        if(self.isCalibrating){
            //send a labeled example
            if(self.calibrationStage != .notCalibrating && self.isWaitingForMotionData)
            {
                self.isWaitingForMotionData = false
                
                // send data to the server with label
                sendFeatures(self.ringBuffer.getDataAsVector(),
                             withLabel: self.calibrationStage)
                
                self.nextCalibrationStage()
            }
        }
        else
        {
            if(self.isWaitingForMotionData)
            {
                self.isWaitingForMotionData = false
                //predict a label
                getPrediction(self.ringBuffer.getDataAsVector())
                // dont predict again for a bit
                setDelayedWaitingToTrue(2.0)
                
            }
        }
    }
    
    func nextCalibrationStage(){
        switch self.calibrationStage {
        case .notCalibrating:
            //start with up arrow
            self.calibrationStage = .iphone6sp
            setDelayedWaitingToTrue(3.0)
            break
        case .iphone6sp:
            //go to right arrow
            self.calibrationStage = .iphone8
            setDelayedWaitingToTrue(3.0)
            break
        case .iphone8:
            //go to down arrow
            self.calibrationStage = .iphoneXr
            setDelayedWaitingToTrue(3.0)
            break
        case .iphoneXr:
            //go to left arrow
            self.calibrationStage = .iphone7p
            setDelayedWaitingToTrue(3.0)
            break
            
        case .iphone7p:
            //end calibration
            self.calibrationStage = .notCalibrating
            setDelayedWaitingToTrue(3.0)
            break
        }
    }
    
    func setDelayedWaitingToTrue(_ time:Double){
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: {
            self.isWaitingForMotionData = true
        })
    }
    
    func setAsCalibrating(_ label: UILabel){
        label.layer.add(animation, forKey:nil)
        label.backgroundColor = UIColor.red
    }
    
    func setAsNormal(_ label: UILabel){
        label.layer.add(animation, forKey:nil)
        label.backgroundColor = UIColor.white
    }
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig,
            delegate: self,
            delegateQueue:self.operationQueue)
        
        // create reusable animation
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionFade
        animation.duration = 0.5
        
        
        // setup core motion handlers
        startMotionUpdates()
        
        dsid = 2 // set this and it will update UI
    }

    //MARK: Get New Dataset ID
    @IBAction func getDataSetId(_ sender: AnyObject) {
        // create a GET request for a new DSID from server
        let baseURL = "\(SERVER_URL)/GetNewDatasetId"
        
        let getUrl = URL(string: baseURL)
        let request: URLRequest = URLRequest(url: getUrl!)
        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    print("Response:\n%@",response!)
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
                    // This better be an integer
                    if let dsid = jsonDictionary["dsid"]{
                        self.dsid = dsid as! Int
                    }
                }
                
        })
        
        dataTask.resume() // start the task
        
    }
    
    //MARK: Calibration
    @IBAction func startCalibration(_ sender: AnyObject) {
        self.isWaitingForMotionData = false // dont do anything yet
        nextCalibrationStage()
        
    }
    
    //MARK: Comm with Server
    func sendFeatures(_ array:[Double], withLabel label:CalibrationStage){
        let baseURL = "\(SERVER_URL)/AddDataPoint"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":array,
                                       "label":"\(label)",
                                       "dsid":self.dsid]
        
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
                    print(jsonDictionary["feature"]!)
                    print(jsonDictionary["label"]!)
                }

        })
        
        postTask.resume() // start the task
    }
    
    func getPrediction(_ array:[Double]){
        let baseURL = "\(SERVER_URL)/PredictOne"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":array, "dsid":self.dsid]
        
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,completionHandler:{(data, response, error) in
        if(error != nil){
            if let res = response{
                print("Response:\n",res)
                
            }
            
        }
        else{
            let jsonDictionary = self.convertDataToDictionary(with: data)
            print(jsonDictionary)
            let labelResponse_KNN = jsonDictionary["prediction_KNN"]!
            print(labelResponse_KNN)
            self.displayLabelResponse(labelResponse_KNN as! String)
            let labelResponse_SVC = jsonDictionary["prediction_SVC"]!
            print(labelResponse_SVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                self.KNN.text = labelResponse_KNN as? String
                self.SVM.text = labelResponse_SVC as? String
                
            })
            }
        })
        
        postTask.resume() // start the task
    }
    
    func displayLabelResponse(_ response:String){
        switch response {
        case "['iphone6sp']":
            blinkLabel(iphone1)
            break
        case "['iphoneXr']":
            blinkLabel(iphone4)
            break
        case "['iphone7p']":
            blinkLabel(iphone2)
            break
        case "['iphone8']":
            blinkLabel(iphone3)
            break
        default:
            print("Unknown")
            break
        }
    }
    
    func blinkLabel(_ label:UILabel){
        DispatchQueue.main.async {
            self.setAsCalibrating(label)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.setAsNormal(label)
            })
        }
        
    }
    
    @IBAction func makeModel(_ sender: AnyObject) {
        
        // create a GET request for server to update the ML model with current data
        let baseURL = "\(SERVER_URL)/UpdateModel"
        let query = "?dsid=\(self.dsid)"
        
        let postUrl = URL(string: baseURL+query)
        var request = URLRequest(url: postUrl!)
        
        let jsonUpload:NSDictionary = [ "dsid":self.dsid,
                                        "model_id":1,
                                        "knn_pa":self.knnParameter,
                                        "svm_pa":self.svmParameter,]
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,completionHandler:{(data, response, error) in
                                                                    // handle error!
            if (error != nil) {
                if let res = response{
                    print("Response:\n",res)
                    
                }
                
            }
            else{
                let jsonDictionary = self.convertDataToDictionary(with: data)
                print(jsonDictionary)
                if let resubAcc_KNN = jsonDictionary["resubAccuracy_KNN"]{
                    print("Resubstitution_KNN Accuracy is", resubAcc_KNN)
                }
                if let resubAcc_SVC = jsonDictionary["resubAccuracy_SVC"]{
                    print("Resubstitution_SVC Accuracy is", resubAcc_SVC)
                }
               
                
               
                }
                    

            
                                                                    
        })
        
        postTask.resume() // start the task
        
    }
    
    //MARK: JSON Conversion Functions
    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
        do { // try to make JSON and deal with errors using do/catch block
            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
            return requestBody
        } catch {
            print("json error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func convertDataToDictionary(with data:Data?)->NSDictionary{
        do { // try to parse JSON and deal with errors using do/catch block
            let jsonDictionary: NSDictionary =
                try JSONSerialization.jsonObject(with: data!,
                                              options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            return jsonDictionary
            
        } catch {
            print("json error: \(error.localizedDescription)")
            return NSDictionary() // just return empty
        }
    }

}





