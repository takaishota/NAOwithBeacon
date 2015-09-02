//
//  BeaconManager.swift
//  OhayoRegister
//
//  Created by Masato OSHIMA on 2014/10/28.
//  Copyright (c) 2014年 NRI Netcom, Ltd. All rights reserved.
//

import UIKit
import CoreLocation


/**
    ビーコンの受信を管理するクラス
 */
class BeaconManager: NSObject, CLLocationManagerDelegate {
    
    // NSNotificationの名前
    class var BeaconReceiveNotification :String { return "BeaconReceiveNotification" }
    class var BeaconOutsideNotification :String { return "BeaconOutsideNotification" }
    
    /// 0843のiBeaconの固定パラメータ
    private let locationManager = CLLocationManager()
    private let beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "12300100-39FA-4005-860C-09362F6169DA"), identifier: NSBundle.mainBundle().bundleIdentifier)
    
    class var sharedInstance : BeaconManager {
        struct Static {
            static let instance : BeaconManager = BeaconManager()
        }
        return Static.instance
    }
    
    func startMonitoring() {
        self.locationManager.delegate = self
        
        if !CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion) {
            // iBeaconに対応していないデバイスなのでモニタリングを開始せず終了する
            return
        }
        
        if !CLLocationManager.isRangingAvailable() {
            // iBeaconのranging機能が使用できないのでモニタリングを開始せず終了する
            return
        }
        
        // アプリがバックグラウンド状態の場合は位置情報のバックグラウンド更新をする
        let appStatus = UIApplication.sharedApplication().applicationState
        let isBackground = appStatus == UIApplicationState.Background || appStatus == UIApplicationState.Inactive
        if isBackground {
            self.locationManager.startUpdatingLocation()
        }
        
        // beaconの観測開始
        self.locationManager.startMonitoringForRegion(self.beaconRegion)
    }
    
    /**
        iBeaconのレンジングを再開する
     */
    func resumeRanging() {
        self.locationManager.startMonitoringForRegion(self.beaconRegion)
    }

    /*
     *  iBeaconのレンジングをストップする
     */
    func stopRanging() {
        self.locationManager.stopRangingBeaconsInRegion(self.beaconRegion)
    }
    
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didStartMonitoringForRegion region: CLRegion!) {
        // region内にすでにいる場合に備えて、必ずregionについての状態を知らせてくれるように要求する必要がある
        // このリクエストは非同期で行われ、結果は locationManager:didDetermineState:forRegion: で呼ばれる
        manager.requestStateForRegion(region)
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .NotDetermined {
            self.locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println(error)
    }
    
    func locationManager(manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLRegion!) {
        switch state {
        case .Inside:
            if region is CLBeaconRegion && CLLocationManager.isRangingAvailable() {
                manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
            }
            break
        case .Outside:
            NSNotificationCenter.defaultCenter().postNotificationName(BeaconManager.BeaconOutsideNotification, object: nil)
            break
        case .Unknown:
            NSNotificationCenter.defaultCenter().postNotificationName(BeaconManager.BeaconOutsideNotification, object: nil)
            break
        }
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        let validBeacons = (beacons as! [CLBeacon]).filter { beacon in
            if beacon.proximity == .Unknown {
                return false
            }
            return true
        }
        
        // ViewControllerクラスへBeacon情報とともに通知する
        if validBeacons.isEmpty {
            NSNotificationCenter.defaultCenter()
                .postNotificationName(BeaconManager.BeaconOutsideNotification, object: nil)
        } else {
            NSNotificationCenter.defaultCenter()
                .postNotificationName(BeaconManager.BeaconReceiveNotification, object: validBeacons.first)
        }
    }
}
