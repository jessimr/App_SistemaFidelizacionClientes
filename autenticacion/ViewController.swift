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
        print("viewDidLoadViewController")//
        
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
    }

    //Cuando el usuario pulse el botón de registrarse
    @IBAction func pulsaRegistrarse(_ sender: Any) {
        showTextInputPrompt(withMessage: "Email:") { (userPressedOK, email) in
            if let email = email {
                self.showTextInputPrompt(withMessage: "Contraseña:") { (userPressedOK, password) in
                    if let password = password {
                        self.showSpinner({
                            // Crear usuario
                            FIRAuth.auth()?.createUser(withEmail: email, password: password) { (user, error) in
                                self.hideSpinner({
                                    if let error = error {
                                        self.showMessagePrompt(error.localizedDescription)
                                        return
                                    }
                                    print("\(user!.email!) cuenta de usuario creada")
                                    self.crearPseudonimo() //Crear pseudónimo
                                    self.performSegue(withIdentifier: "show1", sender: self) //Pasar a la siguiente vista
                                })
                            }
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
    
    //Cuando el usuario pulse el botón de iniciar sesión
    @IBAction func pulsaInicioSesion(_ sender: Any) {
        if let email = self.nombreUsuario.text, let password = self.claveUsuario.text {
            showSpinner({
                //Iniciar sesión de usuario
                FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
                    self.hideSpinner({
                        if let error = error {
                            self.showMessagePrompt(error.localizedDescription)
                            return
                        }
                        self.crearPseudonimo() //Crear pseudónimo
                        self.performSegue(withIdentifier: "show1", sender: self) //Pasar a la siguiente vista
                    })
                }
            })
        } else {
            self.showMessagePrompt("Rellene los campos Usuario y Contraseña")
        }

    }
    
    //Cuando el usuario pulse el botón de iniciar sesión con Google
    @IBAction func pulsaInicioGoogle(_ sender: Any) {
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }
    
    //Esconder teclado cuando se pulsa en cualquier punto de la vista
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //Esconder teclado cuando se da a intro
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nombreUsuario.resignFirstResponder()
        claveUsuario.resignFirstResponder()
        return (true)
    }
    
    //Cuando el usuario pulse el botón de iniciar sesión con Facebook
    @IBAction func pulsaInicioFacebook(_ sender: Any) {
        let loginManager = FBSDKLoginManager()
        loginManager.logOut() //Importante sino da error (com.facebook.sdk.login error 304)
        loginManager.logIn(withReadPermissions: ["email"], from: self, handler: { (result, error) in
            if let error = error {
                self.showMessagePrompt(error.localizedDescription)
            } else if result!.isCancelled {
                print("FBLogin cancelado")
            } else {
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseLogin(credential)
            }
        })
    }
    
    //Inicio Sesion con credenciales (Google o Facebook)
    func firebaseLogin(_ credential: FIRAuthCredential) {
        showSpinner({
            if let user = FIRAuth.auth()?.currentUser { //"Crear" cuenta (primera vez se asocia la cuenta de Google o Facebook a la app)
                user.link(with: credential) { (user, error) in
                    self.hideSpinner({
                        if let error = error {
                            self.showMessagePrompt(error.localizedDescription)
                            return
                        }
                        self.crearPseudonimo() //Crear pseudónimo
                        self.performSegue(withIdentifier: "show1", sender: self) //Pasar a la siguiente vista
                    })
                }
            } else { //Iniciar sesión
                FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                    self.hideSpinner({
                        if let error = error {
                            self.showMessagePrompt(error.localizedDescription)
                            return
                        }
                        self.crearPseudonimo() //Crear pseudónimo
                        self.performSegue(withIdentifier: "show1", sender: self) //Pasar a la siguiente vista
                    })
                }
            }
        })
    }
    
    //Cuando el usuario pulse el botón de reestablecer contraseña
    @IBAction func pulsaRestablecerPassword(_ sender: Any) {
        showTextInputPrompt(withMessage: "Email:") { (userPressedOK, email) in
            if let email = email {
                self.showSpinner({
                    FIRAuth.auth()?.sendPasswordReset(withEmail: email) { error in
                        self.hideSpinner({
                            if let error = error {
                                self.showMessagePrompt(error.localizedDescription)
                                return
                            }
                        })
                        // Password reset email sent.
                        self.showMessagePrompt("Le ha sido enviado un correo de restablecimiento de contraseña.")
                    }
                })
            } else {
                self.showMessagePrompt("El campo email está vacío")
            }
        }
    }
    
    //Crear pseudónimo
    func crearPseudonimo(){
        
        let pseudonimo = randomStringWithLength(len: 10) //Cadena aleatoria de 10 bytes de longitud
        
        print("Pseudónimo: \(pseudonimo)")
        
        let bbdd = FIRDatabase.database().reference() //Referencia a la base de datos
        
        let uid = FIRAuth.auth()?.currentUser?.uid //UID del usuario
        
        bbdd.child("users/\(uid!)/pseudonimo").setValue(pseudonimo) //Guardar pseudónimo en la base de datos del usuario
        
    }
    
    //Generar cadena de caracteres aleatoria
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for _ in 0 ..< len{
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        
        return randomString
    }

}
