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
        
        tabla.rowHeight = 120
        
        leerOfertasDeLaBD()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func leerOfertasDeLaBD(){
        
        //Leer keys asociado a las ofertas guardadas en la base de datos <- necesario para poder borrarlas
            self.ref2.observe(FIRDataEventType.childAdded, with: { (snapshot: FIRDataSnapshot) in //<- Aqui entra cada vez que se añade una oferta a la lista
                self.bonos.append((snapshot.value as AnyObject).object(forKey: "bono") as! String)
                self.tiendas.append((snapshot.value as AnyObject).object(forKey: "nombre") as! String)
                self.fechas.append((snapshot.value as AnyObject).object(forKey: "validez") as! String)
                self.keys.append((snapshot as AnyObject).key!)
                print ("bonos: \(self.bonos)")
                print("tiendas: \(self.tiendas)")
                print("fechas: \(self.fechas)")
                print("key: \(self.keys)")
                self.tabla.reloadData()  //Recargar tabla (la lectura de firebase database se hace de manera asíncrona, por eso es necesario ponerlo aqui)
            })
        
    }
    
    func configLogOutButton(){
        // Seleccionar imagen
        let buttonCerrarSIcon = UIImage(named: "Cerrar sesion")
        
        //Añadir barbutton
        let cerrarSButton: UIBarButtonItem = UIBarButtonItem(title: "Salir", style: UIBarButtonItemStyle.plain, target: self, action: #selector(Ofertas.pulsaCerrarSesion))
        cerrarSButton.image = buttonCerrarSIcon
        self.tabBarController?.navigationItem.setLeftBarButton(cerrarSButton, animated: true)
    }
    
    func pulsaCerrarSesion(sender:UIButton) {
        try! FIRAuth.auth()!.signOut()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondVC =   storyboard.instantiateViewController(withIdentifier: "Vista1") as! ViewController
        self.navigationController!.pushViewController(secondVC, animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    //Número de secciones
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    //Número de filas en cada renglón
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.bonos.count
    }
    
/*func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        cell.textLabel!.text = self.bonos[indexPath.row]
        return cell
    }*/
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CeldaTablaOfertasTableViewCell
        cell.promocion.text = self.bonos[indexPath.row]
        cell.nombre.text = self.tiendas[indexPath.row]
        cell.validez.text = "Válido hasta: " + self.fechas[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "OFERTAS:"
    }
    
    // this method handles row deletion
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            //borrarlo de la base de datos
            ref.child("users").child(userID!).child("ofertas").child(self.keys[indexPath.row]).removeValue(completionBlock: { (error, ref) in
                if error != nil {
                    print("error \(error)")
                }
                
                // remove the item from the data model
                self.bonos.remove(at: indexPath.row)
                self.keys.remove(at: indexPath.row)
                self.tiendas.remove(at: indexPath.row)
                self.fechas.remove(at: indexPath.row)
                
                // delete the table view row
                self.tabla.deleteRows(at: [indexPath], with: .fade)
                
            })
            
        }
    }
    //dar nombre al boton
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Eliminar"
    }
    
}
