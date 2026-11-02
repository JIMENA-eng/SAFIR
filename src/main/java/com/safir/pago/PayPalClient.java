package com.safir.pago;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;

/**
 * Cliente mínimo de la API REST de PayPal (Orders v2).
 *
 * Variables de entorno:
 *   PAYPAL_CLIENT_ID, PAYPAL_SECRET  credenciales de tu app en developer.paypal.com
 *   PAYPAL_BASE_URL                  opcional; por defecto sandbox.
 *                                    Producción: https://api-m.paypal.com
 */
public class PayPalClient {

    private static final String BASE = System.getenv()
            .getOrDefault("PAYPAL_BASE_URL", "https://api-m.sandbox.paypal.com");
    private static final String CLIENT_ID = System.getenv("PAYPAL_CLIENT_ID");
    private static final String SECRET = System.getenv("PAYPAL_SECRET");

    private final HttpClient http = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    public record Orden(String id, String urlAprobacion) { }

    public record Captura(boolean completada, BigDecimal monto,
                          String moneda, String customId) { }

    public static boolean configurado() {
        return CLIENT_ID != null && !CLIENT_ID.isBlank()
                && SECRET != null && !SECRET.isBlank();
    }

    /** Los ids de orden de PayPal son alfanuméricos; se valida antes de usarlos en una URL. */
    public static boolean ordenValida(String id) {
        return id != null && id.matches("[A-Za-z0-9]{8,40}");
    }

    /** Crea la orden y devuelve la URL a la que hay que enviar al comprador. */
    public Orden crearOrden(long compraId, BigDecimal montoUsd, String descripcion,
                            String urlRetorno, String urlCancelar) throws IOException {

        JsonObject monto = new JsonObject();
        monto.addProperty("currency_code", "USD");
        monto.addProperty("value",
                montoUsd.setScale(2, RoundingMode.HALF_UP).toPlainString());

        JsonObject unidad = new JsonObject();
        unidad.addProperty("reference_id", "compra-" + compraId);
        unidad.addProperty("custom_id", String.valueOf(compraId));
        unidad.addProperty("description", descripcion);
        unidad.add("amount", monto);

        JsonArray unidades = new JsonArray();
        unidades.add(unidad);

        JsonObject contexto = new JsonObject();
        contexto.addProperty("brand_name", "SAFIR");
        contexto.addProperty("user_action", "PAY_NOW");
        contexto.addProperty("return_url", urlRetorno);
        contexto.addProperty("cancel_url", urlCancelar);

        JsonObject paypal = new JsonObject();
        paypal.add("experience_context", contexto);

        JsonObject fuente = new JsonObject();
        fuente.add("paypal", paypal);

        JsonObject cuerpo = new JsonObject();
        cuerpo.addProperty("intent", "CAPTURE");
        cuerpo.add("purchase_units", unidades);
        cuerpo.add("payment_source", fuente);

        HttpRequest req = HttpRequest.newBuilder(URI.create(BASE + "/v2/checkout/orders"))
                .timeout(Duration.ofSeconds(20))
                .header("Authorization", "Bearer " + token())
                .header("Content-Type", "application/json")
                .header("PayPal-Request-Id", "safir-compra-" + compraId)
                .POST(HttpRequest.BodyPublishers.ofString(cuerpo.toString()))
                .build();

        JsonObject json = exigirExito(llamar(req));
        String id = json.get("id").getAsString();
        String url = null;

        for (JsonElement e : json.getAsJsonArray("links")) {
            JsonObject enlace = e.getAsJsonObject();
            String rel = enlace.get("rel").getAsString();
            if ("payer-action".equals(rel) || "approve".equals(rel)) {
                url = enlace.get("href").getAsString();
                break;
            }
        }

        if (url == null) {
            throw new IOException("PayPal no devolvió el enlace de aprobación.");
        }
        return new Orden(id, url);
    }

