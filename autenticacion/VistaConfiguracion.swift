//
//  VistaConfiguracion.swift
//  autenticacion
//
//  Created by JESSICA MENDOZA RUIZ on 23/03/2017.
//  Copyright © 2017 JESSICA MENDOZA RUIZ. All rights reserved.
//

import UIKit
import Firebase

class VistaConfiguracion: UIViewController, UITableViewDataSource, UITableViewDelegate{
  
    @IBOutlet weak var tabla: UITableView!
    
    var mistiendas = ColeccionDeTiendas()
    
    var ref: FIRDatabaseReference!
    var ref2: FIRDatabaseReference!
    
    let userID = FIRAuth.auth()?.currentUser?.uid
    let username = FIRAuth.auth()?.currentUser?.displayName

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Configurar boton de cerrar sesision
        configLogOutButton();
        
        self.ref = FIRDatabase.database().reference()
        
        //Registrar el nombre del usuario en la base de datos
        self.ref.child("users/\(userID!)/username").setValue(username)

        self.ref2 = self.ref.child("users").child(userID!).child("tiendas")
        
        //Leer tiendas de la base de datos
        leerKeysDeLasTiendasDeLaBD()
}
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Leer las tiendas que el usuario tiene guardadas en su base de datos
    func leerKeysDeLasTiendasDeLaBD(){
        
        var arrayKey: [String] = []
        
        //Leer keys asociado a las tiendas guardadas en la base de datos <- necesario para poder borrarlas
        self.ref2.observeSingleEvent(of: .value, with: { snapshot in

            for child in snapshot.children {
                let key = (child as AnyObject).key!
                arrayKey.append(key)
                
            }
            
            //Leer los major de las tiendas
            self.ref2.observe(FIRDataEventType.childAdded, with: { (snapshot: FIRDataSnapshot) in //Aquí entra cada vez que se añade una tienda a la lista
                let major = (snapshot.value as AnyObject).object(forKey: "major") as! String
                
                //Actualizar tiendas activas (solo al inicio)
                for i in 0 ..< self.mistiendas.tiendas.count{ //Recorremos todas las tiendas del array
                    if ((major == self.mistiendas.tiendas[i][1])&&(arrayKey.count > 0)){ //Si la tienda está en la base de datos del usuario y es la primera vez que se realiza la actualización
                        self.mistiendas.switchState(position: i, state: "1") //Cambio el estado de la tienda a seleccionado
                        self.mistiendas.guardarKey(position: i, key: arrayKey[0]) //Guardar key asociada a la tienda
                        arrayKey.remove(at: 0) //Eliminar la key ya guardada
                    }
                }
                
                self.tabla.reloadData() //Recargar tabla
            })
            
        })
    }
    
    //Configurar el botón de cerrar sesión
    func configLogOutButton(){
        
        // Seleccionar imagen
        let buttonCerrarSIcon = UIImage(named: "Cerrar sesion")
        
        //Añadir barbutton
        let cerrarSButton: UIBarButtonItem = UIBarButtonItem(title: "Salir", style: UIBarButtonItemStyle.plain, target: self, action: #selector(VistaConfiguracion.pulsaCerrarSesion))
        cerrarSButton.image = buttonCerrarSIcon
        self.tabBarController?.navigationItem.setLeftBarButton(cerrarSButton, animated: true)
        
    }
    
    //Pulsar cerrar sesión
    func pulsaCerrarSesion(sender:UIButton) {
        try! FIRAuth.auth()!.signOut() //Cerrar sesión
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondVC =   storyboard.instantiateViewController(withIdentifier: "Vista1") as! ViewController
        self.navigationController!.pushViewController(secondVC, animated: true) //Saltar a la vista de inicio de sesión
    }
    
    //Número de secciones
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //Número de filas en cada renglón
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mistiendas.tiendas.count
    }
    
    //Lo que se muestra en cada celda
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        
        cell.textLabel!.text = self.mistiendas.tiendas[indexPath.row][0] //Mostrar el nombre de la tienda
        
        if (self.mistiendas.tiendas[indexPath.row][2] == "1"){ //Si la tienda está seleccionada por el usuario
        
            cell.accessoryType = UITableViewCellAccessoryType.checkmark //Mostrar checkmark
            
        }else{ //Tienda no seleccionada por el usuario
            
            cell.accessoryType = UITableViewCellAccessoryType.none //No se añade nada
            
        }
        
        return cell
    }
    
    //Cuando el usuario seleccione una celda
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (self.mistiendas.tiendas[indexPath.row][2] == "1"){ //Si la tienda está seleccionada por el usuario
            
            self.mistiendas.switchState(position: indexPath.row, state: "0") //Cambiar estado a no seleccionada
            
            borrarTiendaDeBBDD(position: indexPath.row) //Borrar tienda de la base de datos
            
            tableView.reloadData() //Recargar la tabla
            
        }else{ //Tienda no seleccionada por el usuario
            
            self.mistiendas.switchState(position: indexPath.row, state: "1") //Cambiar estado a seleccionada
            
            addTiendaABBDD(position: indexPath.row) //Añadir tienda a la la base de datos
            
            //No hace falta recargar, ya que al añadir la tienda a la base de datos se va a ejecutar la actualización de tiendas activas y con ello la actualización de la tabla
            
        }
        
    }
    
    //Borrar tienda de la base de datos
    func borrarTiendaDeBBDD(position: Int){
        
        ref.child("users").child(userID!).child("tiendas").child(self.mistiendas.tiendas[position][3]).child("major").removeValue(completionBlock: { (error, ref) in
            if error != nil {
                print("error \(error)")
            }
        })
        
        self.mistiendas.guardarKey(position: position, key: "0")
    }
    
    //Añadir tienda a la base de datos
    func addTiendaABBDD(position: Int){
        
        let key = ref.child("users").child(userID!).child("tiendas").childByAutoId().key //Generar key
        self.mistiendas.guardarKey(position: position, key: key) //Guardar key
        
        let post = ["major": self.mistiendas.tiendas[position][1] ]
        let childUpdates = ["/users/\(userID!)/tiendas/\(key)": post]
        ref.updateChildValues(childUpdates)
        
    }
    
    //Poner título a la tabla
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "TIENDAS:"
    }

}
