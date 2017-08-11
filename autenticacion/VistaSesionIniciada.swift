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
import FBSDKCoreKit
import FBSDKLoginKit

class VistaSesionIniciada: UIViewController, CLLocationManagerDelegate{

    @IBOutlet weak var foto: UIImageView!
    @IBOutlet weak var nombre: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var distancia: UILabel!
    
    var locationManager: CLLocationManager!
    
    //'anterior' es una matriz en la que se asocia cada region (major+minor) con el valor del majorAnterior y minorAnterior detectado en ese área (inicialmente 0, no se ha detectado ningún beacon en esa área)
    var anterior: [[String]] = [["2000", "0", "0"],
                               ["1000", "0", "0"],
                               ["1001", "0", "0"],
                               ["1002", "0", "0"],
                               ["1003", "0", "0"]]
    
    var sitio: [String] = ["el escaparate", "la puerta", "la caja", "los probadores"]
    
    var nombreUsuario: String?
    var emailUsuario: String?
    var fotoURL: URL?
    var uid: String?
    
    var tiendas: [Int] = []
    
    let uuid = UUID(uuidString:   "00000000-0000-0000-0000-000000000001")!
    
    var ref: FIRDatabaseReference!
    var ref2: FIRDatabaseReference!
    var refseg: FIRDatabaseReference!
    var refpseu: FIRDatabaseReference!
    
    var newRegions = Set<CLRegion>()
    var monitoredRegions = Set<CLRegion>()
    var rangedRegions = Set<CLRegion>()
    var initialRegion = Set<CLRegion>()   //Solo va a contener una region, la correspondiente al centro comercial
    
    var mistiendas = ColeccionDeTiendas()
    
    var pseudonimo: String? = nil
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        //Datos de usuario
        mostrarDatosUsuario();
        
        //Referencia a la base de datos
        self.ref = FIRDatabase.database().reference()
        self.ref2 = FIRDatabase.database().reference()
        self.refseg = FIRDatabase.database().reference()
        self.refpseu = FIRDatabase.database().reference()
        self.ref = self.ref.child("users").child(uid!).child("tiendas")
        self.refpseu = self.refpseu.child("users").child(uid!)
       
        //Configurar boton de cerrar sesision
        configLogOutButton();
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //Mostrar en la vista los datos del usuario
    func mostrarDatosUsuario(){
        
        if let user = FIRAuth.auth()?.currentUser { //Obtener los datos del usuario con sesión iniciada
            nombreUsuario = user.displayName
            emailUsuario = user.email
            fotoURL = user.photoURL
            uid = user.uid;
        }
        
        //Nombre de usuario
        if nombreUsuario != nil{
            nombre.text = nombreUsuario
        } else { //En caso de que el nombre del usuario sea nil (usuarios que inician sesión con email y contraseña) tomamos como nombre de usuario la primera parte de la dirección de email
            nombre.text = emailUsuario?.components(separatedBy: "@")[0]
        }
        
        //Email
        email.text = emailUsuario
        
        //Foto
        if fotoURL != nil {
            let dataImagen = try? Data(contentsOf: fotoURL!)
            foto.image = UIImage(data: dataImagen!)
        }
    }
    
