//
//  VistaSesionIniciada.swift
//  autenticacion
//
//  Created by JESSICA MENDOZA RUIZ on 16/03/2017.
//  Copyright © 2017 JESSICA MENDOZA RUIZ. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import FirebaseMessaging
import AdSupport
//import CoreBluetooth


class VistaSesionIniciada: UIViewController, CLLocationManagerDelegate{  //, CBCentralManagerDelegate

    @IBOutlet weak var distancia: UILabel!
    var locationManager: CLLocationManager!
    
    //Los estados de majorAnterior=0 y minorAnterior=0 significa que no estoy conectada a ningún beacon. Con lo cual ningún beacon de ninguna tienda puede tener estos valores a 0.
    //var majorAnterior: NSNumber = 0  //Una posible solución para el caso de sobre escritura de major y minor en el locationManager(:didRangeBeacons) con el uso de varias regiones, sería tener un array de major y minor, cada uno asociado a una región.
    //var minorAnterior: NSNumber = 0
    
    //b es una matriz en la que se asocia cada region con el valor del majorAnterior y minorAnterior (inicialmente 0)
    var anterior: [[String]] = [["2000", "0", "0" ],
                               ["1000", "0", "0"],
                               ["1001", "0", "0"],
                               ["1002", "0", "0"],
                               ["1003", "0", "0"]]
    
    //var beaconAnterior: NSNumber = 0  //-> no sirve pa na
    
    var sitio: [String] = ["el escaparate", "la puerta", "la caja", "los probadores"]
    
    var nombreUsuario: String?
    var emailUsuario: String?
    var fotoURL: URL?
    var uid: String?
    var tiendas: [Int] = []
    var estadoAnterior: Bool = false //tb se sobreescribe en locationManager(:didRangeBeacons) con el uso de varias regiones, creo que su uso no es 100x100 necesario, se podría sustituir por lo de la suma de major y mino != 0 -> comprobar bien, en caso de que no se pueda eliminar, una posible solución es hacer un array como con los major y minor.
    
    let uuid = UUID(uuidString:   "00000000-0000-0000-0000-000000000001")!
    
    var ref: FIRDatabaseReference!
    var ref2: FIRDatabaseReference!
    
    var newRegions = Set<CLRegion>()
    var monitoredRegions = Set<CLRegion>()
    var rangedRegions = Set<CLRegion>()
    var initialRegion = Set<CLRegion>()   //Solo va a contener una region, la correspondiente al centro comercial
    
    var mistiendas = ColeccionDeTiendas()
    
    //var centralManager: CBCentralManager?
    
    
    override func viewDidLoad() {
        print("-------------------viewDidLoad2------------------")
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        if let user = FIRAuth.auth()?.currentUser {
            nombreUsuario = user.displayName
            emailUsuario = user.email
            fotoURL = user.photoURL
            uid = user.uid;  // The user's ID, unique to the Firebase project.
            // Do NOT use this value to authenticate with
            // your backend server, if you have one. Use
            // getTokenWithCompletion:completion: instead.
        }
        self.ref = FIRDatabase.database().reference()
        self.ref2 = FIRDatabase.database().reference()
        self.ref = self.ref.child("users").child(uid!).child("tiendas")

        //Eliminar el botón de "back"
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        // Image needs to be added to project.
        let buttonConfigIcon = UIImage(named: "configuracion")
        let buttonCerrarSIcon = UIImage(named: "salir")

        //Añadir barbutton
        let configButton: UIBarButtonItem = UIBarButtonItem(title: "Config", style: UIBarButtonItemStyle.plain, target: self, action: #selector(VistaSesionIniciada.pulsaConfiguracion))
        
        let cerrarSButton: UIBarButtonItem = UIBarButtonItem(title: "Salir", style: UIBarButtonItemStyle.plain, target: self, action: #selector(VistaSesionIniciada.pulsaCerrarSesion))
        
        configButton.image = buttonConfigIcon
        cerrarSButton.image = buttonCerrarSIcon
        
        self.navigationItem.setRightBarButton(configButton, animated: true)
        self.navigationItem.setLeftBarButton(cerrarSButton, animated: true)

        //Initialise CoreBluetooth Central Manager
        //centralManager = CBCentralManager(delegate: self,  queue: DispatchQueue.main)
        
    }

    override func didReceiveMemoryWarning() {
        print("-------------------didReceiveMemoryWarning2------------------")
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pulsaConfiguracion(sender:UIButton) {
        print("-------------------pulsaConfiguracion------------------")
        self.performSegue(withIdentifier: "show2", sender: self)
    }

    func pulsaCerrarSesion(sender:UIButton) {
        print("-------------------pulsaCerrarSesion------------------")
        try! FIRAuth.auth()!.signOut()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondVC =   storyboard.instantiateViewController(withIdentifier: "Vista1") as! ViewController
        self.navigationController!.pushViewController(secondVC, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("-------------------locationManagerdidChangeAuthorization------------------")
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    
                    //Leer las tiendas guardadas en la base de datos del usuario <- necesario para saber que tiendas tiene activas el usuario
                    self.ref.observe(FIRDataEventType.childAdded, with: { (snapshot: FIRDataSnapshot) in
                        let major = (snapshot.value as AnyObject).object(forKey: "major") as! String
                        print (major)
                     
                        //Actualizar tiendas activas
                        self.tiendas.append(Int(major)!)
                        
                        //Empezar escaner
                        self.startScanning()
                     })
                    
                }
            }
        }
    }
    
    func startScanning() {
        print("-------------------startScanning------------------")
        //let uuid = UUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")!
        
        //Definimos la region (se pueden monitorear hasta 20 regiones al mismo tiempo)
        //Region -> el centro comercial
        //let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "MyBeacon")
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: 200, minor: 0, identifier: "MyBeacon2000")
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
        locationManager.startUpdatingLocation() //nuevo
        
        initialRegion.insert(beaconRegion)
        
    }
    
    
    
