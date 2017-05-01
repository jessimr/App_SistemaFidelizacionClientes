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

class VistaSesionIniciada: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var distancia: UILabel!
    var locationManager: CLLocationManager!
    
    //Los estados de majorAnterior=0 y minorAnterior=0 significa que no estoy conectada a ningún beacon. Con lo cual ningún beacon de ninguna tienda puede tener estos valores a 0.
    var majorAnterior: NSNumber = 0
    var minorAnterior: NSNumber = 0
    
    var nombreUsuario: String?
    var emailUsuario: String?
    var fotoURL: URL?
    var uid: String?
    var tiendas: [Int] = []
    var estadoAnterior: Bool = false
    
    let uuid = UUID(uuidString:   "00000000-0000-0000-0000-000000000001")!
    
    var ref: FIRDatabaseReference!
    var ref2: FIRDatabaseReference!
    
    var newRegions = Set<CLRegion>()
    var monitoredRegions = Set<CLRegion>()
    
    var mistiendas = ColeccionDeTiendas()
    
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
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        print("-------------------locationManagerdidRangeBeacons------------------")
        //Para que aparezca en los eventos el UserID
        FIRAnalytics.setUserID(emailUsuario)
        
        //Regiones monitorizadas
        monitoredRegions = locationManager.monitoredRegions
        
        print("----------monitoredRegions")
        //Mostrar por pantalla las regiones incluidas en monitoredRegions
        for reg in self.monitoredRegions{
            print(reg)
        }
        print("-----------------------")
        
        if beacons.count > 0 { //si hay algún beacon cerca
            let beacon = beacons[0]
            update(distance: beacon.proximity, major: beacon.major, minor: beacon.minor)

            
            
            //Intentar monitorizar las nuevas regiones de los vecinos y parar de monitorizar regiones que ya no interesan -> las regiones de los vecinos en el database
            //Tomo major y minor del beacon, los convierto a String y los "sumo"
            let mj = String(describing: beacon.major)
            //print ("------------>\(mj)<-----------")
            let mn = String(describing: beacon.minor)
            //print ("------------>\(mn)<-----------")
            let suma = mj+mn
            //print ("------------>\(suma)<-----------")
            
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
            if((beacon.major == majorAnterior)&&(beacon.minor == minorAnterior)){
                //print("Sigo conectado al mismo beacon por lo que no envío evento")
            }else{
                //print("Estoy conectado a otro beacon")
                
                //hacer comprobación de si el major del beacon que estoy detectando pertenece a alguna de las tiendas seleccionadas en la configuración del usuario, si pertenece hago lo demás, sino no
                var pertenece: Bool = false
                for i in 0 ..< self.tiendas.count{
                    if ((beacon.major as Int) == self.tiendas[i]){
                        pertenece = true
                    }
                }
               
                
                if (pertenece){ //Si el beacon pertenece a la lista de tiendas envío evento siempre
                    estadoAnterior = true
                    
                    //Envio notificación al usuario indicandole en qué tienda está
                    let notification = UILocalNotification()
                    notification.alertBody = "Está en la tienda \(mistiendas.obtenerTienda(major: String(describing: beacon.major)))"
                    notification.soundName = "Default"
                    UIApplication.shared.presentLocalNotificationNow(notification)
                    
                    //conexión con firebase para enviar major minor y nombre usuario, firebase debe añadir marca de tiempo
                    FIRAnalytics.logEvent(withName: "beacon", parameters: [
                        "major": beacon.major,
                        "minor": beacon.minor,
                        "usuario": emailUsuario as! NSString,
                        ])
                    print("Envío evento, estoy conectado al beacon \(beacon.major)")
                    
                    //Si cambio de tienda 
                    if (majorAnterior != beacon.major){
                        //Si antes estaba suscrito a algún topic
                        if (((majorAnterior as Int) + (minorAnterior as Int)) != 0){
                            //Elimino la suscripción al topic anterior
                            FIRMessaging.messaging().unsubscribe(fromTopic: "/topics/\(majorAnterior)")
                            print("Unsubscribed to \(majorAnterior) topic")
                        }
                        //Me suscribo a un topic
                        FIRMessaging.messaging().subscribe(toTopic: "/topics/\(beacon.major)")
                        print("Subscribed to \(beacon.major) topic")
                    }
                
                    //Cambiamos los valores de major y minor anterior por lo actuales
                    majorAnterior = beacon.major
                    minorAnterior = beacon.minor
                    
                    
                }else{ //Si el beacon no pertenece a la lista de tiendas solo envío evento si el beacon anterior si pertenecía a uno de la lista, para indicar que me he ido
                    if(estadoAnterior){ //Si el beacon de antes estaba en la lista
                        
                        //Envio notificación al usuario indicandole en qué tienda está
                        let notification = UILocalNotification()
                        notification.alertBody = "Sale de la tienda \(mistiendas.obtenerTienda(major: String(describing: majorAnterior)))"
                        notification.soundName = "Default"
                        UIApplication.shared.presentLocalNotificationNow(notification)
                        
                        //Registrar evento de desconexión de beacon
                        FIRAnalytics.logEvent(withName: "beacon", parameters: [
                            "major": majorAnterior ,
                            "minor": majorAnterior,
                            "usuario": emailUsuario as! NSString
                            ])
                        print("Envío evento, he pasado del beacon \(majorAnterior) a uno no reconocido \(beacon.major)")
                        
                        //Cambiamos el estado anterior a false para que no se registren más eventos en caso de encontrarnos con otro beacon que no está en la lista o en caso de que este sea el último beacon que vemos
                        estadoAnterior = false
                        
                        //Elimino la suscripción al topic anterior
                        FIRMessaging.messaging().unsubscribe(fromTopic: "/topics/\(majorAnterior)")
                        print("Unsubscribed to \(majorAnterior) topic")
                        
                        //Cambiamos los valores de major y minor anterior por 0
                        majorAnterior = 0
                        minorAnterior = 0
                    }
                    
                }
                
                //Nos suscribimos a un tema (cuando me conecto al beacon de una tienda me suscribo al tema de dicha tienda para recibir las ofertas en forma de notificaciones) -> Diferenciamos todos los beacon de la misma tienda porque tiene el mismo major
                
            }
            
        } else {
            //comprobar el estado anterior, conectado a un beacon o no: con la suma de major y minor = 0 (si es mayor que cero estaba conectado a un beacon y por tanto debo registrar el evento y ponerlos a  0 0)
            
            let major = majorAnterior as Int
            let minor = majorAnterior as Int
            
            
            if((major + minor) == 0){ //Estado anterior desconectado
                //print("Sigo desconectado por lo que no envío evento")
            }else if (((major + minor) != 0) && (estadoAnterior == true)) {//Estado anterior conectado a un beacon de la lista (significa que nos hemos ido)
                //print("Me he desconectado del beacon, envío evento")
                
                //Envio notificación al usuario indicandole en qué tienda está
                let notification = UILocalNotification()
                notification.alertBody = "Sale de la tienda \(mistiendas.obtenerTienda(major: String(describing: majorAnterior)))"
                notification.soundName = "Default"
                UIApplication.shared.presentLocalNotificationNow(notification)
                
                //Registrar evento de desconexión de beacon
                
                FIRAnalytics.logEvent(withName: "beacon", parameters: [
                    "major": majorAnterior ,
                    "minor": minorAnterior,
                    "usuario": emailUsuario as! NSString
                    ])
                print("Envío evento, he pasado del beacon \(majorAnterior) a irme")
                
                estadoAnterior = false
                
                //Elimino la suscripción al topic anterior
                FIRMessaging.messaging().unsubscribe(fromTopic: "/topics/\(majorAnterior)")
                print("Unsubscribed to \(majorAnterior) topic")

                //Cambiamos los valores de major y minor anterior por 0
                majorAnterior = 0
                minorAnterior = 0
            }
            
            update(distance: .unknown, major: 0, minor: 0)
        }
    }
    
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
