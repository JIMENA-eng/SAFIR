package com.safir.seguridad;

import org.mindrot.jbcrypt.BCrypt;

public class PasswordUtil {

    public static String hash(String clave) {
        return BCrypt.hashpw(clave, BCrypt.gensalt(12));
    }

    public static boolean verificar(String clave, String hash) {
        return BCrypt.checkpw(clave, hash);
    }
}