    func update(distance: CLProximity, major: NSNumber, minor: NSNumber) {
        //print("-------------------update------------------")
        UIView.animate(withDuration: 0.8) { [unowned self] in
            switch distance {
            case .unknown:
                self.distancia.text = "UNKNOWN"
                //print("UNKNOWN")
                
            case .far:
                self.distancia.text = "FAR"
                //print("FAR")
                
            case .near:
                self.distancia.text = "NEAR"
                //print("NEAR")
                
            case .immediate:
                self.distancia.text = "RIGHT HERE  \(major) \(minor)"
                //print("RIGHT HERE  \(major) \(minor)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {//Se realiza por cada region activada periodicamente -> cambiar el uso de variables globales en esta función ya que conllevan a error (majorAnterior, minorAnterior....)
        print("-------------------locationManagerdidRangeBeacons------------------")
        //Para que aparezca en los eventos el UserID
        FIRAnalytics.setUserID(emailUsuario)
        
        var majorAnterior: Int = 0
        var minorAnterior: Int = 0
        
        //Regiones monitorizadas
        monitoredRegions = locationManager.monitoredRegions //The location manager persists region data between launches of your app.
        rangedRegions = locationManager.rangedRegions
        
        print("----------monitoredRegions")
        //Mostrar por pantalla las regiones incluidas en monitoredRegions
        for reg in self.monitoredRegions{
            print(reg)
        }
        print("-----------------------")
        
        print("----------rangedRegions")
        //Mostrar por pantalla las regiones incluidas en monitoredRegions
        for reg in self.rangedRegions{
            print(reg)
        }
        print("-----------------------")
        
        
        
        //Intentar monitorizar las nuevas regiones de los vecinos y parar de monitorizar regiones que ya no interesan -> las regiones de los vecinos en el database
        //Tomo major y minor de la región, los convierto a String y los "sumo"
        let mj = String(describing: region.major!)
        //print ("------------>\(mj)<-----------")
        let mn = String(describing: region.minor!)
        //print ("------------>\(mn)<-----------")
        let suma = mj+mn
        print ("------------>\(suma)<-----------")
        
        
        //Obtener valores de major y minor anteriores
        for i in 0...4 {
            if(anterior[i][0] == suma){
                majorAnterior = Int (anterior[i][1])!
                minorAnterior = Int (anterior[i][2])!
            }
        }
        
        
        if beacons.count > 0 { //si hay algún beacon cerca
            let beacon = beacons[0]
            update(distance: beacon.proximity, major: beacon.major, minor: beacon.minor)

            //beaconAnterior = beacon.major
            
            
            //Leer de la base de datos los beacos a monitorizar
            self.ref2.child("beacons").child(suma).observeSingleEvent(of: .value, with: { (snapshot) in
                let arraybeacons: [AnyObject] = snapshot.value as! [AnyObject] //Obtengo un array con los majorminor de los beacons -> beacons de las regiones que tengo que activar
                print(arraybeacons)
                
                //Crear regiones a partir de los beacons y guardarlas en un set
                for i in 0..<arraybeacons.count{
                    //print("array: \(i)")
                    let n = arraybeacons[i] as! NSNumber
                    let sum = String(describing: n)
                    let index: String.Index = sum.index(sum.startIndex, offsetBy: 3)  //Los tres primeros caracteres indican el major y el resto el minor
                    let maj: String = sum.substring(to: index)
                    //print(maj)
                    let min: String = sum.substring(from: index)
                    //print(min)
                    
                    //Crear nueva region e insertar en newRegions
                    self.newRegions.insert(CLBeaconRegion(proximityUUID: self.uuid, major: CLBeaconMajorValue(maj)!, minor: CLBeaconMinorValue(min)!, identifier: "MyBeacon\(n)"))  //Necesario cambiar el identificador, sino toma todas las regiones como si fuese la misma y solo incluye 1 en el set
                }
                
                //Mostrar por pantalla las regiones incluidas en newRegions
                print("----------newRegions")
                for reg in self.newRegions{
                    print(reg)
                }
                print("-----------------------")
                
                //Parar monitoring y ranging de regiones que ya no me interesan
                let parar: Set<CLRegion>  = self.monitoredRegions.subtracting(self.newRegions) //Devuelve los elemtos que no están en newRegions -> regiones a parar de monitoring
                
                //Mostrar por pantalla las regiones incluidas en parar
                print("----------parar")
                for reg in parar{
                    print(reg)
                }
                print("-----------------------")
                
                for reg in parar{
                    self.locationManager.stopMonitoring(for: reg)
                    self.locationManager.stopRangingBeacons(in: reg as! CLBeaconRegion)
                }
                
                //Activar monitoring y ranging de las nuevas regiones
                let activar: Set<CLRegion>  = self.newRegions.subtracting(self.monitoredRegions) //Devuelve los elemtos que no están en monitoredRegions -> nuevas regiones a monitorizar
                
                //Mostrar por pantalla las regiones incluidas en activar
                print("----------activar")
                for reg in activar{
                    print(reg)
                }
                print("-----------------------")
                
                for reg in activar{
                    self.locationManager.startMonitoring(for: reg)
                    self.locationManager.startRangingBeacons(in: reg as! CLBeaconRegion)
                }
                
                //Vaciar el newRegions
                self.newRegions.removeAll()
                
            })
            
            //si el beacon es mismo que el anterior no enviar evento
            if((beacon.major == majorAnterior as NSNumber)&&(beacon.minor == minorAnterior as NSNumber)){
                print("Sigo conectado al mismo beacon por lo que no envío evento")
            }else{
                print("Estoy conectado a otro beacon") //-> Realmente pasa de no estar conectado al beacon asociado a la región a si estarlo (en las regiones solo hay un beacon)  -> Solo entrará en este else cuando se producza el cambio de "no conectado" a "conectado", una vez conectado al beacon no volverá a entrar (a no ser que nos deconectemos y nos volvamos a conectar)
                
                //hacer comprobación de si el major del beacon que estoy detectando pertenece a alguna de las tiendas seleccionadas en la configuración del usuario, si pertenece hago lo demás, sino no
                var pertenece: Bool = false
                for i in 0 ..< self.tiendas.count{
                    if ((beacon.major as Int) == self.tiendas[i]){
                        pertenece = true
                    }
                }
                
                if (pertenece){ //Si el beacon pertenece a la lista de tiendas envío evento siempre
                    //estadoAnterior = true
                    
                    //Envio notificación al usuario indicandole en qué tienda está
                    let notification = UILocalNotification()
                    notification.alertBody = "Está en \(sitio[beacon.minor as Int]) de la tienda \(mistiendas.obtenerTienda(major: String(describing: beacon.major)))"
                    notification.soundName = "Default"
                    UIApplication.shared.presentLocalNotificationNow(notification)
                    
                    //conexión con firebase para enviar major minor y nombre usuario, firebase debe añadir marca de tiempo
                    FIRAnalytics.logEvent(withName: "EntraEnArea", parameters: [
                        "major": beacon.major,
                        "minor": beacon.minor,
                        "usuario": emailUsuario as! NSString,
                        ])
                    print("Envío evento, estoy conectado al beacon \(beacon.major)")
                    
                    //Si cambio de tienda 
                    if (majorAnterior as NSNumber != beacon.major){
                        //Si antes estaba suscrito a algún topic
                        if ((majorAnterior + minorAnterior) != 0){
                            //Elimino la suscripción al topic anterior
                            FIRMessaging.messaging().unsubscribe(fromTopic: "/topics/\(majorAnterior)")
                            print("Unsubscribed to \(majorAnterior) topic")
                        }
                        //Me suscribo a un topic
                        FIRMessaging.messaging().subscribe(toTopic: "/topics/\(beacon.major)")
                        print("Subscribed to \(beacon.major) topic")
                    }
                
                    //Cambiamos los valores de major y minor anterior por los actuales
                    for i in 0...4 {
                        if(anterior[i][0] == suma){
                            anterior[i][1] = String (describing: beacon.major)
                            anterior[i][2] = String (describing: beacon.minor)
                        }
                    }
                    
                    
                }else{ //Si el beacon no pertenece a la lista de tiendas solo envío evento si el beacon anterior si pertenecía a uno de la lista, para indicar que me he ido
                    //if(estadoAnterior){ //Si el beacon de antes estaba en la lista
                    
                    //Realmente aquí nunca entra, ya que hemos asociado cada beacon con una región distinta -> las regiones solo tienen 1 beacon asociado, por tanto dentro de una misma región no se va a producir el paso de un beacon a otro
                    if ((majorAnterior + minorAnterior) != 0){
                        
                        //Envio notificación al usuario indicandole en qué tienda está
                        let notification = UILocalNotification()
                        notification.alertBody = "Sale de la tienda \(mistiendas.obtenerTienda(major: String(describing: majorAnterior)))"
                        notification.soundName = "Default"
                        UIApplication.shared.presentLocalNotificationNow(notification)
                        
                        //Registrar evento de desconexión de beacon
                        FIRAnalytics.logEvent(withName: "CambiaDeArea", parameters: [
                            "major": majorAnterior as NSObject ,
                            "minor": majorAnterior as NSObject,
                            "usuario": emailUsuario as! NSString
                            ])
                        print("Envío evento, he pasado del beacon \(majorAnterior) a uno no reconocido \(beacon.major)")
                        
                        //Cambiamos el estado anterior a false para que no se registren más eventos en caso de encontrarnos con otro beacon que no está en la lista o en caso de que este sea el último beacon que vemos
                        //estadoAnterior = false
                        
                        //Elimino la suscripción al topic anterior
                        FIRMessaging.messaging().unsubscribe(fromTopic: "/topics/\(majorAnterior)")
                        print("Unsubscribed to \(majorAnterior) topic")
                        
                        //Cambiamos los valores de major y minor anterior por 0
                        for i in 0...4 {
                            if(anterior[i][0] == suma){
                                anterior[i][1] = "0"
                                anterior[i][2] = "0"
                            }
                        }
                    }
                    
                }
                
                //Nos suscribimos a un tema (cuando me conecto al beacon de una tienda me suscribo al tema de dicha tienda para recibir las ofertas en forma de notificaciones) -> Diferenciamos todos los beacon de la misma tienda porque tiene el mismo major
                
            }
            
        } else {
            //comprobar el estado anterior, conectado a un beacon o no: con la suma de major y minor = 0 (si es mayor que cero estaba conectado a un beacon y por tanto debo registrar el evento y ponerlos a  0 0)
            
            //let major = majorAnterior as Int
            //let minor = minorAnterior as Int
            
            
            
            
            if((majorAnterior + minorAnterior) == 0){ //Estado anterior desconectado
                print("Sigo desconectado por lo que no envío evento")
                //El centro comercial no esta en la lista de tiendas del usuario por lo que nunca entrará en el else.
                //Si me voy del centro comercial, paro el ranging y monitoring de todos los beacons excepto del MyBeacon2000
                //Se que me he ido del centro comercial cuando el major de la region de la que he salido es el 200 y solo estoy monitorizando 2 regiones (Estoy suponiendo que las regiones se "solapan" (antes de salir de una estro en otra), por tanto cuando voy entrando en el centro comercial, antes de salir de la region 2000 entro en la 1000 y tengo más de dos regiones siendo monitorizadas)
                if ((region.major == 200)&&(monitoredRegions.count == 2)){
                    //Parar monitoring y ranging de regiones que ya no me interesan
                    let pararFinal: Set<CLRegion>  = self.monitoredRegions.subtracting(self.initialRegion) //Devuelve los elemtos que no están en initialRegions -> regiones a parar de monitoring
                    
                    //Mostrar por pantalla las regiones incluidas en parar
                    print("----------pararFinal")
                    for reg in pararFinal{
                        print(reg)
                    }
                    print("-----------------------")
                    
                    for reg in pararFinal{
                        self.locationManager.stopMonitoring(for: reg)
                        self.locationManager.stopRangingBeacons(in: reg as! CLBeaconRegion)
                    }
                }
            }
            else {//Estado anterior conectado a un beacon de la lista (significa que nos hemos ido)
                print("-------Me he desconectado del beacon, envío evento--------")
                
                //Envio notificación al usuario indicandole en qué tienda está
                let notification = UILocalNotification()
                notification.alertBody = "Sale de \(sitio[minorAnterior]) de la tienda \(mistiendas.obtenerTienda(major: String(describing: majorAnterior)))"
                notification.soundName = "Default"
                UIApplication.shared.presentLocalNotificationNow(notification)
                
                //Registrar evento de desconexión de beacon
                
                FIRAnalytics.logEvent(withName: "SaleDeArea", parameters: [
                    "major": majorAnterior as NSObject ,
                    "minor": minorAnterior as NSObject,
                    "usuario": emailUsuario as! NSString
                    ])
                print("Envío evento, he pasado del beacon \(majorAnterior) a irme")
                
                estadoAnterior = false
                
                //Elimino la suscripción al topic anterior
                FIRMessaging.messaging().unsubscribe(fromTopic: "/topics/\(majorAnterior)")
                print("Unsubscribed to \(majorAnterior) topic")

                //Cambiamos los valores de major y minor anterior por 0
                for i in 0...4 {
                    if(anterior[i][0] == suma){
                        anterior[i][1] = "0"
                        anterior[i][2] = "0"
                    }
                }
            }
            
            //update(distance: .unknown, major: 0, minor: 0)
        }

    }
    
    
    //Escanear por nuevos BLE (CoreBluetooth)
     /*func centralManagerDidUpdateState(_ central: CBCentralManager) {
     print("----------centralManagerDidUpdateState---------")
     if (central.state == .poweredOn){
     print("----------central.state == .poweredOn---------")
     self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
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
     let notification = UILocalNotification()
     notification.alertBody = "BLE"
     notification.soundName = "Default"
     UIApplication.shared.presentLocalNotificationNow(notification)
     }*/
    
    //Para que no se muestre la navigation bar
   /* override public func viewWillAppear(_ animated: Bool) {
        print("-------------------viewWillAppear2------------------")
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        print("-------------------viewWillDisappear2------------------")
        self.navigationController?.isNavigationBarHidden = false
        super.viewWillDisappear(animated)
    }*/
    
    //tiempo en un beacon = diferencia de tiempo entre eventos

    
    /* Idea (no funciona): para poder diferenciar si el beacon que estoy viendo con la aplicación trabajando en segundo plano es o no uno de la lista del usuario, llamo en el appdelegate a la funcion locationManager(:didRangeBeacons) y esta función a su vez llama a enviarNotificacionBeaconCerca, el prolema es que cuando la aplicación está en segundo plano la función locationManager(:didRangeBeacons) no se llama
     
     func enviaNotificacionBeaconCerca(beacon: CLBeacon) {
        if((beacon.major != majorAnterior)||(beacon.minor != minorAnterior)){
            print("-------------------el beacon no es el mismo que el anterior \(majorAnterior) \(minorAnterior)------------------")
            //no es el mismo que el anterior
            //hacer comprobación de si el major del beacon que estoy detectando pertenece a alguna de las tiendas seleccionadas en la configuración del usuario, si pertenece hago lo demás, sino no
            var pertenece: Bool = false
            for i in 0 ..< self.tiendas.count{
                if ((beacon.major as Int) == self.tiendas[i]){
                    pertenece = true
                }
            }
            if (pertenece){ //Si el beacon pertenece a la lista de tiendas envío notificación siempre
                print("-------------------el beacon pertenece a la lista del usuario------------------")
                let notification = UILocalNotification()
                notification.alertBody = "Entra en la region de \(mistiendas.obtenerTienda(major: String(describing: beacon.major)))"
                notification.soundName = "Default"
                UIApplication.shared.presentLocalNotificationNow(notification)
            }
        }else{
            
        }
    }*/
    

}
