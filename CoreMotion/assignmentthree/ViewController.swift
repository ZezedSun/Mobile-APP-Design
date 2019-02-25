//
//  ViewController.swift
//  assignmentthree
//
//  Created by Rocky Leo on 9/27/18.
//  Copyright © 2018 Rocky Leo. All rights reserved.
//
import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    // MARK: =====Class Variables=====
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    var todayGoalStep = 0
    var realTimeSteps: Int = 0{
        willSet(newrealTimeSteps){
            DispatchQueue.main.async {
                self.realtimestep.text = "Realtime Step: \(newrealTimeSteps)"
            }
        }
    }
    var  todayStep = 0
    var  reachGoalStep = 0
    var  yestodayStep = 0
    var slidervalue = 0
    // MARK: =====UI Outlets=====
    @IBOutlet weak var todaystepnumber: UILabel!
    @IBOutlet weak var yestodaystepnumber: UILabel!
    @IBOutlet weak var motionlabel: UILabel!
    @IBOutlet weak var realtimestep: UILabel!
    
    @IBOutlet weak var todaygoal: UILabel!
    @IBOutlet weak var progress: UILabel!
    
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var playGameButton: UIButton!
    @IBAction func goalChanged(_ sender: UISlider) {
        self.todayGoalStep = Int(sender.value)
        self.todaygoal.text = "Today Goal: \(Int(sender.value))"
        //let stepDefault = UserDefaults.standardstepDefault.set(self.slider.value,forKey:"dailyStepGoal")
        
        //self.todaygoal.text = "Goal: \(UserDefaults.standard.integer(forKey: "dailyStepGoal"))"
        
        //if( self.todayStep >= UserDefaults.standard.integer(forKey: "dailyStepGoal")){
        if(self.todayStep >= self.todayGoalStep){
            self.playGameButton.isEnabled = true
            self.progress.text = "you have achieved today's godal"
        }
        else {
            self.playGameButton.isEnabled = false
            self.reachGoalStep = self.todayGoalStep - self.todayStep
            self.progress.text = "You need to walk: \(self.reachGoalStep)"
        }
        

    }
    
    
    // MARK: =====UI Lifecycle=====
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.realTimeSteps = 0
        self.slider.setValue(UserDefaults.standard.float(forKey: "dailyStepGoal"), animated: true)
        self.todaygoal.text = "Today Goal: \(slidervalue)"
        
        self.startActivityMonitoring()
        self.startPedometerMonitoring()
        self.getPastStep()
        self.getTodayStep()
    }
    
    
    // MARK: =====Motion Methods=====
    func startActivityMonitoring(){
        // is activity is available
        if CMMotionActivityManager.isActivityAvailable(){
            // update from this queue (should we use the MAIN queue here??.... )
            self.activityManager.startActivityUpdates(to: OperationQueue.main)
            {(activity:CMMotionActivity?)->Void in
                // unwrap the activity and dispaly
                if let unwrappedActivity = activity {
                    print("%@",unwrappedActivity.description)
                    if(unwrappedActivity.automotive){
                        
                        self.motionlabel.text = "automotive"
                    }else if(unwrappedActivity.running){
                        self.motionlabel.text = "running"
                    }else if(unwrappedActivity.cycling){
                        self.motionlabel.text = "cycling"
                    }else if(unwrappedActivity.walking){
                        self.motionlabel.text = "walking"
                    }else if(unwrappedActivity.stationary){
                        self.motionlabel.text = "stationary"
                    }else {
                        self.motionlabel.text = "unknown"
                    }
                    
                }
            }
        }
        
    }
    
    func startPedometerMonitoring(){
        //separate out the handler for better readability
        if CMPedometer.isStepCountingAvailable(){
            pedometer.startUpdates(from: Date(),
                                   withHandler: handlePedometer)
        }
    }
    
    //ped handler
    func handlePedometer(_ pedData:CMPedometerData?, error:Error?)->(){
        if let steps = pedData?.numberOfSteps {
            self.realTimeSteps = steps.intValue
        }
    }
    // MARK: ===== Get Past Step Methods =====
    func getPastStep(){
        
        var componentt = Calendar.current.dateComponents([.year,.month,.day], from: Date())
        
        componentt.day = componentt.day!
        componentt.hour = 0
        componentt.minute = 0
        componentt.second = 0
        
        var componenty = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        componenty.day = componenty.day! - 1
        componenty.hour = 0
        componenty.minute = 0
        componenty.second = 0
        let yesterday = Calendar.current.date(from: componenty)!
        let todaystep = Calendar.current.date(from: componentt)!
        
        self.pedometer.queryPedometerData(from: yesterday ,to: todaystep)
        {(pedData: CMPedometerData?, error:Error?) -> Void in
            self.yestodayStep = pedData!.numberOfSteps.intValue
            //let paststep = "Steps: \(pedData?.numberOfSteps)"
            
            DispatchQueue.main.async(){
                self.yestodaystepnumber.text = " Yesterday Step : \(pedData?.numberOfSteps ?? 0)"
            }
        }
    }


        
       // MARK: ===== Get Today Step Methods =====
        
        func getTodayStep(){
            let now = NSDate()
            
            var component = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            component.day = component.day
            component.hour = 0
            component.minute = 0
            component.second = 0
            let today = Calendar.current.date(from: component)!
            
            self.pedometer.queryPedometerData(from: today ,to: now as Date)
            {(pedData: CMPedometerData?, error:Error?) -> Void in
                self.todayStep = pedData!.numberOfSteps.intValue
                
                let aggregated_string = "Today Steps :\(pedData?.numberOfSteps ?? 0)"
                DispatchQueue.main.async(){
                    let todaystepDefault = UserDefaults.standard
                    todaystepDefault.set(aggregated_string,forKey:"todayStep")
                    self.todaystepnumber.text = aggregated_string
            
                }
            }
    }

}

