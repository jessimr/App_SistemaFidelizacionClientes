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
//import CoreBluetooth

class VistaSesionIniciada: UIViewController, CLLocationManagerDelegate{ //, CBCentralManagerDelegate


    @IBOutlet weak var foto: UIImageView!
    @IBOutlet weak var nombre: UILabel!
    @IBOutlet weak var email: UILabel!
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
    
    var newRegions = Set<CLRegion>()
    var monitoredRegions = Set<CLRegion>()
    var rangedRegions = Set<CLRegion>()
    var initialRegion = Set<CLRegion>()   //Solo va a contener una region, la correspondiente al centro comercial
    
    var mistiendas = ColeccionDeTiendas()
    
    //var centralManager: CBCentralManager?
    
    var ultimo:String?
    
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
        self.ref = self.ref.child("users").child(uid!).child("tiendas")
       
        //Configurar boton de cerrar sesision
        configLogOutButton();
        
        // Start up the CBCentralManager
        //centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }
    
    func mostrarDatosUsuario(){
        if let user = FIRAuth.auth()?.currentUser {
            nombreUsuario = user.displayName
            emailUsuario = user.email
            fotoURL = user.photoURL
            uid = user.uid;
        }
        
        //Nombre de usuario
        if nombreUsuario != nil{
            nombre.text = nombreUsuario
        } else {
            //Tomamos como nombre de usuario la primera parte de la dirección de email
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
    
    func configLogOutButton(){
        // Seleccionar imagen
        let buttonCerrarSIcon = UIImage(named: "Cerrar sesion")
        
        //Añadir barbutton
        let cerrarSButton: UIBarButtonItem = UIBarButtonItem(title: "Salir", style: UIBarButtonItemStyle.plain, target: self, action: #selector(VistaSesionIniciada.pulsaCerrarSesion))
        cerrarSButton.image = buttonCerrarSIcon
        self.tabBarController?.navigationItem.setLeftBarButton(cerrarSButton, animated: true)
    }

    func pulsaCerrarSesion(sender:UIButton) {
        try! FIRAuth.auth()!.signOut()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondVC =   storyboard.instantiateViewController(withIdentifier: "Vista1") as! ViewController
        self.navigationController!.pushViewController(secondVC, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
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
        //Definimos la region (se pueden monitorear hasta 20 regiones al mismo tiempo)
        //Region la puerta del centro comercial
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: 200, minor: 0, identifier: "MyBeacon2000")
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
        locationManager.startUpdatingLocation() //nuevo
        
        initialRegion.insert(beaconRegion)
        
    }
    
    
    
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
    
    func mostrarTexto(major: NSNumber, minor: NSNumber){
        if major == 200{
            self.distancia.text = "Está en el Centro Comercial"
        }else{
            self.distancia.text = "Está en \(self.sitio[minor as Int]) de la tienda \(self.mistiendas.obtenerTienda(major: String(describing: major)))"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        //Se realiza por cada region activada periodicamente -> cambiar el uso de variables globales en esta función ya que conllevan a error (majorAnterior, minorAnterior....)
        //Para que aparezca en los eventos el UserID
        FIRAnalytics.setUserID(emailUsuario)
        
        //Inicialización de variable locales de la función
        var majorAnterior: Int = 0
        var minorAnterior: Int = 0
        var suma = ""
        
        //Regiones monitorizadas
        monitoredRegions = locationManager.monitoredRegions //The location manager persists region data between launches of your app.
        rangedRegions = locationManager.rangedRegions
        
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
        
        //Intentar monitorizar las nuevas regiones de los vecinos y parar de monitorizar regiones que ya no interesan -> las regiones de los vecinos en el database
        //Tomo major y minor de la región, los convierto a String y los "sumo"
        
        if (region.major != nil)&&(region.minor != nil){
            let mj = String(describing: region.major!)
            //print ("------------>\(mj)<-----------")
            let mn = String(describing: region.minor!)
            //print ("------------>\(mn)<-----------")
            suma = mj+mn
            print ("------------>\(suma)<-----------")
        
            //Obtener valores de major y minor anteriores
            for i in 0...4 {
                if(anterior[i][0] == suma){
                    majorAnterior = Int (anterior[i][1])!
                    minorAnterior = Int (anterior[i][2])!
                }
            }
        }
        
        if beacons.count > 0 { //si hay algún beacon cerca
            let beacon = beacons[0]
            update(distance: beacon.proximity, major: beacon.major, minor: beacon.minor)
            
            //Actualizar regiones a monitorizar 
            actualizarMonitoringYRanging(beacon: beacon);
            
            //si el beacon no es mismo que el anterior enviar evento
            if((beacon.major != majorAnterior as NSNumber)||(beacon.minor != minorAnterior as NSNumber)){
                
                print("Estoy conectado a un beacon") //-> Realmente pasa de no estar conectado al beacon asociado a la región a si estarlo (en las regiones solo hay un beacon)  -> Solo entrará en este else cuando se producza el cambio de "no conectado" a "conectado", una vez conectado al beacon no volverá a entrar (a no ser que nos desconectemos y nos volvamos a conectar)
                
                //hacer comprobación de si el major del beacon que estoy detectando pertenece a alguna de las tiendas seleccionadas en la configuración del usuario, si pertenece hago lo demás, sino no
                
                if (beaconPerteneceALista(beacon: beacon)){ //Si el beacon pertenece a la lista de tiendas envío evento siempre
                    //Escaneo beacon seguridad
                    //scan()

                    //Envio notificación al usuario indicandole en qué tienda está
                    enviarNotificacion(cuerpo: "Está en \(sitio[beacon.minor as Int]) de la tienda \(mistiendas.obtenerTienda(major: String(describing: beacon.major)))");
                    
                    //conexión con firebase para enviar major minor y nombre usuario, firebase debe añadir marca de tiempo
                    enviarEvento(nombre: "EntraEnArea", major: beacon.major, minor: beacon.minor, usuario: emailUsuario as! NSString);
                
                    //Cambiamos los valores de major y minor anterior por los actuales
                    actualizaMajorAnteriorYMinorAnterior(major: String (describing: beacon.major), minor: String (describing: beacon.minor), region: suma);
                    
                    //centralManager?.stopScan()
                    
                }
                
            }
            
        } else { //No se detecta ningún beacon cerca
            //comprobar el estado anterior, conectado a un beacon o no: con la suma de majorAnterior y minorAnterior = 0 (si es mayor que cero estaba conectado a un beacon y por tanto debo registrar el evento y ponerlos a  0 0)
            
            if((majorAnterior + minorAnterior) == 0){ //Estado anterior desconectado
                print("Sigo desconectado por lo que no envío evento")
                //El centro comercial no esta en la lista de tiendas del usuario por lo que nunca entrará en el else, ya que para el el majorAnt y minorAnt siempre serán 0.
                //Si me voy del centro comercial, paro el ranging y monitoring de todos los beacons excepto del MyBeacon2000
                //Se que me he ido del centro comercial cuando el major de la region de la que he salido es el 200 y solo estoy monitorizando 2 regiones (Estoy suponiendo que las regiones se "solapan" (antes de salir de una entro en otra), por tanto cuando voy entrando en el centro comercial, antes de salir de la region 2000 entro en la 1000 y tengo más de dos regiones siendo monitorizadas)
                if ((region.major == 200)&&(monitoredRegions.count == 2)){
                    //Parar monitoring y ranging de regiones que ya no me interesan
                    pararMonitoringYRangingRegiones(salirCentroComercial: true)
                }
            }
            else {//Estado anterior conectado a un beacon de la lista (significa que nos hemos ido)
                print("-------Me he desconectado del beacon, envío evento--------")
                
                //Envio notificación al usuario indicandole de que tienda sale
                enviarNotificacion(cuerpo: "Sale de \(sitio[minorAnterior]) de la tienda \(mistiendas.obtenerTienda(major: String(describing: majorAnterior)))")
                
                //Registrar evento de desconexión de beacon
                enviarEvento(nombre: "SaleDeArea", major: majorAnterior as NSNumber, minor: minorAnterior as NSNumber, usuario: emailUsuario as! NSString)

                //Cambiamos los valores de major y minor anterior por 0
                actualizaMajorAnteriorYMinorAnterior(major: "0", minor: "0", region: suma);
            }
        }

    }
    
    func actualizarMonitoringYRanging(beacon: CLBeacon){
        
        let mj = String(describing: beacon.major)
        let mn = String(describing: beacon.minor)
        let suma = mj+mn
        
        //Indico este beacon como ultimo -> para escribirlo en la base de datos y que se ejecute bien lo de la seguridad
        ultimo = suma
        refseg.child("users/\(uid!)/iBeacon").setValue(ultimo)
        
        //Leer de la base de datos los beacos a monitorizar
        self.ref2.child("beacons").child(suma).observeSingleEvent(of: .value, with: { (snapshot) in
            let arraybeacons: [AnyObject] = snapshot.value as! [AnyObject] //Obtengo un array con los majorminor de los beacons -> beacons de las regiones que tengo que activar
            print(arraybeacons)
            
            //Crear regiones a partir de los beacons y guardarlas en un set
            self.crearRegiones(beacons: arraybeacons);
            
            //Parar monitoring y ranging de regiones que ya no me interesan
            self.pararMonitoringYRangingRegiones(salirCentroComercial: false);
            
            //Activar monitoring y ranging de las nuevas regiones
            self.activarMonitoringYRangingRegiones();
            
            //Vaciar el newRegions
            self.newRegions.removeAll()
            
        })
    }
    
    func crearRegiones(beacons: [AnyObject]) {
        for i in 0..<beacons.count{
            let n = beacons[i] as! NSNumber
            let sum = String(describing: n)
            let index: String.Index = sum.index(sum.startIndex, offsetBy: 3)  //Los tres primeros caracteres indican el major y el resto el minor
            let maj: String = sum.substring(to: index)
            let min: String = sum.substring(from: index)
            
            //Crear nueva region e insertar en newRegions
            self.newRegions.insert(CLBeaconRegion(proximityUUID: self.uuid, major: CLBeaconMajorValue(maj)!, minor: CLBeaconMinorValue(min)!, identifier: "MyBeacon\(n)"))  //Necesario cambiar el identificador, sino toma todas las regiones como si fuese la misma y solo incluye 1 en el set
        }
    }
    
    func pararMonitoringYRangingRegiones(salirCentroComercial: Bool){
        let parar: Set<CLRegion>
        if salirCentroComercial { //true
            parar = self.monitoredRegions.subtracting(self.initialRegion) //Devuelve los elemtos que no están en initialRegions -> regiones a parar de monitoring
        }else{ //false
           parar = self.monitoredRegions.subtracting(self.newRegions) //Devuelve los elemtos que no están en newRegions -> regiones a parar de monitoring
        }
        
        for reg in parar{
            self.locationManager.stopMonitoring(for: reg)
            self.locationManager.stopRangingBeacons(in: reg as! CLBeaconRegion)
        }
    }
    
    func activarMonitoringYRangingRegiones(){
        let activar: Set<CLRegion>  = self.newRegions.subtracting(self.monitoredRegions) //Devuelve los elemtos que no están en monitoredRegions -> nuevas regiones a monitorizar
        
        for reg in activar{
            self.locationManager.startMonitoring(for: reg)
            self.locationManager.startRangingBeacons(in: reg as! CLBeaconRegion)
        }
    }
    
    func beaconPerteneceALista(beacon: CLBeacon) -> Bool {
        var pertenece: Bool = false
        for i in 0 ..< self.tiendas.count{
            if ((beacon.major as Int) == self.tiendas[i]){
                pertenece = true
            }
        }
        return pertenece
    }
    
    func enviarNotificacion(cuerpo: String){
        let notification = UILocalNotification()
        notification.alertBody = cuerpo
        notification.soundName = "Default"
        UIApplication.shared.presentLocalNotificationNow(notification)
    }
    
    func enviarEvento(nombre: String, major: NSNumber, minor: NSNumber, usuario: NSString){
        FIRAnalytics.logEvent(withName: nombre, parameters: [
            "major": major,
            "minor": minor,
            "usuario": usuario,
            ])
    }
    
    func actualizaMajorAnteriorYMinorAnterior(major: String, minor: String, region: String){
        for i in 0...4 {
            if(anterior[i][0] == region){
                anterior[i][1] = major
                anterior[i][2] = minor
            }
        }
    }
    
    @IBAction func pulsaActualizarPosicion(_ sender: Any) {
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "Actualizar")
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
        locationManager.startUpdatingLocation() //nuevo
    }

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
    
    
/*    //No escanea los beacons
    //Escanear por nuevos BLE (CoreBluetooth)
   func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            print(central.state)
            //Para que detecte los Eddysrone-uid beacon en el background hay que definir los servicios que queremos que sean escaneados
            //CBUUID IDENTIFICADOR DEL TIPO DE SERVICIO, EN EL CASO DE LOS EDDYSTONE, ESTE TIPO DE SERVICIO ES FEAA
            //let arrayOfServices: [CBUUID] = [CBUUID(string: "FEAA")]
            //let options = [CBCentralManagerScanOptionAllowDuplicatesKey : true]
            //self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
            //scan()
        }
        else {
            // do something like alert the user that ble is not on
        }
    }
    
    func scan() {
        print("------scan------")
        
        /*centralManager?.scanForPeripherals(
            withServices: nil, options: [  //[transferServiceUUID]
                CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: true as Bool)
            ]
        )*/
        let arrayOfServices: [CBUUID] = [CBUUID(string: "FEAA")]
        self.centralManager?.scanForPeripherals(withServices: arrayOfServices, options: nil)
        
        print("Scanning started")
    }
    
    //Si encuentra un BLE
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print ("advertisementData: \(advertisementData)")
        
        //print("kCBAdvDataIsConnectable : \(advertisementData["kCBAdvDataIsConnectable"])")
        //print("kCBAdvDataManufacturerData : \(advertisementData["kCBAdvDataManufacturerData"])")
        //print("kCBAdvDataLocalName : \(advertisementData["kCBAdvDataLocalName"])")
        //print(advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID])
        //print (advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID])
        //print(advertisementData["CBAdvertisementServiceDataKey"] as? String)
        //print("data : \(advertisementData["data"])")
        let datos = advertisementData["kCBAdvDataServiceData"] as? NSDictionary
        print ("datos \(datos)")
        print ("valor \(datos?.allValues)")
        //print ("peripheral.identifier: \(peripheral.identifier)")
        //print ("peripheral.services: \(peripheral.services)")
        
        let refseg = FIRDatabase.database().reference()
        
        //Obtener el token actual
        let token = FIRInstanceID.instanceID().token()
        print ("token \(token)")
        print ("uid \(uid)")
        
        //Registrar el token
        refseg.child("users/\(uid!)/tokens").setValue(token!)
        
        //Registrar el último iBeacon detectado
        self.refseg.child("users/\(uid!)/iBeacon").setValue(ultimo)
        
        //Registrar el BLE en la base de datos
        self.refseg.child("users/\(uid!)/seguridad").setValue(String(describing:datos!.allValues))
        
        
        //Cuando se encuentre un eddystone-uid se envía un evento a firebase -> si mando el evento al superponerse con los de las tiendas me se queda la app colgada
       /* FIRAnalytics.logEvent(withName: "BLE", parameters: [
            "data": String(describing:datos.allValues) as NSString,
            "usuario": FIRAuth.auth()?.currentUser?.email as! NSString,
            "uid": FIRAuth.auth()?.currentUser?.uid as! NSString,
            ])*/
        
    }*/
    
    
    
}