    /** Cobra una orden ya aprobada por el comprador. Es seguro repetir la llamada. */
    public Captura capturar(String ordenId) throws IOException {
        validar(ordenId);

        HttpRequest req = HttpRequest
                .newBuilder(URI.create(BASE + "/v2/checkout/orders/" + ordenId + "/capture"))
                .timeout(Duration.ofSeconds(20))
                .header("Authorization", "Bearer " + token())
                .header("Content-Type", "application/json")
                .header("PayPal-Request-Id", "safir-captura-" + ordenId)
                .POST(HttpRequest.BodyPublishers.ofString("{}"))
                .build();

        HttpResponse<String> r = llamar(req);

        // Ya se había cobrado (p. ej. el usuario recargó la página): se consulta su estado.
        if (r.statusCode() == 422 && r.body().contains("ORDER_ALREADY_CAPTURED")) {
            return consultar(ordenId);
        }
        return leerCaptura(exigirExito(r));
    }

    public Captura consultar(String ordenId) throws IOException {
        validar(ordenId);

        HttpRequest req = HttpRequest
                .newBuilder(URI.create(BASE + "/v2/checkout/orders/" + ordenId))
                .timeout(Duration.ofSeconds(20))
                .header("Authorization", "Bearer " + token())
                .GET()
                .build();

        return leerCaptura(exigirExito(llamar(req)));
    }

    // ------------------------------------------------------------------

    private static void validar(String ordenId) throws IOException {
        if (!ordenValida(ordenId)) {
            throw new IOException("Identificador de orden inválido.");
        }
    }

    private String token() throws IOException {
        if (!configurado()) {
            throw new IOException("PayPal no está configurado (PAYPAL_CLIENT_ID / PAYPAL_SECRET).");
        }

        String basic = Base64.getEncoder().encodeToString(
                (CLIENT_ID + ":" + SECRET).getBytes(StandardCharsets.UTF_8));

        HttpRequest req = HttpRequest.newBuilder(URI.create(BASE + "/v1/oauth2/token"))
                .timeout(Duration.ofSeconds(20))
                .header("Authorization", "Basic " + basic)
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString("grant_type=client_credentials"))
                .build();

        return exigirExito(llamar(req)).get("access_token").getAsString();
    }

    private HttpResponse<String> llamar(HttpRequest req) throws IOException {
        try {
            return http.send(req, HttpResponse.BodyHandlers.ofString());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IOException("Solicitud a PayPal interrumpida.", e);
        }
    }

    private JsonObject exigirExito(HttpResponse<String> r) throws IOException {
        if (r.statusCode() / 100 != 2) {
            throw new IOException("PayPal respondió " + r.statusCode() + ": " + r.body());
        }
        return JsonParser.parseString(r.body()).getAsJsonObject();
    }

    private Captura leerCaptura(JsonObject json) {
        boolean ordenOk = json.has("status")
                && "COMPLETED".equals(json.get("status").getAsString());
        try {
            JsonObject unidad = json.getAsJsonArray("purchase_units")
                    .get(0).getAsJsonObject();
            JsonObject captura = unidad.getAsJsonObject("payments")
                    .getAsJsonArray("captures").get(0).getAsJsonObject();

            boolean capturaOk = "COMPLETED".equals(captura.get("status").getAsString());
            JsonObject monto = captura.getAsJsonObject("amount");

            String custom = unidad.has("custom_id") ? unidad.get("custom_id").getAsString()
                    : captura.has("custom_id") ? captura.get("custom_id").getAsString()
                    : null;

            return new Captura(ordenOk && capturaOk,
                    new BigDecimal(monto.get("value").getAsString()),
                    monto.get("currency_code").getAsString(),
                    custom);
        } catch (RuntimeException e) {
            // Respuesta sin datos de cobro (orden aún no completada).
            return new Captura(false, BigDecimal.ZERO, "", null);
        }
    }
}