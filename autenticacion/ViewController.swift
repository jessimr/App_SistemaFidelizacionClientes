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
        
        //Para que el teclado se esconda cuando se pulsa intro es necesario lo siguiente:
        self.nombreUsuario.delegate = self
        self.claveUsuario.delegate = self
        
        super.viewDidLoad()
        
        //Eliminar el botón de "back"
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        //Comprobar si hay algún usuario con la sesión iniciada, y en ese caso cargar la siguiente vista
        if (FIRAuth.auth()?.currentUser) != nil {
            self.performSegue(withIdentifier: "show1", sender: self)
        }
        
 
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func pulsaRegistrarse(_ sender: Any) {
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
                        self.showMessagePrompt("El campo contraseña está vacío")
                    }
                }
            } else {
                self.showMessagePrompt("El campo email está vacío")
            }
        }

    }
    
    @IBAction func pulsaInicioSesion(_ sender: Any) {
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
            self.showMessagePrompt("Rellene los campos Usuario y Contraseña")
        }

    }
    
    @IBAction func pulsaInicioGoogle(_ sender: Any) {
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }
    
    //Esconder teclado cuando se pulsa fuera (no funciona con el scroll)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //Esconder teclado cuando se da a intro
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nombreUsuario.resignFirstResponder()
        claveUsuario.resignFirstResponder()
        return (true)
    }
    
    @IBAction func pulsaInicioFacebook(_ sender: Any) {
        let loginManager = FBSDKLoginManager()
        loginManager.logOut() //Importante sino da error (com.facebook.sdk.login error 304)
        loginManager.logIn(withReadPermissions: ["email"], from: self, handler: { (result, error) in
            if let error = error {
                self.showMessagePrompt(error.localizedDescription)
            } else if result!.isCancelled {
                print("FBLogin cancelado")
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
                        self.performSegue(withIdentifier: "show1", sender: self)
                    })
                    // [END_EXCLUDE]
                }
                // [END link_credential]
            } else {
                // [START signin_credential]
                FIRAuth.auth()?.signIn(with: credential) { (user, error) in
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
    
    @IBAction func pulsaRestablecerPassword(_ sender: Any) {
        showTextInputPrompt(withMessage: "Email:") { (userPressedOK, email) in
            if let email = email {
                FIRAuth.auth()?.sendPasswordReset(withEmail: email) { error in
                    if let error = error {
                        // An error happened.
                        self.showMessagePrompt(error.localizedDescription)
                        return
                    } else {
                        // Password reset email sent.
                        self.showMessagePrompt("Le ha sido enviado un correo de restablecimiento de contraseña.")

                    }
                }
            } else {
                self.showMessagePrompt("El campo email está vacío")
            }
        }
    }
    

}

