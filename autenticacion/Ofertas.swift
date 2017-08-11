//
//  Ofertas.swift
//  autenticacion
//
//  Created by JESSICA MENDOZA RUIZ on 27/05/2017.
//  Copyright © 2017 JESSICA MENDOZA RUIZ. All rights reserved.
//

import UIKit
import Firebase

class Ofertas: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tabla: UITableView!
    
    var ref: FIRDatabaseReference!
    var ref2: FIRDatabaseReference!
    
    let userID = FIRAuth.auth()?.currentUser?.uid
    
    var bonos: [String] = []
    var keys: [String] = []
    var tiendas: [String] = []
    var fechas: [String] = []
    var primeraVez = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Configurar boton de cerrar sesision
        configLogOutButton();
        
        self.ref = FIRDatabase.database().reference()
        self.ref2 = self.ref.child("users").child(userID!).child("ofertas")
        
        tabla.rowHeight = 120 //Tamaño de las celdas
        
        leerOfertasDeLaBD() //Leer ofertas de la base de datos del usuario
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func leerOfertasDeLaBD(){
        
        //Leer keys asociado a las ofertas guardadas en la base de datos <- necesario para poder borrarlas
            self.ref2.observe(FIRDataEventType.childAdded, with: { (snapshot: FIRDataSnapshot) in //<- Aqui entra cada vez que se añade una oferta a la lista
                self.bonos.append((snapshot.value as AnyObject).object(forKey: "bono") as! String) //Oferta
                self.tiendas.append((snapshot.value as AnyObject).object(forKey: "nombre") as! String) //Tienda que la ofrece
                self.fechas.append((snapshot.value as AnyObject).object(forKey: "validez") as! String) //Periodo de validez de la oferta
                self.keys.append((snapshot as AnyObject).key!) //key de la oferta
                self.tabla.reloadData()  //Recargar tabla
            })
    }
    
    //Configurar el botón de cerrar sesión
    func configLogOutButton(){
        
        // Seleccionar imagen
        let buttonCerrarSIcon = UIImage(named: "Cerrar sesion")
        
        //Añadir barbutton
        let cerrarSButton: UIBarButtonItem = UIBarButtonItem(title: "Salir", style: UIBarButtonItemStyle.plain, target: self, action: #selector(Ofertas.pulsaCerrarSesion))
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
        return self.bonos.count
    }
    
    //Lo que se muestra en cada celda
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CeldaTablaOfertasTableViewCell
        cell.promocion.text = self.bonos[indexPath.row] //Oferta
        cell.nombre.text = self.tiendas[indexPath.row] //Nombre de la tienda
        cell.validez.text = "Válido hasta: " + self.fechas[indexPath.row] //Perido de validez
        return cell
    }
    
    //Poner título a la tabla
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "OFERTAS:"
    }
    
    //Añadir botón de eliminar y definir acción a realizar
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            //Borrar oferta de la base de datos del usuario
            ref.child("users").child(userID!).child("ofertas").child(self.keys[indexPath.row]).removeValue(completionBlock: { (error, ref) in
                if error != nil {
                    print("error \(error)")
                }
                
                //Borrar items de la celda
                self.bonos.remove(at: indexPath.row)
                self.keys.remove(at: indexPath.row)
                self.tiendas.remove(at: indexPath.row)
                self.fechas.remove(at: indexPath.row)
                
                //Borrar celda de la tabla
                self.tabla.deleteRows(at: [indexPath], with: .fade)
                
            })
        }
    }
    
    //Dar nombre al botón de eliminar
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Eliminar"
    }
    
}
