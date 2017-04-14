//
//  ViewController.swift
//  autenticacion
//
//  Created by JESSICA MENDOZA RUIZ on 15/03/2017.
//  Copyright © 2017 JESSICA MENDOZA RUIZ. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit


class ViewController: UIViewController, UITextFieldDelegate, GIDSignInUIDelegate {

    @IBOutlet weak var nombreUsuario: UITextField!
    @IBOutlet weak var claveUsuario: UITextField!
    
    var handle: FIRAuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        
        print("-------------------viewDidLoad------------------")
        
        //Para que el teclado se esconda cuando se pulsa intro es necesario lo siguiente:
        self.nombreUsuario.delegate = self
        self.claveUsuario.delegate = self
        
        //let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //let secondVC =   storyboard.instantiateViewController(withIdentifier: "Vista2") as! VistaSesionIniciada
        
        super.viewDidLoad()
        
        //Comprobar si hay algún usuario con la sesión iniciada, y en ese caso cargar la siguiente vista
        
       /*FIRAuth.auth()?.addStateDidChangeListener { auth, user in
           /* if let user = user {
                // User is signed in.
                
                /*DispatchQueue.main.async(){
                    self.performSegue(withIdentifier: "show1", sender: self)
                }*/
                
                
                self.navigationController!.pushViewController(secondVC, animated: true)
                
                
                //self.navigationController!.popViewController(animated: true)
                
 
            } else {
                // No user is signed in.
                super.viewDidLoad()
            }*/
        
        }*/
        
        if (FIRAuth.auth()?.currentUser) != nil {
            self.performSegue(withIdentifier: "show1", sender: self)
        }
        
 
    }

    override func didReceiveMemoryWarning() {
        print("-------------------didReceiveMemoryWarning------------------")
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*override func viewWillAppear(_ animated: Bool) {
        print("-------------------viewWillAppear------------------")
        super.viewWillAppear(animated)
        // [START auth_listener]
        handle = FIRAuth.auth()?.addStateDidChangeListener() { (auth, user) in
            print("-------------------usuario: \(user)------------------")
           /* if user != nil {
                /*let storyboard = UIStoryboard(name: "Main", bundle: nil)
                 let secondVC =   storyboard.instantiateViewController(withIdentifier: "Vista2") as! VistaSesionIniciada
                 self.navigationController!.pushViewController(secondVC, animated: true)*/
                DispatchQueue.main.async(){
                    self.performSegue(withIdentifier: "show1", sender: self)
                }
            }*/
        }
        // [END auth_listener]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("-------------------viewWillDisappear------------------")
        super.viewWillDisappear(animated)
        FIRAuth.auth()?.removeStateDidChangeListener(handle!)
    }*/
    
    //Para que no se muestre la navigation bar
    override public func viewWillAppear(_ animated: Bool) {
        print("-------------------viewWillAppear------------------")
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        print("-------------------viewWillDisappear------------------")
        self.navigationController?.isNavigationBarHidden = false
        super.viewWillDisappear(animated)
    }
    

    @IBAction func pulsaRegistrarse(_ sender: Any) {
        print("-------------------pulsaRegistrarse------------------")
        showTextInputPrompt(withMessage: "Email:") { (userPressedOK, email) in
            if let email = email {
                self.showTextInputPrompt(withMessage: "Contraseña:") { (userPressedOK, password) in
                    if let password = password {
                        self.showSpinner({
                            // Crear usuario
                            FIRAuth.auth()?.createUser(withEmail: email, password: password) { (user, error) in
                                // [START_EXCLUDE]
                                self.hideSpinner({
                                    if let error = error {
                                        self.showMessagePrompt(error.localizedDescription)
                                        return
                                    }
                                    print("\(user!.email!) created")
                                    self.performSegue(withIdentifier: "show1", sender: self)
                                })
                                // [END_EXCLUDE]
                            }
                            // [END create_user]
                        })
                    } else {
                        self.showMessagePrompt("password can't be empty")
                    }
                }
            } else {
                self.showMessagePrompt("email can't be empty")
            }
        }

    }
    
    @IBAction func pulsaInicioSesion(_ sender: Any) {
        print("-------------------pulsaInicioSesion------------------")
        if let email = self.nombreUsuario.text, let password = self.claveUsuario.text {
            showSpinner({
                // [START headless_email_auth]
                FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
                    // [START_EXCLUDE]
                    self.hideSpinner({
                        if let error = error {
                            self.showMessagePrompt(error.localizedDescription)
                            return
                        }
                        self.performSegue(withIdentifier: "show1", sender: self)
                    })
                    // [END_EXCLUDE]
                }
                // [END headless_email_auth]
            })
        } else {
            self.showMessagePrompt("email/password can't be empty")
        }

    }
    
    @IBAction func pulsaInicioGoogle(_ sender: Any) {
        print("-------------------pulsaInicioGoogle------------------")
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }
    
    //Esconder teclado cuando se pulsa fuera (no funciona con el scroll)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("-------------------touchesBegan------------------")
        self.view.endEditing(true)
    }
    
    //Esconder teclado cuando se da a intro
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("-------------------textFieldShouldReturn------------------")
        nombreUsuario.resignFirstResponder()
        claveUsuario.resignFirstResponder()
        return (true)
    }
    
    @IBAction func pulsaInicioFacebook(_ sender: Any) {
        print("-------------------pulsaInicioFacebook------------------")
        let loginManager = FBSDKLoginManager()
        loginManager.logOut() //Importante sino da error (com.facebook.sdk.login error 304)
        loginManager.logIn(withReadPermissions: ["email"], from: self, handler: { (result, error) in
            if let error = error {
                self.showMessagePrompt(error.localizedDescription)
            } else if result!.isCancelled {
                print("FBLogin cancelled")
            } else {
                // [START headless_facebook_auth]
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                // [END headless_facebook_auth]
                self.firebaseLogin(credential)
            }
        })
    }
    
    //Inicio Sesion con credenciales
    func firebaseLogin(_ credential: FIRAuthCredential) {
        print("-------------------firebaseLogin------------------")
        showSpinner({
            if let user = FIRAuth.auth()?.currentUser {
                // [START link_credential]
                user.link(with: credential) { (user, error) in
                    // [START_EXCLUDE]
                    self.hideSpinner({
                        if let error = error {
                            self.showMessagePrompt(error.localizedDescription)
                            return
                        }
                        //self.tableView.reloadData()
                        print("-------------Hay una sesión de google/fb iniciada-----------")
                        self.performSegue(withIdentifier: "show1", sender: self)
                    })
                    // [END_EXCLUDE]
                }
                // [END link_credential]
            } else {
                // [START signin_credential]
                FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                    print("------------- No hay una sesión de google/fb iniciada-----------")
                    // [START_EXCLUDE]
                    self.hideSpinner({
                        // [END_EXCLUDE]
                        if let error = error {
                            // [START_EXCLUDE]
                            self.showMessagePrompt(error.localizedDescription)
                            // [END_EXCLUDE]
                            return
                        }
                        // [END signin_credential]
                        // Merge prevUser and currentUser accounts and data
                        // ...
                        self.performSegue(withIdentifier: "show1", sender: self)
                    })
                }
            }
        })
    }
    
    

}

