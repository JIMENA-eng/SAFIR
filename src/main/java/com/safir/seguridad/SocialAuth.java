package com.safir.seguridad;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.util.Base64;

/**
 * OAuth 2.0 "autorización por código" para Google, Facebook y X.
 *
 * Credenciales (variables de entorno o propiedades -D de la JVM):
 *   SAFIR_GOOGLE_ID / SAFIR_GOOGLE_SECRET
 *   SAFIR_FACEBOOK_ID / SAFIR_FACEBOOK_SECRET
 *   SAFIR_X_ID / SAFIR_X_SECRET
 * Un proveedor sin credenciales queda desactivado (no se muestra su botón).
 */
public final class SocialAuth {

    public static final String GOOGLE = "google";
    public static final String FACEBOOK = "facebook";
    public static final String X = "x";

    private static final String FB_VERSION = "v23.0";
    private static final SecureRandom ALEATORIO = new SecureRandom();
    private static final HttpClient HTTP = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(8)).build();

    private SocialAuth() {}

    /** Datos del usuario según el proveedor. correo puede ser null (X no lo da). */
    public static final class Perfil {
        public String uid;
        public String nombre;
        public String correo;
        public boolean correoVerificado;
    }

    public static boolean esProveedor(String p) {
        return GOOGLE.equals(p) || FACEBOOK.equals(p) || X.equals(p);
    }

    private static String valor(String nombre) {
        String v = System.getenv(nombre);
        if (v == null || v.isBlank()) v = System.getProperty(nombre);
        return (v == null || v.isBlank()) ? null : v.trim();
    }

    private static String id(String p) { return valor("SAFIR_" + p.toUpperCase() + "_ID"); }
    private static String secreto(String p) { return valor("SAFIR_" + p.toUpperCase() + "_SECRET"); }

    public static boolean configurado(String p) {
        return esProveedor(p) && id(p) != null && secreto(p) != null;
    }

    // ---------- Valores aleatorios y PKCE ----------

    public static String aleatorio() {
        byte[] b = new byte[32];
        ALEATORIO.nextBytes(b);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    }

    private static String desafioPkce(String verificador) {
        try {
            byte[] h = MessageDigest.getInstance("SHA-256")
                    .digest(verificador.getBytes(StandardCharsets.US_ASCII));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(h);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    // ---------- Paso 1: dirección a la que se envía al usuario ----------

    public static String urlAutorizacion(String p, String redirect,
                                         String state, String verificadorPkce) {
        switch (p) {
            case GOOGLE:
                return "https://accounts.google.com/o/oauth2/v2/auth?" + form(
                        "client_id", id(p), "redirect_uri", redirect,
                        "response_type", "code", "scope", "openid email profile",
                        "state", state, "prompt", "select_account");
            case FACEBOOK:
                return "https://www.facebook.com/" + FB_VERSION + "/dialog/oauth?" + form(
                        "client_id", id(p), "redirect_uri", redirect,
                        "response_type", "code", "scope", "email,public_profile",
                        "state", state);
            default: // X
                return "https://x.com/i/oauth2/authorize?" + form(
                        "response_type", "code", "client_id", id(p),
                        "redirect_uri", redirect, "scope", "users.read tweet.read",
                        "state", state, "code_challenge", desafioPkce(verificadorPkce),
                        "code_challenge_method", "S256");
        }
    }

    // ---------- Paso 2: cambiar el código por los datos del usuario ----------

    public static Perfil obtenerPerfil(String p, String codigo, String redirect,
                                       String verificadorPkce)
            throws IOException, InterruptedException {

        Perfil perfil = new Perfil();

        switch (p) {
            case GOOGLE: {
                JsonObject t = enviar(HttpRequest.newBuilder()
                        .uri(URI.create("https://oauth2.googleapis.com/token"))
                        .header("Content-Type", "application/x-www-form-urlencoded")
                        .POST(HttpRequest.BodyPublishers.ofString(form(
                                "code", codigo, "client_id", id(p),
                                "client_secret", secreto(p), "redirect_uri", redirect,
                                "grant_type", "authorization_code"))));
                JsonObject u = enviar(HttpRequest.newBuilder()
                        .uri(URI.create("https://openidconnect.googleapis.com/v1/userinfo"))
                        .header("Authorization", "Bearer " + texto(t, "access_token"))
                        .GET());
                perfil.uid = texto(u, "sub");
                perfil.nombre = texto(u, "name");
                perfil.correo = texto(u, "email");
                JsonElement ev = u.get("email_verified");
                perfil.correoVerificado = ev != null && !ev.isJsonNull() && ev.getAsBoolean();
                break;
            }
            case FACEBOOK: {
                JsonObject t = enviar(HttpRequest.newBuilder()
                        .uri(URI.create("https://graph.facebook.com/" + FB_VERSION
                                + "/oauth/access_token?" + form(
                                "client_id", id(p), "redirect_uri", redirect,
                                "client_secret", secreto(p), "code", codigo)))
                        .GET());
                JsonObject u = enviar(HttpRequest.newBuilder()
                        .uri(URI.create("https://graph.facebook.com/" + FB_VERSION
                                + "/me?fields=id,name,email"))
                        .header("Authorization", "Bearer " + texto(t, "access_token"))
                        .GET());
                perfil.uid = texto(u, "id");
                perfil.nombre = texto(u, "name");
                perfil.correo = texto(u, "email");
                perfil.correoVerificado = false; // Facebook no indica si está verificado
                break;
            }
            default: { // X
                String basic = Base64.getEncoder().encodeToString(
                        (id(p) + ":" + secreto(p)).getBytes(StandardCharsets.UTF_8));
                JsonObject t = enviar(HttpRequest.newBuilder()
                        .uri(URI.create("https://api.x.com/2/oauth2/token"))
                        .header("Content-Type", "application/x-www-form-urlencoded")
                        .header("Authorization", "Basic " + basic)
                        .POST(HttpRequest.BodyPublishers.ofString(form(
                                "grant_type", "authorization_code", "code", codigo,
                                "redirect_uri", redirect, "client_id", id(p),
                                "code_verifier", verificadorPkce))));
                JsonObject u = enviar(HttpRequest.newBuilder()
                        .uri(URI.create("https://api.x.com/2/users/me"))
                        .header("Authorization", "Bearer " + texto(t, "access_token"))
                        .GET());
                JsonObject d = u.getAsJsonObject("data");
                perfil.uid = texto(d, "id");
                perfil.nombre = texto(d, "name");
                if (perfil.nombre == null) perfil.nombre = texto(d, "username");
                perfil.correo = null;
                perfil.correoVerificado = false;
                break;
            }
        }

        if (perfil.uid == null || perfil.uid.isBlank()) {
            throw new IOException("El proveedor no devolvió un identificador.");
        }
        return perfil;
    }

    // ---------- Utilidades ----------

    private static JsonObject enviar(HttpRequest.Builder b)
            throws IOException, InterruptedException {
        HttpResponse<String> r = HTTP.send(
                b.timeout(Duration.ofSeconds(10)).build(),
                HttpResponse.BodyHandlers.ofString());
        if (r.statusCode() / 100 != 2) {
            throw new IOException("HTTP " + r.statusCode() + " de "
                    + r.uri().getHost() + ": " + r.body());
        }
        return JsonParser.parseString(r.body()).getAsJsonObject();
    }

    private static String texto(JsonObject o, String clave) {
        if (o == null) return null;
        JsonElement e = o.get(clave);
        return (e == null || e.isJsonNull()) ? null : e.getAsString();
    }

    private static String form(String... kv) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < kv.length; i += 2) {
            if (i > 0) sb.append('&');
            sb.append(URLEncoder.encode(kv[i], StandardCharsets.UTF_8)).append('=')
              .append(URLEncoder.encode(kv[i + 1], StandardCharsets.UTF_8));
        }
        return sb.toString();
    }
}