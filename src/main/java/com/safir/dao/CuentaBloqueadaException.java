package com.safir.dao;

import java.time.Instant;

/**
 * Se lanza cuando una cuenta está bloqueada temporalmente por exceso
 * de intentos fallidos de inicio de sesión (RNF-03).
 */
public class CuentaBloqueadaException extends Exception {

    private final Instant bloqueadoHasta;

    public CuentaBloqueadaException(Instant bloqueadoHasta) {
        super("Cuenta bloqueada hasta " + bloqueadoHasta);
        this.bloqueadoHasta = bloqueadoHasta;
    }

    public Instant getBloqueadoHasta() {
        return bloqueadoHasta;
    }

    /** Minutos que faltan para el desbloqueo, redondeados hacia arriba (mínimo 1). */
    public long minutosRestantes() {
        long segundos = bloqueadoHasta.getEpochSecond() - Instant.now().getEpochSecond();
        return Math.max(1, (segundos + 59) / 60);
    }
}
