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
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate, CBCentralManagerDelegate, CLLocationManagerDelegate{//

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    let locationManager = CLLocationManager()
    var centralManager: CBCentralManager?
    var tokenNotifications: String?
    var beacon: String? = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        locationManager.delegate = self
        UIApplication.shared.cancelAllLocalNotifications()
        
        //Crear las configuraciones para las notificaciones que se quieren recibir y registrar la app para que las reciba (hace que se muestre el dialogo de permiso la primera vez que se ejecuta la app)
        if #available(iOS 10.0, *) {
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            //Para mostrar notificaciones (recibidas vía APNS) en iOS 10
            UNUserNotificationCenter.current().delegate = self
            
            //Para mensaje de datos (recibidos vía FCM) en iOS 10
            FIRMessaging.messaging().remoteMessageDelegate = self
            
        } else {
            
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        //Observador para actualización de tokens
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.tokenRefreshNotification),
                                               name: .firInstanceIDTokenRefresh,
                                               object: nil)
        
        //Configurar delegado de acceso GoogleSingIn
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        //Configurar delegado de acceso para Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions:launchOptions)
        
        //Inicializar CoreBluetooth Central Manager
        centralManager = CBCentralManager(delegate: self,  queue: DispatchQueue.main)
        
        //Configurar Firebase
        FIRApp.configure()
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])-> Bool {

        return self.application(application, open: url, sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: [:])

    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {

        if GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation) {
            return true
        }
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication,
            annotation: annotation)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {

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

        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("InstanceID token: \(refreshedToken)")
            self.tokenNotifications = refreshedToken
        }
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    // [END refresh_token]
    
    // [START connect_to_fcm]
    func connectToFcm() {

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
                if let refreshedToken = FIRInstanceID.instanceID().token() {
                    print("InstanceID token: \(refreshedToken)")
                    self.tokenNotifications = refreshedToken
                }
            }
        }
    }
    // [END connect_to_fcm]
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
 
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the InstanceID token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        print("APNs token retrieved: \(deviceToken)")
        
        // With swizzling disabled you must set the APNs token here.
        // FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
    }
    
    // [START connect_on_active]
    func applicationDidBecomeActive(_ application: UIApplication) {
        connectToFcm()
    }
    // [END connect_on_active]
    
    // [START disconnect_from_fcm]
    func applicationDidEnterBackground(_ application: UIApplication) {
        FIRMessaging.messaging().disconnect()
        print("Disconnected from FCM.")
    }
    // [END disconnect_from_fcm]
    
    //Cuando el usuario entre en la región definida por un iBeacon
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        if (region as? CLBeaconRegion) != nil {
            
            //Obtener major y minor de la región en la que entra el usuario
            let beaconRegion = region as! CLBeaconRegion
            let majorRegion = beaconRegion.major!
            let minorRegion = beaconRegion.minor!
            
            print ("Usuario entra en el area del iBeacon con major: \(majorRegion) y minor: \(minorRegion)")
            
            //Instanciar referencias a la base de datos
            let refmajor = FIRDatabase.database().reference()
            var refuser = FIRDatabase.database().reference()
            
            //Obtener UID del usuario
            let uid = FIRAuth.auth()?.currentUser?.uid
            
            //Inicializar variables
            refuser = refuser.child("users").child(uid!).child("tiendas")
            var cont = 0
            var esta = false
            
            refuser.observeSingleEvent(of: .value, with: { snapshot in
                
                for _ in snapshot.children {
                    cont += 1 //Contar las tiendas que hay en la lista
                }
                
                //Leer las tiendas guardadas en la base de datos del usuario
                refuser.observe(FIRDataEventType.childAdded, with: { (snapshot: FIRDataSnapshot) in
                    
                    cont -= 1 //Cada vez que lee el major de una tienda se resta una a las tiendas que quedan por leer
                    let major = (snapshot.value as AnyObject).object(forKey: "major") as! String
                    
                    if (major == String (describing: majorRegion)){ //Si el major de la región coincide con el major de alguna tienda de la lista del usuario
                        print("iBeacon asociado a una tienda de la lista del usuario")
                        esta = true
                        self.beacon = major + String (describing: minorRegion) //Actualizar el valor de la variable beacon con el valor de la suma del major+minor
                        refmajor.child("users/\(uid!)/iBeacon").setValue(self.beacon) //Guardar en la base de datos el major+minor de la región
                    }
                    
                    if ((cont == 0)&&(esta == false)){ //Si el major de la región no coincide con ninguna tienda de la lista del usuario
                        print("iBeacon no asociado a una tienda de la lista del usuario")
                        self.beacon = nil //Actualizar el valor de la variable beacon a nil
                    }
                })
            })
            
            //Activa el ranging (actualización dinámica de areas)
            locationManager.requestState(for: region)
        }
    }
    
    //Cuando el usuario salga de la región definida por un iBeacon
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        if (region as? CLBeaconRegion) != nil {
            
            //Obtener major y minor de la región de la que sale el usuario
            let beaconRegion = region as! CLBeaconRegion
            let majorRegion = beaconRegion.major!
            let minorRegion = beaconRegion.minor!
            
            print ("Usuario sale del area del iBeacon con major: \(majorRegion) y minor: \(minorRegion)")
            
            //Activa el ranging (actualización dinámica de areas)
            locationManager.requestState(for: region)
        }
    }
    
    //Escanear por nuevos BLE (CoreBluetooth) -> En busca de beacons de seguridad
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            //Para que detecte los beacons Eddystone-UID en el background hay que definir los servicios que queremos que sean escaneados
            //CBUUID es el identificador del tipo de servicio en el caso de los beacons Eddystone-UID este tipo de servicio es FEAA
            let arrayOfServices: [CBUUID] = [CBUUID(string: "FEAA")]
            self.centralManager?.scanForPeripherals(withServices: arrayOfServices, options: nil)
        }
    }
    
    //Cuando entre en la región de un beacon de seguridad
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print ("Detectado beacon de seguridad")
        
        //Leer datos enviados por el beacon
        let datos = advertisementData["kCBAdvDataServiceData"] as? NSDictionary
        let ns = String(describing: datos!.allValues)

        //Obtener el HMAC
        let start = ns.index(ns.startIndex, offsetBy: 2)
        let end = ns.index(ns.endIndex, offsetBy: -2)
        let range = start..<end
        let hmac = ns.substring(with: range)
        
        //Obtener UID del usuario
        let uid = FIRAuth.auth()?.currentUser?.uid
        
        //Iniciar referencia a la base de datos
        let refseg = FIRDatabase.database().reference()
        
        if(self.beacon != nil){ //Si el valor de beacon es distinto de nil, es decir, si estamos en el área de un iBeacon asociado a alguna tienda de la lista del usuario
            print ("Se guarda el token del usuario: \(tokenNotifications) y el valor HMAC recibido: \(hmac) en la base de datos")
            
            //Registrar el token
            refseg.child("users/\(uid!)/tokens").setValue(tokenNotifications)
        
            //Registrar el valor HMAC en la base de datos -> Este registro lanza la Cloud Function
            refseg.child("users/\(uid!)/seguridad").setValue(hmac)
        }
        
        /*let notification = UILocalNotification()
        notification.alertBody = "Detectado beacon de seguridad"
        notification.soundName = "Default"
        UIApplication.shared.presentLocalNotificationNow(notification)*/
     
    }
    
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
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
        print(remoteMessage.appData)
    }
}
// [END ios_10_data_message_handling]


