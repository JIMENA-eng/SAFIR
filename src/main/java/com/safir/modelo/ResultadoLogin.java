package com.safir.modelo;

import java.util.Map;

/**
 * Resultado de un intento de inicio de sesión.
 *
 * EXITO                  -> credenciales correctas; "usuario" trae los datos de sesión.
 * CREDENCIALES_INVALIDAS -> usuario inexistente, cuenta no activa o contraseña errónea.
 *                           Si la cuenta existe, "intentosRestantes" dice cuántos le quedan
 *                           antes del bloqueo (-1 si no aplica).
 * BLOQUEADO              -> la cuenta está bloqueada; "segundosBloqueo" indica la espera.
 */
public final class ResultadoLogin {

    public enum Estado { EXITO, CREDENCIALES_INVALIDAS, BLOQUEADO }

    private final Estado estado;
    private final Map<String, Object> usuario;
    private final int intentosRestantes;
    private final int segundosBloqueo;

    private ResultadoLogin(Estado estado, Map<String, Object> usuario,
                           int intentosRestantes, int segundosBloqueo) {
        this.estado = estado;
        this.usuario = usuario;
        this.intentosRestantes = intentosRestantes;
        this.segundosBloqueo = segundosBloqueo;
    }

    public static ResultadoLogin exito(Map<String, Object> usuario) {
        return new ResultadoLogin(Estado.EXITO, usuario, -1, 0);
    }

    public static ResultadoLogin invalido() {
        return new ResultadoLogin(Estado.CREDENCIALES_INVALIDAS, null, -1, 0);
    }

    public static ResultadoLogin invalido(int intentosRestantes) {
        return new ResultadoLogin(Estado.CREDENCIALES_INVALIDAS, null, intentosRestantes, 0);
    }

    public static ResultadoLogin bloqueado(int segundos) {
        return new ResultadoLogin(Estado.BLOQUEADO, null, 0, Math.max(1, segundos));
    }

    public Estado getEstado()               { return estado; }
    public Map<String, Object> getUsuario() { return usuario; }
    public int getIntentosRestantes()       { return intentosRestantes; }
    public int getSegundosBloqueo()         { return segundosBloqueo; }
}