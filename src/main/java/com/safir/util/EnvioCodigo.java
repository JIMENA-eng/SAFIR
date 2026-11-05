package com.safir.util;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

import java.util.Properties;

/**
 * Envío del código de verificación.
 *
 * CORREO: se envía por SMTP si están definidas estas variables (de entorno
 * o propiedades -D de la JVM): SAFIR_SMTP_HOST, SAFIR_SMTP_PORT (587 por
 * defecto), SAFIR_SMTP_USER, SAFIR_SMTP_PASS y SAFIR_SMTP_FROM (opcional;
 * por defecto SAFIR_SMTP_USER). Si no están definidas, el mensaje se imprime
 * en la consola del servidor (modo desarrollo).
 *
 * SMS: por ahora solo se imprime en consola (modo desarrollo).
 *
 * enviar() devuelve false si el correo no pudo enviarse.
 */
public final class EnvioCodigo {

    private EnvioCodigo() {}

    public static boolean enviar(String canal, String destino,
                                 String codigo, int minutos) {
        if ("telefono".equals(canal)) {
            enviarSms(destino, codigo, minutos);
            return true;
        }
        return enviarCorreo(destino, codigo, minutos);
    }

    private static String config(String nombre) {
        String v = System.getenv(nombre);
        if (v == null || v.isBlank()) v = System.getProperty(nombre);
        return (v == null || v.isBlank()) ? null : v.trim();
    }

    private static void enviarSms(String telefono, String codigo, int minutos) {
        String texto = "SAFIR: tu código es " + codigo + " (vence en " + minutos
                + " min). Al ingresarlo confirmas que tu número está activo y "
                + "autorizas el uso de tus datos personales según nuestra "
                + "política de privacidad.";
        System.out.println("=====================================");
        System.out.println("SMS (solo desarrollo) -> " + telefono);
        System.out.println(texto);
        System.out.println("=====================================");
    }

    private static boolean enviarCorreo(String correo, String codigo, int minutos) {
        String asunto = "Tu código de verificación de SAFIR";
        String cuerpo = "Hola,\n\nTu código de verificación es: " + codigo + "\n\n"
                + "Vence en " + minutos + " minutos. Al ingresarlo confirmas tu "
                + "correo y autorizas el uso de tus datos personales según "
                + "nuestra política de privacidad.\n\n"
                + "Si no fuiste tú, ignora este mensaje.\n\nEquipo SAFIR";

        String host = config("SAFIR_SMTP_HOST");
        String usuario = config("SAFIR_SMTP_USER");
        String clave = config("SAFIR_SMTP_PASS");

        if (host == null || usuario == null || clave == null) {
            System.out.println("=====================================");
            System.out.println("CORREO (solo desarrollo, SMTP sin configurar) -> " + correo);
            System.out.println("Asunto: " + asunto);
            System.out.println(cuerpo);
            System.out.println("=====================================");
            return true;
        }

        String puerto = config("SAFIR_SMTP_PORT");
        if (puerto == null) puerto = "587";
        String remitente = config("SAFIR_SMTP_FROM");
        if (remitente == null) remitente = usuario;

        Properties p = new Properties();
        p.put("mail.smtp.host", host);
        p.put("mail.smtp.port", puerto);
        p.put("mail.smtp.auth", "true");
        if ("465".equals(puerto)) {
            p.put("mail.smtp.ssl.enable", "true");
        } else {
            p.put("mail.smtp.starttls.enable", "true");
        }
        p.put("mail.smtp.connectiontimeout", "8000");
        p.put("mail.smtp.timeout", "8000");
        p.put("mail.smtp.writetimeout", "8000");

        Session sesion = Session.getInstance(p, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(usuario, clave);
            }
        });

        try {
            MimeMessage m = new MimeMessage(sesion);
            m.setFrom(new InternetAddress(remitente, "SAFIR", "UTF-8"));
            m.setRecipients(Message.RecipientType.TO, InternetAddress.parse(correo, false));
            m.setSubject(asunto, "UTF-8");
            m.setText(cuerpo, "UTF-8");
            Transport.send(m);
            return true;
        } catch (Exception e) {
            System.err.println("No se pudo enviar el correo a " + correo + ": " + e);
            return false;
        }
    }
}