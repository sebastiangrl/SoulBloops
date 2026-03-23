package ui;

import h2d.Object;

/**
	Puntaje, Bloop Coins y botones.
**/
class HUD extends Object {
	public function new(?parent:h2d.Object) {
		super(parent);
		// -----------------------------------------------------------------
		// AdMob — banner inferior (no intrusivo)
		// -----------------------------------------------------------------
		// Tras montar el layout, disparar carga async del banner; el SDK
		// invocará onLoaded / onError en otro hilo o callback — aplicar
		// visibilidad y posición aquí cuando llegue el evento.
		//
		// IAP (extension-iap): compras y restore devuelven resultado en callback;
		// actualizar estado “No Ads” / saldo de Bloop Coins en el hilo principal
		// cuando el plugin notifique éxito o error (no bloquear UI).
	}
}
