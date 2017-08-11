
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
 /*exports.helloWorld = functions.https.onRequest((request, response) => {
  response.send("Hello from Firebase!");
  console.log('Hace algo');
 });*/
'use strict';

//const functions = require('firebase-functions');
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');
const moment = require('moment-timezone');

admin.initializeApp(functions.config().firebase);

exports.validarUsuario = functions.database.ref('/users/{pushId}/seguridad').onWrite(event => {

	const original = event.data.val();
	console.log('UID', event.params.pushId, 'HMAC enviado por la app', original);
	const uid = event.params.pushId;
	var orig = original.replace(/\s+/g, ''); //Eliminar los espacios de la cadena original

	return calcularHMAC(uid).then(resul => { //Calcular función HMAC

		if (resul.trim()  === orig.trim()){ //Si MAC calculado y MAC original son iguales

			console.log('Coinciden');

			return sendCouponViaFCM(uid); //Enviar cupon

		}else{ //Si MAC calculado y MAC original no son iguales

			console.log('No coinciden, hacer segunda prueba', 'calculado', resul, 'original', orig);

			sleep(3000, function() { //Esperar un 3 segundos y volver a comprobar 

				return admin.database().ref(`/users/${uid}/seguridad`).once("value").then(function(snapshot) { //Coger valor HMAC de la base de datos

					var original2 = snapshot.val();
					var orig2 = original2.replace(/\s+/g, ''); //Eliminar los espacios de la cadena original

					return calcularHMAC(uid).then(resul2 =>{ //Vuelve a calcular HMAC

						if (resul2.trim()  === orig2.trim()){ //Si MAC calculado y MAC original son iguales

							console.log('Coinciden en la segunda prueba');

							return sendCouponViaFCM(uid); //Enviar cupon

						}else{

							console.log('No coinciden', 'calculado', resul2, 'original', orig2);

						}
					});

				});

			});
		}
  	});
});

 //Sólo lo debería enviar si la tienda está en la lista de tiendas que el usuario quiere ver y si no ha recibido ya esta oferta
function sendCouponViaFCM(uid) {

    //Mirar si el iBeacon ultimo está en la lista de tiendas del usuario
    return admin.database().ref(`/users/${uid}/iBeacon`).once("value").then(function(snapshot) { //Coge iBeacon

    	var iBeacon = snapshot.val();

    	return comprobarLista(uid,iBeacon).then(pertenece => { //Comprobar si el iBeacon se corresponde a alguna tienda de la lista

			if (pertenece == true){

				//Registrar posición validada
				registrarPosicion(uid,iBeacon);

				//Comporbar si hay oferta
				return comprobarOferta(uid,iBeacon).then(hay =>{

					if (hay == true){

						//Mirar si el usuario tiene la oferta, en caso negativo enviar notificación
						return comprobarSiUsuarioTieneOferta(uid,iBeacon);

					}else{

						console.log('No hay oferta');

					}
				});

			}else{ 

				console.log('Tienda no está en la lista', iBeacon);

			} 

		});

    });

} 

//Obtener token                                                          
function getDeviceTokens(uid) {

    console.log('Entra en obtenerToken');

    return admin.database().ref(`/users/${uid}/tokens`).once("value").then(function(snapshot) { //Lee de la base de datos

    	var data = snapshot.val();
    	console.log('Token del usuario', data);
    	return data;

     });
}

//Calcular función HMAC
function calcularHMAC(uid) {

	
	return admin.database().ref(`/users/${uid}/iBeacon`).once("value").then(function(snapshot) { //Coger parametro iBeacon de la base de datos

    	var iBeacon = snapshot.val();

		//Definir clave y algoritmo hash a utilizar
		var clave = new Buffer('0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b', 'hex');
		const hmac = crypto.createHmac('sha1', clave);

		//Coger hora y fecha actual
		var date = new Date();  
		var hora = (date.getUTCHours()+2)%24;

		//Como hay un desfase de dos horas con la hora que nos proporciona la función getUTCHours, se suma un día cuando son las 12 y la 1 de la madrugada 
		if((hora === 0)||(hora === 1)){
			var dia = date.getUTCDate()+1;
		}else{
			var dia = date.getUTCDate();
		}

		//Datos de los cuales vamos a calcular el HMAC
		var datos = iBeacon+date.getUTCFullYear().toString()+(date.getUTCMonth()+1).toString()+dia.toString()+hora.toString()+date.getUTCMinutes().toString(); 
		console.log('Datos sobre los que calculare la HMAC (iBeacon+Fecha+Hora)', datos); 
	
		//Calcular HMAC (resultado en hexadecimal)
		hmac.update(datos); //le paso de que quiero hacer el HMAC
		var hmac_hex = hmac.digest('hex');

		console.log('HMAC calculada por la función', hmac_hex);

		return hmac_hex;
	});
}

//Esperar 
function sleep(time, callback) {

    var stop = new Date().getTime();

    while(new Date().getTime() < stop + time) {
        ;
    }

    callback();
}

