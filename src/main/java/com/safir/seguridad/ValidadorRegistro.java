package com.safir.seguridad;

import java.util.regex.Pattern;

/** Reglas de validación del registro y del inicio de sesión (correo / teléfono). */
public final class ValidadorRegistro {

    private static final Pattern CORREO =
            Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");
    private static final Pattern USUARIO =
            Pattern.compile("^[A-Za-z0-9_.]{3,30}$");

    private ValidadorRegistro() {}

    /** Si el texto contiene "@" se trata como correo; si no, como teléfono. */
    public static boolean esCorreo(String valor) {
        return valor != null && valor.contains("@");
    }

    public static boolean correoValido(String correo) {
        return correo != null && correo.length() <= 254
                && CORREO.matcher(correo.trim()).matches();
    }

    /**
     * Devuelve el teléfono en formato internacional (+51999888777) o null si
     * no es válido. Sin código de país se asume Perú (9 dígitos que empiezan en 9).
     */
    public static String normalizarTelefono(String valor) {
        if (valor == null) return null;
        String s = valor.replaceAll("[\\s\\-().]", "");
        if (s.startsWith("00")) s = "+" + s.substring(2);
        if (!s.startsWith("+")) {
            if (!s.matches("9\\d{8}")) return null;
            s = "+51" + s;
        }
        return s.matches("\\+[1-9]\\d{7,14}") ? s : null;
    }

    public static boolean usuarioValido(String usuario) {
        return usuario != null && USUARIO.matcher(usuario.trim()).matches();
    }

    /** Mensaje de error de la contraseña, o null si cumple todas las reglas. */
    public static String errorClave(String clave) {
        if (clave == null || clave.length() < 8) {
            return "La contraseña debe tener al menos 8 caracteres.";
        }
        if (clave.length() > 72) {
            return "La contraseña admite hasta 72 caracteres.";
        }
        if (!clave.chars().anyMatch(Character::isUpperCase)) {
            return "La contraseña debe incluir al menos una letra mayúscula.";
        }
        if (tieneNumerosSeguidos(clave)) {
            return "No uses números seguidos (12345678, 9876) ni repetidos (1111).";
        }
        return null;
    }

    /** 4 o más dígitos consecutivos ascendentes, descendentes o repetidos. */
    static boolean tieneNumerosSeguidos(String c) {
        int asc = 1, desc = 1, rep = 1;
        for (int i = 1; i < c.length(); i++) {
            char a = c.charAt(i - 1), b = c.charAt(i);
            if (Character.isDigit(a) && Character.isDigit(b)) {
                asc  = (b == a + 1) ? asc + 1  : 1;
                desc = (b == a - 1) ? desc + 1 : 1;
                rep  = (b == a)     ? rep + 1  : 1;
            } else {
                asc = desc = rep = 1;
            }
            if (asc >= 4 || desc >= 4 || rep >= 4) return true;
        }
        return false;
    }

    /** 0 = débil, 1 = media, 2 = fuerte (misma lógica que el JavaScript de registro.jsp). */
    public static int fuerza(String c) {
        if (c == null) return 0;
        int p = 0;
        if (c.length() >= 8) p++;
        if (c.length() >= 12) p++;
        if (c.chars().anyMatch(Character::isUpperCase)
                && c.chars().anyMatch(Character::isLowerCase)) p++;
        if (c.chars().anyMatch(Character::isDigit)) p++;
        if (c.chars().anyMatch(ch -> !Character.isLetterOrDigit(ch))) p++;
        return p <= 2 ? 0 : (p == 3 ? 1 : 2);
    }
}