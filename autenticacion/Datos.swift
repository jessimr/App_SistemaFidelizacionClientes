//
//  Datos.swift
//  autenticacion
//
//  Created by JESSICA MENDOZA RUIZ on 22/03/2017.
//  Copyright © 2017 JESSICA MENDOZA RUIZ. All rights reserved.
//

import Foundation
import UIKit

class ColeccionDeTiendas {
    //Conterido Array (nombre_tienda, major, estado, key(para poder borrar las tiendas de la base de datos))
    var tiendas: [[String]] = [["Zara", "100", "0", "0" ],
                                ["Mango", "101", "0", "0"],
                                ["Pull&Bear", "102", "0", "0"],
                                ["Stradivarius", "103", "0", "0"],
                                ["Blanco", "104", "0", "0"],
                                ["Springfield", "105", "0", "0"],
                                ["Catchalot", "106", "0", "0"],
                                ["Marypaz", "107", "0", "0"],
                                ["Tezenis", "108", "0", "0"],
                                ["Calcedonia", "109", "0", "0"],
                                ["Oysho", "110", "0", "0"],
                                ["Parfois", "111", "0", "0"],
                                ["Misako", "112", "0", "0"]]
    
    func switchState (position: Int, state: String){
        tiendas[position][2] = state
    }
}
