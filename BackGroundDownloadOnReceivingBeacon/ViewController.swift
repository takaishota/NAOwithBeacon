//
//  ViewController.swift
//  BackGroundDownloadOnReceivingBeacon
//
//  Created by Shota Takai on 2015/09/02.
//  Copyright (c) 2015年 NRI Netcom. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet private weak var iPhoneImage: UIImageView!
    @IBOutlet private weak var userLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var beaconLabel: UILabel!
    @IBOutlet private weak var debugConsole: UITextView!
    
    private var halo: PulsingHaloLayer!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.halo = createHaloLayer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        addHaloLayer()
    }
    
    override func viewWillAppear(animated: Bool) {
        // BeaconManagerで取得したビーコンの通知を受け取る
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "outsideBeacon:", name: BeaconManager.BeaconOutsideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveBeacon:", name: BeaconManager.BeaconReceiveNotification, object: nil)
        
        // デバッグコンソールの表示を切り替える
        self.debugConsole.hidden = !NSUserDefaults.standardUserDefaults().boolForKey("enabled_debug_preference")
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // 別画面に遷移したらビーコンの通知を受け取るのをやめる
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BeaconManager.BeaconOutsideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BeaconManager.BeaconReceiveNotification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - public
    
    /**
    iPhone画像をタップしたときにrangingを再開する
    */
    @IBAction func didTapIPhoneImage() {
        self.halo.hidden = false
        BeaconManager.sharedInstance.startMonitoring()
    }
    
    /**
    iBeaconを受信したときに呼ばれるメソッド
    */
    func receiveBeacon(notification: NSNotification) {
        let beaconRecived = notification.object as! CLBeacon?
        if let beacon = beaconRecived {
            self.halo.hidden = false
            switch beacon.proximity {
            case .Immediate:
                self.halo.radius = 70
                self.halo.backgroundColor = UIColor(red: 0.854, green: 0, blue: 0, alpha: 1).CGColor
                self.beaconLabel.text = "Immediate"
            case .Near:
                self.halo.radius = 90
                self.halo.backgroundColor = UIColor(red: 0.9, green: 0.383, blue: 0.11, alpha: 1).CGColor
                self.beaconLabel.text = "Near"
                // ローカル通知を送信
                self.sendNotification()
            case .Far:
                self.halo.radius = 120
                self.halo.backgroundColor = UIColor(red: 0, green: 0.478, blue: 1, alpha: 1).CGColor
                self.beaconLabel.text = "Far"
            case .Unknown:
                self.halo.hidden = true
            }
        }
    }
    
    /**
    iBeaconの領域から外れたときに呼ばれるメソッド
    */
    func outsideBeacon(notification: NSNotification) {
        self.debugConsole.text = "ビーコンを検知していません\(nowDateString())"
        self.halo.hidden = true
    }
    
    
    // MARK: - private
    
    /**
        ローカル通知を送信する
    */
    private func sendNotification() {
        var notification:UILocalNotification = UILocalNotification()
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.alertTitle = "test"
        notification.alertBody = "バックグラウンドでのビーコン受信を確認するテストです。\(nowDateString())"
        notification.alertAction = "OPEN";
        UIApplication.sharedApplication().presentLocalNotificationNow(notification);
    }
    波紋上のアニメーションビューレイヤーの初期化
    */
    private func createHaloLayer() -> PulsingHaloLayer {
        let layer = PulsingHaloLayer()
        layer.animationDuration = 1
        layer.radius = 100
        layer.backgroundColor = UIColor(red: 0, green: 0.478, blue: 1, alpha: 1).CGColor
        layer.hidden = true
        return layer
    }
    
    /**
    波紋上のアニメーションビューレイヤーをviewに追加する
    */
    private func addHaloLayer() {
        self.halo.position = CGPointMake(self.view.center.x, self.iPhoneImage.center.y)
        self.view.layer.insertSublayer(halo, below: iPhoneImage.layer)
    }
    
    /**
    リクエストに失敗したとき用にエラーを表示する
    */
    private func showError(error: NSError) {
        let alert = UIAlertController(title: "error", message: error.localizedDescription, preferredStyle: .Alert)
        let action = UIAlertAction(title: "ok", style: .Default, handler: nil)
        alert.addAction(action)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    /**
    現在の日付文字列を取得する
    */
    private func nowDateString() -> String {
        let now = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale.currentLocale()
        dateFormatter.timeStyle = .MediumStyle
        dateFormatter.dateStyle = .MediumStyle
        return dateFormatter.stringFromDate(now)
    }
}

