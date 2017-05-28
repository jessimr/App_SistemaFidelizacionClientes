//
//  Ofertas.swift
//  autenticacion
//
//  Created by JESSICA MENDOZA RUIZ on 27/05/2017.
//  Copyright © 2017 JESSICA MENDOZA RUIZ. All rights reserved.
//

import UIKit
import Firebase

class Ofertas: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Configurar boton de cerrar sesision
        configLogOutButton();
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "OFERTAS:"
    }
}
