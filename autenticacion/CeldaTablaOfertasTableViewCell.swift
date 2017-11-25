//
//  CeldaTablaOfertasTableViewCell.swift
//  autenticacion
//
//  Created by JESSICA MENDOZA RUIZ on 27/06/2017.
//  Copyright © 2017 JESSICA MENDOZA RUIZ. All rights reserved.
//

import UIKit

class CeldaTablaOfertasTableViewCell: UITableViewCell {

    @IBOutlet weak var nombre: UILabel!
    @IBOutlet weak var promocion: UILabel!
    @IBOutlet weak var validez: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //Items o campos que aparecerán en la celda
        nombre.text = ""
        promocion.text = ""
        validez.text = ""
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
