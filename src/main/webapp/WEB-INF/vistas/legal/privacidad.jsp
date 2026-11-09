<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%--
    Política de privacidad. Lo usa PrivacidadServlet (GET /privacidad).
    Atributos: actualizada (texto) y correoContacto (puede ser null).
--%>
<%
    String contexto = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Política de privacidad · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet">
<script>
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}
</script>
<style>
  :root { --indigo:#252866; --lav:#7775D6; --soft:#E9E7FF; --warm:#FFFCF7; --carbon:#292936;
          --bg:var(--warm); --text:var(--carbon); --title:var(--indigo); --muted:#5b5b72; --line:#E3E0F7; --link:var(--indigo);
          --sans:"DM Sans", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
  :root[data-theme="dark"] { --bg:#12142E; --soft:#181B3A; --text:#D9D9E8; --title:#F1F0FF; --muted:#A5A6C4; --line:#2C3060; --link:#B9B7F5; }
  *, *::before, *::after { box-sizing: border-box; }
  body { margin:0; background:var(--bg); color:var(--text); font-family:var(--sans); font-size:1.0625rem; line-height:1.7; -webkit-font-smoothing:antialiased; }
  a { color:var(--link); }
  :focus-visible { outline:3px solid var(--lav); outline-offset:3px; border-radius:6px; }
  .pv-barra { display:flex; justify-content:space-between; align-items:center; gap:1rem; flex-wrap:wrap;
              max-width:820px; margin:0 auto; padding:1.2rem 1.25rem; }
  .pv-marca { display:inline-flex; align-items:center; gap:.6rem; text-decoration:none; color:var(--title); font-weight:600; letter-spacing:.04em; }
  .pv-marca svg { width:44px; height:33px; }
  .pv-marca .dk { display:none; }
  :root[data-theme="dark"] .pv-marca .lt { display:none; }
  :root[data-theme="dark"] .pv-marca .dk { display:block; }
  .pv-main { max-width:820px; margin:0 auto; padding:.5rem 1.25rem 4rem; }
  h1 { font-weight:300; font-size:clamp(2rem,5vw,2.8rem); line-height:1.1; letter-spacing:-.01em; color:var(--title); margin:.4rem 0 .6rem; }
  h2 { font-weight:500; font-size:1.3rem; color:var(--title); margin:2.2rem 0 .5rem; line-height:1.3; }
  p, ul { margin:.6rem 0; }
  ul { padding-left:1.25rem; }
  li { margin:.3rem 0; }
  .pv-fecha { color:var(--muted); font-size:.95rem; }
  .pv-resumen { margin:1.5rem 0 0; padding:1rem 1.2rem; border-radius:16px; background:var(--soft); border:1px solid var(--line); }
  .pv-resumen p { margin:.3rem 0; }
  .pv-pie { margin-top:3rem; padding-top:1.2rem; border-top:1px solid var(--line); color:var(--muted); font-size:.92rem; }
</style>
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/simbolos-logo.jspf" %>

<header class="pv-barra">
  <a class="pv-marca" href="<%= contexto %>/" aria-label="SAFIR, inicio">
    <svg class="lt" viewBox="0 0 380 280" aria-hidden="true"><use href="#plane-color"/></svg>
    <svg class="dk" viewBox="0 0 380 280" aria-hidden="true"><use href="#plane-white"/></svg>
    <span>SAFIR</span>
  </a>
  <a href="<%= contexto %>/">Volver al inicio</a>
</header>

<main class="pv-main">
  <h1>Política de privacidad</h1>
  <p class="pv-fecha">Última actualización: <c:out value="${actualizada}"/></p>

  <div class="pv-resumen" role="note">
    <p><b>En breve:</b> usamos tus datos para que puedas crear tu cuenta, leer y publicar obras, comprar monedas y retirar tus ganancias. No vendemos tus datos. Puedes pedir en cualquier momento acceder a ellos, corregirlos o eliminarlos.</p>
  </div>

  <h2>1. Quién es el responsable</h2>
  <p>SAFIR es una plataforma de lectura y escritura de obras y capítulos. El titular de la plataforma es el responsable del tratamiento de tus datos personales y del banco de datos donde se almacenan. Esta política explica qué datos recogemos, para qué los usamos y qué derechos tienes, conforme a la Ley N.º 29733, Ley de Protección de Datos Personales del Perú, y su reglamento.</p>

  <h2>2. Qué datos recogemos</h2>
  <ul>
    <li><b>Datos de registro:</b> sobrenombre, nombre de usuario, correo electrónico o número de teléfono y contraseña. La contraseña se guarda cifrada (hash); nadie en SAFIR puede leerla.</li>
    <li><b>Verificación:</b> el código de 6 dígitos que enviamos a tu correo o teléfono y la fecha en que lo confirmas.</li>
    <li><b>Inicio de sesión con Google, Facebook o X:</b> el nombre y el correo que esa red nos entrega con tu autorización. No recibimos tu contraseña de esa red.</li>
    <li><b>Perfil:</b> foto de perfil, portada, enlaces a tus redes y la música que decidas subir.</li>
    <li><b>Contenido:</b> obras, capítulos, archivos que importas (PDF, DOCX, DOC o TXT), comentarios, valoraciones, biblioteca y obras que sigues.</li>
    <li><b>Monedas y pagos:</b> compras de paquetes de monedas, capítulos desbloqueados, regalos enviados y recibidos, niveles de autor y solicitudes de retiro, con sus fechas e importes.</li>
    <li><b>Notificaciones y preferencias:</b> avisos de la plataforma, idioma y tema (claro u oscuro).</li>
  </ul>

  <h2>3. Para qué usamos tus datos</h2>
  <ul>
    <li>Crear y proteger tu cuenta, verificar tu correo o teléfono y recuperar tu contraseña.</li>
    <li>Mostrar tu perfil y tu contenido, y permitir que otras personas lean, comenten y valoren.</li>
    <li>Procesar compras, regalos, desbloqueos de capítulos, reembolsos y retiros, y aplicar las comisiones indicadas en la plataforma.</li>
    <li>Enviarte avisos relacionados con tu cuenta y con la actividad de tus obras.</li>
    <li>Moderar contenido y prevenir fraude o abusos.</li>
  </ul>
  <p>Al registrarte, verificar tu código o continuar con una red social, autorizas este uso de tus datos personales. Puedes retirar tu autorización eliminando tu cuenta, aunque algunos datos deberán conservarse si la ley lo exige.</p>

  <h2>4. Qué es público</h2>
  <p>Tu nombre público, nombre de usuario, foto, portada, enlaces del perfil, obras publicadas, capítulos publicados y comentarios pueden ser vistos por otras personas. Tu correo, tu teléfono y tus datos de pago nunca se muestran públicamente.</p>

  <h2>5. Con quién compartimos datos</h2>
  <p>No vendemos ni alquilamos tus datos. Solo los compartimos con:</p>
  <ul>
    <li>Proveedores que hacen posible el servicio: envío de correos y mensajes SMS con el código de verificación, y pasarelas de pago (PayPal y Yape).</li>
    <li>Google, Facebook o X, solo si eliges iniciar sesión con ellos.</li>
    <li>Autoridades, cuando una norma o una orden válida nos obligue.</li>
  </ul>
  <p>SAFIR no almacena los datos de tu tarjeta; los procesa la pasarela de pago.</p>

  <h2>6. Cuánto tiempo los conservamos</h2>
  <p>Conservamos tus datos mientras tu cuenta esté activa. Si eliminas tu cuenta, borramos o anonimizamos tus datos personales, salvo los registros de transacciones (compras, retiros y reembolsos) que debamos guardar el tiempo que exijan las normas contables y tributarias. Los archivos que importas para crear capítulos se guardan solo mientras revisas la importación y se borran al confirmarla o rechazarla.</p>

  <h2>7. Seguridad</h2>
  <p>Aplicamos medidas técnicas y organizativas para proteger tus datos: contraseñas cifradas, códigos de verificación con vencimiento, sesiones protegidas y acceso restringido a la información. Ningún sistema es infalible; si detectamos un incidente que afecte tus datos, te lo comunicaremos según corresponda.</p>

  <h2>8. Cookies y almacenamiento en tu navegador</h2>
  <p>Usamos una cookie de sesión para mantenerte conectado y almacenamiento local del navegador para recordar tu tema e idioma. No usamos cookies de publicidad.</p>

  <h2>9. Tus derechos</h2>
  <p>Puedes ejercer tus derechos de <b>acceso, rectificación, cancelación y oposición</b> sobre tus datos personales. Muchos datos los puedes corregir tú mismo desde <i>Mi cuenta</i>, y puedes eliminar tu cuenta desde esa misma sección.</p>
  <p>Para cualquier otra solicitud escribe a
    <c:choose>
      <c:when test="${not empty correoContacto}"><a href="mailto:<c:out value='${correoContacto}'/>"><c:out value="${correoContacto}"/></a></c:when>
      <c:otherwise>nuestro equipo de soporte desde la plataforma</c:otherwise>
    </c:choose>
    indicando tu nombre de usuario y qué deseas hacer. Si consideras que no atendimos tu solicitud, puedes presentar un reclamo ante la Autoridad Nacional de Protección de Datos Personales del Perú.</p>

  <h2>10. Menores de edad</h2>
  <p>Si eres menor de edad, usa SAFIR con el consentimiento de tu madre, padre o tutor. Si sabemos que se registró un menor sin ese consentimiento, podremos eliminar la cuenta.</p>

  <h2>11. Cambios en esta política</h2>
  <p>Si cambiamos esta política, publicaremos la nueva versión en esta página con su fecha de actualización. Si el cambio es importante, te avisaremos dentro de la plataforma.</p>

  <p class="pv-pie"><a href="<%= contexto %>/">Volver al inicio</a></p>
</main>

</body>
</html>