    //Configurar el botón de cerrar sesión
    func configLogOutButton(){
        
        // Seleccionar imagen
        let buttonCerrarSIcon = UIImage(named: "Cerrar sesion")
        
        //Añadir barbutton
        let cerrarSButton: UIBarButtonItem = UIBarButtonItem(title: "Salir", style: UIBarButtonItemStyle.plain, target: self, action: #selector(VistaSesionIniciada.pulsaCerrarSesion))
        cerrarSButton.image = buttonCerrarSIcon
        self.tabBarController?.navigationItem.setLeftBarButton(cerrarSButton, animated: true)
    }

    //Acción al pulsar cerrar sesión
    func pulsaCerrarSesion(sender:UIButton) {
        try! FIRAuth.auth()!.signOut() //Cerrar sesión
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondVC = storyboard.instantiateViewController(withIdentifier: "Vista1") as! ViewController
        self.navigationController!.pushViewController(secondVC, animated: true) //Saltar a la vista de inicio de sesión
    }
    
    //Cuando se detecte un cambio en los permisos de detección de iBeacon en la aplicación
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    
                    //Leer las tiendas guardadas en la base de datos del usuario
                    self.ref.observe(FIRDataEventType.childAdded, with: { (snapshot: FIRDataSnapshot) in
                        
                        let major = (snapshot.value as AnyObject).object(forKey: "major") as! String
                        
                        print ("Tienda de la lista del usuario \(major)")
                     
                        //Actualizar tiendas activas
                        self.tiendas.append(Int(major)!)
                        
                        //Empezar escaner
                        self.startScanning()
                        
                     })
                }
            }
        }
    }
    
    //Empezar el escaneo
    func startScanning() {
        //Inicialmente la única región que se va a monitorizar es la correspondiente al acceso al centro comercial
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: 200, minor: 0, identifier: "MyBeacon2000") //Definir región
        locationManager.startMonitoring(for: beaconRegion) //Empezar monitoring
        locationManager.startRangingBeacons(in: beaconRegion) //Empezar ranging
        locationManager.startUpdatingLocation() //Empezar uodatingLocation -> mejora la precisión de la ubicación de usuario
        initialRegion.insert(beaconRegion) //Se inicializa el conjunto initialRegion (solo contiene la región correspondiente al acceso al centro comercial)
    }
    
    //Función que determina la cercanía del usuario al iBeacon
    func update(distance: CLProximity, major: NSNumber, minor: NSNumber) {
        UIView.animate(withDuration: 0.8) { [unowned self] in
            switch distance {
            case .unknown:
                self.distancia.text = "Está fuera del área del Centro Comercial"
                
            case .far:
                self.mostrarTexto(major: major, minor: minor)
                
            case .near:
                self.mostrarTexto(major: major, minor: minor)
                
            case .immediate:
                self.mostrarTexto(major: major, minor: minor)
            }
        }
    }
    
    //Muestra un mensaje en la vista de la app indicando al usuario donde se encunetra
    func mostrarTexto(major: NSNumber, minor: NSNumber){
        if major == 200{
            self.distancia.text = "Está en el Centro Comercial"
        }else{
            self.distancia.text = "Está en \(self.sitio[minor as Int]) de la tienda \(self.mistiendas.obtenerTienda(major: String(describing: major)))"
        }
    }
    
    //Ranging. Se realiza por cada region activada periodicamente (una función ranging por cada región)
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        
        //Inicialización de variable locales de la función
        var majorAnterior: Int = 0
        var minorAnterior: Int = 0
        var suma = ""
        
        monitoredRegions = locationManager.monitoredRegions //Regiones que están siendo monitorizadas
        rangedRegions = locationManager.rangedRegions //Regiones que con 'ranging' activo
        
        /*print("----------monitoredRegions")
        //Mostrar por pantalla las regiones incluidas en monitoredRegions
        for reg in self.monitoredRegions{
            print(reg)
        }
        print("-----------------------")*/
        
        /*print("----------rangedRegions")
        //Mostrar por pantalla las regiones incluidas en monitoredRegions
        for reg in self.rangedRegions{
            print(reg)
        }
        print("-----------------------")*/
        
        if (region.major != nil)&&(region.minor != nil){ //Si entro en alguna región
            let mj = String(describing: region.major!)
            let mn = String(describing: region.minor!)
            suma = mj+mn //Suma del major y minor -> Para buscar regiones
        
            //Obtener valores de major y minor anteriores
            for i in 0...4 {
                if(anterior[i][0] == suma){
                    majorAnterior = Int (anterior[i][1])! //Obtengo el major del iBeacon anterior detectado en la región
                    minorAnterior = Int (anterior[i][2])! //Obtengo el minor del iBeacon anterior detectado en la región
                }
            }
        }
        
        if beacons.count > 0 { //Si hay algún iBeacon cerca
            
            let beacon = beacons[0] //Cogemos el iBeacon más cercano
            
            update(distance: beacon.proximity, major: beacon.major, minor: beacon.minor) //Determinar cercanía del usuario al iBeacon
            
            //Actualizar regiones a monitorizar y 'ranging'
            actualizarMonitoringYRanging(beacon: beacon);
            
            //Si el iBeacon no es mismo que el anterior enviar evento (significa que acabamos de entrar en el área de cobertura del iBeacon)
            if((beacon.major != majorAnterior as NSNumber)||(beacon.minor != minorAnterior as NSNumber)){
                
                print("Usuario entra en el área del iBeacon \(beacon.major) \(beacon.minor)")
                
                if (beaconPerteneceALista(beacon: beacon)){ //Si el beacon pertenece a la lista de tiendas del usuario
                    print("pasa por pertenece")

                    /*//Envio notificación al usuario indicandole en qué tienda está
                    enviarNotificacion(cuerpo: "Está en \(sitio[beacon.minor as Int]) de la tienda \(mistiendas.obtenerTienda(major: String(describing: beacon.major)))");*/
                    
                    print ("Está en \(sitio[beacon.minor as Int]) de la tienda \(mistiendas.obtenerTienda(major: String(describing: beacon.major)))")
                    
                    refpseu.child("pseudonimo").observeSingleEvent(of: .value, with: { (snapshot) in
                        self.pseudonimo = snapshot.value as! String? //Obtener el pseudónimo del usuario de la base de datos
                    
                        //Envío evento de "Entra en área" con los datos del iBeacon y el pseudónimo del usuario
                        self.enviarEvento(nombre: "EntraEnArea", major: beacon.major, minor: beacon.minor, usuario: self.pseudonimo! as NSString);
                    })
                
                    //Cambiamos los valores de major y minor anterior por los actuales
                    actualizaMajorAnteriorYMinorAnterior(major: String (describing: beacon.major), minor: String (describing: beacon.minor), region: suma);
                    
                }else{ //El beacon no pertenece a la lista de tiendas
                    print ("El iBeacon no pertenece a ninguna tienda de la lista del usuario")
                }
            }else{
                print("Usuario sigue en el área del iBeacon \(beacon.major) \(beacon.minor)")
            }
            
        } else { //No se detecta ningún iBeacon cerca
            
            if((majorAnterior + minorAnterior) == 0){ //Estado anterior desconectado
                
                print("Usuario no conectado a ningún iBeacon en la región \(region.major!) \(region.minor!)")
                
                if ((region.major == 200)&&(monitoredRegions.count == 2)){ //Si salgo del centro comercial
                    pararMonitoringYRangingRegiones(salirCentroComercial: true) //Parar monitoring y ranging de regiones que ya no me interesan
                }
                
            }else{ //Estado anterior conectado a un iBeacon de la lista (significa que nos hemos ido)
                
                /*//Envio notificación al usuario indicandole de que tienda sale
                enviarNotificacion(cuerpo: "Sale de \(sitio[minorAnterior]) de la tienda \(mistiendas.obtenerTienda(major: String(describing: majorAnterior)))")*/
                
                print ("Sale de \(sitio[minorAnterior]) de la tienda \(mistiendas.obtenerTienda(major: String(describing: majorAnterior)))")
                
                refpseu.child("pseudonimo").observeSingleEvent(of: .value, with: { (snapshot) in
                    self.pseudonimo = snapshot.value as! String? //Obtener el pseudónimo del usuario de la base de datos
                
                    //Envío evento de "Sale de área" con los datos del iBeacon y el pseudónimo del usuario
                    self.enviarEvento(nombre: "SaleDeArea", major: majorAnterior as NSNumber, minor: minorAnterior as NSNumber, usuario: self.pseudonimo! as NSString)
                })

                //Cambiamos los valores de major y minor anterior por 0
                actualizaMajorAnteriorYMinorAnterior(major: "0", minor: "0", region: suma);
            }
        }
    }
    
    //Actualizar regiones a monitorizar y 'ranging'
    func actualizarMonitoringYRanging(beacon: CLBeacon){
        let mj = String(describing: beacon.major)
        let mn = String(describing: beacon.minor)
        let suma = mj+mn
        
        //Leer de la base de datos los iBeacos a monitorizar y 'ranging'
        self.ref2.child("beacons").child(suma).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let arraybeacons: [AnyObject] = snapshot.value as! [AnyObject] //Obtengo un array con los major+minor de las regiones
            
            print("Beacons a monitorizar \(arraybeacons)")
            
            //Crear regiones a partir de la suma de major+minor
            self.crearRegiones(beacons: arraybeacons);
            
            //Parar monitoring y ranging de regiones que ya no me interesan
            self.pararMonitoringYRangingRegiones(salirCentroComercial: false);
            
            //Activar monitoring y ranging de las nuevas regiones
            self.activarMonitoringYRangingRegiones();
            
            //Vaciar el conjunto newRegions
            self.newRegions.removeAll()
            
            
        })
    }
    
    //Crear regiones a partir de la suma del major y minor de los iBeacons vecinos obtenidos de la base de datos
    func crearRegiones(beacons: [AnyObject]) {
        for i in 0..<beacons.count{
            let n = beacons[i] as! NSNumber
            let sum = String(describing: n)
            let index: String.Index = sum.index(sum.startIndex, offsetBy: 3)  //Los tres primeros caracteres indican el major y el resto el minor
            let maj: String = sum.substring(to: index)
            let min: String = sum.substring(from: index)
            
            //Crear nueva region e insertar en newRegions
            self.newRegions.insert(CLBeaconRegion(proximityUUID: self.uuid, major: CLBeaconMajorValue(maj)!, minor: CLBeaconMinorValue(min)!, identifier: "MyBeacon\(n)"))  //Necesario cambiar el identificador, si no toma todas las regiones como si fuesen la misma y solo incluye una en el set
        }
        
    }
    
    //Parar de 'monitoring' y 'ranging' regiones
    func pararMonitoringYRangingRegiones(salirCentroComercial: Bool){
        
        let parar: Set<CLRegion>
        
        if salirCentroComercial { //Si el usuario está saliendo del centro comercial
            
            parar = self.monitoredRegions.subtracting(self.initialRegion) //Devuelve los elemtos de monitoredRegions que no están en initialRegions
            
        }else{
            
           parar = self.monitoredRegions.subtracting(self.newRegions) //Devuelve los elemtos de monitoredRegions que no están en newRegions
            
        }
        
        for reg in parar{
            self.locationManager.stopMonitoring(for: reg) //Parar 'monitoring'
            self.locationManager.stopRangingBeacons(in: reg as! CLBeaconRegion) //Parar 'ranging'
        }
    }
    
    //Activar de 'monitoring' y 'ranging' regiones
    func activarMonitoringYRangingRegiones(){
        
        let activar: Set<CLRegion>  = self.newRegions.subtracting(self.monitoredRegions) //Devuelve los elemtos de newRegions que no están en monitoredRegions
        
        for reg in activar{
            self.locationManager.startMonitoring(for: reg) //Activar 'monitoring'
            self.locationManager.startRangingBeacons(in: reg as! CLBeaconRegion) //Activar 'ranging'
        }
    }
    
    //Comprobar si un iBeacon se corresponde con alguna de las tiendas de la lista del usuario
    func beaconPerteneceALista(beacon: CLBeacon) -> Bool {

        var pertenece: Bool = false
        
        for i in 0 ..< self.tiendas.count{
            if ((beacon.major as Int) == self.tiendas[i]){
                pertenece = true
            }
        }
        
        return pertenece
    }
    
    /*//Enviar notificación al usuario
    func enviarNotificacion(cuerpo: String){
        let notification = UILocalNotification()
        notification.alertBody = cuerpo
        notification.soundName = "Default"
        UIApplication.shared.presentLocalNotificationNow(notification)
    }*/
    
    //Enviar evento a Firebase Analytics
    func enviarEvento(nombre: String, major: NSNumber, minor: NSNumber, usuario: NSString){
        FIRAnalytics.logEvent(withName: nombre, parameters: [
            "major": major,
            "minor": minor,
            "usuario": usuario,
            ])
    }
    
    //Actualizar valores de major y minor anterior
    func actualizaMajorAnteriorYMinorAnterior(major: String, minor: String, region: String){
        for i in 0...4 {
            if(anterior[i][0] == region){
                anterior[i][1] = major
                anterior[i][2] = minor
            }
        }
    }
    
    //Pulsar actualizar posición
    @IBAction func pulsaActualizarPosicion(_ sender: Any) {
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "Actualizar") //Región definida por el UID del centro comerciañ
        locationManager.startMonitoring(for: beaconRegion) //Activar monitoreo de la región
        locationManager.startRangingBeacons(in: beaconRegion) //Activar ranging de la región
        locationManager.startUpdatingLocation() //Activar la actualización de la localización de la región
    }

    //Pulsar cambiar nombre
    @IBAction func pulsaCambiarNombre(_ sender: Any) {
        showTextInputPrompt(withMessage: "Nuevo nombre:") { (userPressedOK, name) in
            if let name = name {
                let user = FIRAuth.auth()?.currentUser
                if let user = user {
                    let changeRequest = user.profileChangeRequest()
                    changeRequest.displayName = name
                    changeRequest.commitChanges { error in
                        if let error = error {
                            // An error happened.
                            self.showMessagePrompt(error.localizedDescription)
                            return
                        } else {
                            // Profile updated.
                            self.showMessagePrompt("Nombre de usuario actualizado.")
                            self.nombre.text = name
                        }
                    }
                }
            } else {
                self.showMessagePrompt("Debe introducir un nuevo nombre de usuario.")
            }
        }
    }
}
