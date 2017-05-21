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
        
        self.ref = FIRDatabase.database().reference()
        
        //Registrar el nombre del usuario en la base de datos
        self.ref.child("users/\(userID!)/username").setValue(username)

        self.ref2 = self.ref.child("users").child(userID!).child("tiendas")
        
        var arrayKey: [String] = []
        
        //Leer keys asociado a la tiendas guardadas en la base de datos <- necesario para poder borrarlas
        self.ref2.observeSingleEvent(of: .value, with: { snapshot in
                //print(snapshot)
            for child in snapshot.children {
                let key = (child as AnyObject).key!
                print("key: \(key)")
                arrayKey.append(key)
                
            }
            self.ref2.observe(FIRDataEventType.childAdded, with: { (snapshot: FIRDataSnapshot) in //<- Aqui entra cada vez que se añade una tienda a la lista
                let major = (snapshot.value as AnyObject).object(forKey: "major") as! String
                print ("major: \(major)")
                
                //Actualizar tiendas activas (solo al inicio)
                for i in 0 ..< self.mistiendas.tiendas.count{
                    if ((major == self.mistiendas.tiendas[i][1])&&(arrayKey.count > 0)){
                        self.mistiendas.switchState(position: i, state: "1")
                        self.mistiendas.tiendas[i][3] = arrayKey[0]
                        //print("acabo de pasar: \(arrayKey[0])")
                        arrayKey.remove(at: 0)
                    }
                }
                
                //print (self.mistiendas.tiendas)
                
                self.tabla.reloadData()  //Recargar tabla (la lectura de firebase database se hace de manera asíncrona, por eso es necesario ponerlo aqui)
            })
            
        })
        //color tabla
        //self.tabla.backgroundColor = UIColor.green
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   /* override func viewWillAppear(_ animated: Bool) {
        self.tabla.reloadData()
    }*/
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Table view data source
    
    //Número de secciones
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    //Número de filas en cada renglón
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.mistiendas.tiendas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        
        cell.textLabel!.text = self.mistiendas.tiendas[indexPath.row][0]
        
        if (self.mistiendas.tiendas[indexPath.row][2] == "1")
        {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (self.mistiendas.tiendas[indexPath.row][2] == "1")
        {
            self.mistiendas.switchState(position: indexPath.row, state: "0")
            
            //Borrar tienda de la base de datos
            ref.child("users").child(userID!).child("tiendas").child(self.mistiendas.tiendas[indexPath.row][3]).child("major").removeValue(completionBlock: { (error, ref) in
                if error != nil {
                    print("error \(error)")
                }
            })
            self.mistiendas.tiendas[indexPath.row][3] = "0"
            
            tableView.reloadData()
            
        }
        else
        {
            //Camia estado de la tienda
            self.mistiendas.switchState(position: indexPath.row, state: "1")
            
            //Añadir tienda a la la base de datos
            let key = ref.child("users").child(userID!).child("tiendas").childByAutoId().key
            self.mistiendas.tiendas[indexPath.row][3] = key
            //self.arrayKey.append(key)
            //print("añado tienda pos \(self.n)")
            //print(self.arrayKey)
            let post = ["major": self.mistiendas.tiendas[indexPath.row][1] ]
            let childUpdates = ["/users/\(userID!)/tiendas/\(key)": post]
            ref.updateChildValues(childUpdates)
        }
        
    }
    
    /*func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }*/
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Lista de tiendas:"
    }

}
