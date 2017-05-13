//
//  AppDelegate.swift
//  autenticacion
//
//  Created by JESSICA MENDOZA RUIZ on 15/03/2017.
//  Copyright © 2017 JESSICA MENDOZA RUIZ. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseMessaging
import UserNotifications
import CoreLocation
import CoreBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate, CBCentralManagerDelegate {  //, CBCentralManagerDelegate

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    let locationManager = CLLocationManager()
    /*var ref: FIRDatabaseReference!
    let userID = FIRAuth.auth()?.currentUser?.uid*/
    
    var centralManager: CBCentralManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        print("-------------------applicationdidFinishLaunchingWithOptions------------------")
        
        locationManager.delegate = self
        UIApplication.shared.cancelAllLocalNotifications()

        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        if #available(iOS 10.0, *) {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            // For iOS 10 data message (sent via FCM)
            FIRMessaging.messaging().remoteMessageDelegate = self
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()

        // [END register_for_notifications]
        
        // Override point for customization after application launch.
        FIRApp.configure()
        
        // [START add_token_refresh_observer]
        // Add observer for InstanceID token refresh callback.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.tokenRefreshNotification),
                                               name: .firInstanceIDTokenRefresh,
                                               object: nil)

        // [END add_token_refresh_observer]
        
        //Configurar delegado de acceso GoogleSingIn
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions:launchOptions)
        
        
        //Initialise CoreBluetooth Central Manager
        centralManager = CBCentralManager(delegate: self,  queue: DispatchQueue.main)

        return true
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])-> Bool {
        print("-------------------application------------------")
        return self.application(application, open: url, sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: [:])

    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        print("-------------------applicationsourceApplication------------------")
        if GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation) {
            return true
        }
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication,
            annotation: annotation)
    }
    
   /* func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        print("-------------------signIndidSignInForUser------------------")
        if let error = error {
            print(error.localizedDescription)
            return
        }
        // ...
    }*/
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        print("-------------------signIndidSignInForUser------------------")
        guard let controller = GIDSignIn.sharedInstance().uiDelegate as? ViewController else { return }
        
        if let error = error {
            controller.showMessagePrompt(error.localizedDescription)
            return
        }

        guard let authentication = user.authentication else { return }
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)

        controller.firebaseLogin(credential)

    }
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("-------------------applicationdidReceiveRemoteNotification------------------")
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("-------------------applicationdidReceiveRemoteNotificationfetchCompletionHandler------------------")
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    
    // [START refresh_token]
    func tokenRefreshNotification(_ notification: Notification) {
        print("-------------------tokenRefreshNotification------------------")
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("InstanceID token: \(refreshedToken)")
            /*//Guardar el token en la base de datos para luego poder leerlo en la cloud function
            self.ref.child("users/\(userID!)/tokens").setValue(refreshedToken)*/
        }
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    // [END refresh_token]
    
    // [START connect_to_fcm]
    func connectToFcm() {
        print("-------------------connectToFcm------------------")
        // Won't connect since there is no token
        guard FIRInstanceID.instanceID().token() != nil else {
            return;
        }
        
        // Disconnect previous FCM connection if it exists.
        FIRMessaging.messaging().disconnect()
        
        FIRMessaging.messaging().connect { (error) in
            if error != nil {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    // [END connect_to_fcm]
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("-------------------applicationdidFailToRegisterForRemoteNotificationsWithError------------------")
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the InstanceID token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("-------------------applicationdidRegisterForRemoteNotificationsWithDeviceToken------------------")
        print("APNs token retrieved: \(deviceToken)")
        
        // With swizzling disabled you must set the APNs token here.
        // FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
    }
    
    // [START connect_on_active]
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("-------------------applicationDidBecomeActive------------------")
        connectToFcm()
    }
    // [END connect_on_active]
    
    // [START disconnect_from_fcm]
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("-------------------applicationDidEnterBackground------------------")
        FIRMessaging.messaging().disconnect()
        print("Disconnected from FCM.")
    }
    // [END disconnect_from_fcm]
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("-------------------locationManagerdidEnterRegion------------------")
        if (region as? CLBeaconRegion) != nil {
            /*let beacon = region as! CLBeaconRegion
            let major = beacon.major //->Problema: al estar la región definida por el UUID y no por el major/minor, al tratar de conseguir el major se obtiene nil
            print(major)*/
            /*let notification = UILocalNotification()
            notification.alertBody = "Entra en la region de beacon" //\(mistiendas.obtenerTienda(major: major)
            notification.soundName = "Default"
            UIApplication.shared.presentLocalNotificationNow(notification)*/
            
            //-> hace que se inicie el ranging
            locationManager.requestState(for: region)
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("-------------------locationManagerdidExitRegion------------------")
        if (region as? CLBeaconRegion) != nil {
            /*let beacon = region as! CLBeaconRegion
            let major = beacon.proximityUUID
            print(major)*/
            /*let notification = UILocalNotification()
            notification.alertBody = "Sale de la region de beacon"
            notification.soundName = "Default"
            UIApplication.shared.presentLocalNotificationNow(notification)*/
            
            //-> hace que se inicie el ranging
            locationManager.requestState(for: region)
        }
    }
    //El ranging no se hace cuando la app está en segundo plano, por eso hay que hacer monitoring. Para el buen funcionamiento de la app será necesario hacer diferentes regiones teniendo en cuenta major y minor, para que de esta forma se  envien de manera correcta los eventos
    
    //Escanear por nuevos BLE (CoreBluetooth)
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("----------centralManagerDidUpdateState---------")
        if (central.state == .poweredOn){
            print("----------central.state == .poweredOn---------")
            
            //Para que detecte los Eddysrone-uid beacon en el background hay que definir los servicios que queremos que sean escaneados
            //CBUUID IDENTIFICADOR DEL TIPO DE SERVICIO, EN EL CASO DE LOS EDDYSTONE, ESTE TIPO DE SERVICIO ES FEAA
            let arrayOfServices: [CBUUID] = [CBUUID(string: "FEAA")]
            self.centralManager?.scanForPeripherals(withServices: arrayOfServices, options: nil)
        }
        else {
            print("----------central.state == .poweredOff---------")
            // do something like alert the user that ble is not on
        }
    }
    
    //Si encuentra un BLE
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("----------didDiscover peripheral---------")
        print ("Peripheral UID: \(advertisementData)")
        print(advertisementData.debugDescription)
        print ("Peripheral UID: \(peripheral.identifier)")
        print ("Peripheral UID: \(peripheral.services)")
        let notification = UILocalNotification()
        notification.alertBody = "BLE"
        notification.soundName = "Default"
        UIApplication.shared.presentLocalNotificationNow(notification)
        
        //Cuando se encuentre un eddystone-uid se envía un evento a firebase
        FIRAnalytics.logEvent(withName: "BLE", parameters: [
            "data": advertisementData.debugDescription as! NSString,
            "usuario": FIRAuth.auth()?.currentUser?.email as! NSString,
            ])
    }

    
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("-------------------userNotificationCenterwillPresent------------------")
        let userInfo = notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("-------------------userNotificationCenterdidReceive------------------")
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
    

    
}
// [END ios_10_message_handling]

// [START ios_10_data_message_handling]
extension AppDelegate : FIRMessagingDelegate {
    // Receive data message on iOS 10 devices while app is in the foreground.
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        print("-------------------applicationReceivedRemoteMessage------------------")
        print(remoteMessage.appData)
    }
}
// [END ios_10_data_message_handling]

// MARK: - CLLocationManagerDelegate
extension AppDelegate: CLLocationManagerDelegate {
}