//Comprobar si el iBeacon pertenece a alguna tienda de la lista del usuario
function comprobarLista(uid,iBeacon){

	return admin.database().ref(`/users/${uid}/tiendas`).once("value").then(function(snapshot) { //Coge lista de tiendas

		var elem = snapshot.val();

		var pertenece = false;

		for(var key in elem){

			if (elem.hasOwnProperty(key)){

				var major = elem[key];
				var valor = major['major'];
				console.log('Major', valor);

				if(iBeacon.indexOf(valor) > -1) { //Si el iBeacon pertenece a alguna tienda de la lista

					pertenece = true;
					console.log('Tienda en la lista', iBeacon, valor);
					break;

				}

			}
		}

		return pertenece;
	});
}

//Comprobar si hay alguna oferta que ofrecer al usuario
function comprobarOferta(uid,iBeacon){

	return admin.database().ref(`/promociones/${iBeacon}`).once("value").then(function(snapshot) { 

		var enviar = snapshot.val().enviar;

        console.log('Enviar', enviar);

        //Coger hora y fecha actual
		var date = new Date();  
		var hora = (date.getUTCHours()+2)%24;

		var hay = false;
        
        if (enviar.trim() === "mañana".trim()){ //Si enviar es igual a mañana y son entre las 10 y las 14 -> hay = true

        	var inicio = new Date();
			inicio.setHours(10,0,0); // 10.00 am
			var fin = new Date();
			fin.setHours(14,0,0); // 2.00 pm

        	if(hora >= inicio.getUTCHours() && hora < fin.getUTCHours()){
        		console.log('Horario de mañana');
        		hay = true;
        	}

        } else if (enviar.trim() === "tarde".trim()){ //Si enviar es igual a tarde y son entre las 17 y las 21 -> hay = true

        	var inicio = new Date();
			inicio.setHours(17,0,0); // 5.00 pm
			var fin = new Date();
			fin.setHours(21,0,0); // 9.00 pm

        	if(hora >= inicio.getUTCHours() && hora < fin.getUTCHours()){
        		console.log('Horario de tarde');
        		hay = true;
        	}

        }
		return hay;
	});
}

//Comprobar si el usuario ya ha recibido la oferta, en caso negativo enviarla
function comprobarSiUsuarioTieneOferta(uid,iBeacon,token){

	return admin.database().ref(`/promociones/${iBeacon}`).once("value").then(function(snapshot) { 

		var nombre = snapshot.val().nombre;
		var oferta = snapshot.val().oferta;
		var validez = snapshot.val().validez;

		console.log('Nombre', nombre, 'Oferta', oferta, 'Validez', validez);
		
		// Notification details.
		let payload = {
			notification: {
				title: nombre,
				body: oferta,
				sound: 'default'
			}
		};

		return admin.database().ref(`/users/${uid}/ofertas`).once("value").then(function(snapshot) { //Mirar si el usuario ya tiene la oferta

			var ofertas = snapshot.val();

			var tiene = false;

			for(var key in ofertas){

				if (ofertas.hasOwnProperty(key)){ 

					var descuento = ofertas[key]['bono'];
					var name = ofertas[key]['nombre'];
					console.log('Bono', descuento, 'Nombre', name);

					var bolbody = payload['notification']['body'].trim() === descuento.trim();
					var boltitle = payload['notification']['title'].trim() === name.trim();
					console.log (bolbody, boltitle)

					if(bolbody && boltitle){ //Si el título y en cuerpo de la notificación coincide con alguna oferta de la lista del usuario

						console.log("Ya tiene el descuento");
						tiene = true;
						break;

					}
					
				}
			} 

			if (tiene == false){ //El usuario no tiene la oferta

				console.log("No tiene el descuento");
				admin.database().ref('users/' + uid +'/ofertas').push({bono: payload['notification']['body'], validez: validez, nombre: nombre}); //Guardo la oferta en la base de datos del usuario

				return getDeviceTokens(uid).then(tokens => { //Coger el token

    				if (tokens.length > 0) {

						return admin.messaging().sendToDevice(tokens, payload).then(function(response) { //Enviar notificación

							console.log("Mensaje enviado correctamente:", response);

						}).catch(function(error) {

							console.log("Error al enviar el mensaje:", error);

						}); 
					}
				});
			} 
		}); 
	}); 

}

//Registrar la posición validada en la base de datos
function registrarPosicion(uid,iBeacon){

	return admin.database().ref(`/users/${uid}/pseudonimo`).once("value").then(function(snapshot) {

		var pseudonimo = snapshot.val();

		//Coger hora y fecha actual
		var date = new Date();  
		var hora = (date.getUTCHours()+2)%24;

		//Como hay un desfase de dos horas con la hora que nos proporciona la función getUTCHours, se suma un día cuando son las 12 y la 1 de la madrugada 
		if((hora === 0)||(hora === 1)){
			var dia = date.getUTCDate()+1;
		}else{
			var dia = date.getUTCDate();
		}

		//Datos de los cuales vamos a calcular el HMAC
		var fecha = date.getUTCFullYear().toString()+'/'+(date.getUTCMonth()+1).toString()+'/'+dia.toString()+' '+hora.toString()+':'+date.getUTCMinutes().toString(); 

		admin.database().ref('posiciones_validadas/'+ pseudonimo).push({fecha: fecha, iBeacon: iBeacon});

	});
}
