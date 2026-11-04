<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%
    String contexto = request.getContextPath();

    jakarta.servlet.http.HttpSession sesion = request.getSession(false);
    boolean logueado = sesion != null && sesion.getAttribute("usuarioId") != null;

    String nombreUsuario = "";
    if (logueado && sesion.getAttribute("nombreUsuario") != null) {
        nombreUsuario = String.valueOf(sesion.getAttribute("nombreUsuario"))
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>SAFIR · Tus historias, en un solo lugar</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,400;7..72,500&display=swap" rel="stylesheet">
<%-- Estilos de la portada, separados por responsabilidad (el orden importa) --%>
<link rel="stylesheet" href="<%= contexto %>/assets/css/index/base.css">
<link rel="stylesheet" href="<%= contexto %>/assets/css/index/cabecera-pie.css">
<link rel="stylesheet" href="<%= contexto %>/assets/css/index/hero.css">
<link rel="stylesheet" href="<%= contexto %>/assets/css/index/secciones.css">
<link rel="stylesheet" href="<%= contexto %>/assets/css/index/catalogo.css">
<link rel="stylesheet" href="<%= contexto %>/assets/css/index/animaciones.css">
<link rel="stylesheet" href="<%= contexto %>/assets/css/index/responsive.css">
</head>
<body>

<!-- Símbolos del logo compartidos (también los usa registro.jsp) -->
<%@ include file="/WEB-INF/vistas/comunes/simbolos-logo.jspf" %>

<!-- Portadas ilustradas (SVG propio, paleta SAFIR) -->
<svg width="0" height="0" style="position:absolute" aria-hidden="true" focusable="false">
  <defs>
    <symbol id="cv1" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#252866"/>
      <use href="#star" transform="translate(30 35) scale(9)" fill="#CBC9F4"/>
      <use href="#star" transform="translate(112 28) scale(6)" fill="#CBC9F4"/>
      <use href="#star" transform="translate(82 66) scale(5)" fill="#E9E7FF"/>
      <path d="M0 165 Q75 122 150 165 V200 H0Z" fill="#1D2042"/>
      <g stroke="#7775D6" stroke-width="2.5"><line x1="38" y1="182" x2="38" y2="152"/><line x1="75" y1="186" x2="75" y2="140"/><line x1="112" y1="182" x2="112" y2="155"/></g>
      <use href="#star" transform="translate(38 150) scale(9)" fill="#E9E7FF"/>
      <use href="#star" transform="translate(75 138) scale(11)" fill="#E9E7FF"/>
      <use href="#star" transform="translate(112 153) scale(8)" fill="#E9E7FF"/>
    </symbol>
    <symbol id="cv2" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#CBC9F4"/>
      <circle cx="108" cy="56" r="22" fill="#FFFCF7"/>
      <polygon points="0,150 46,82 92,150" fill="#7775D6"/>
      <polygon points="52,150 106,96 150,150" fill="#5051AE"/>
      <rect y="150" width="150" height="50" fill="#252866"/>
      <rect x="38" y="165" width="74" height="3" rx="1.5" fill="#7775D6"/>
      <rect x="56" y="178" width="40" height="3" rx="1.5" fill="#7775D6"/>
    </symbol>
    <symbol id="cv3" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#12142E"/>
      <circle cx="78" cy="82" r="44" fill="#E9E7FF"/>
      <circle cx="58" cy="72" r="8" fill="#CBC9F4"/>
      <circle cx="94" cy="98" r="10" fill="#CBC9F4"/>
      <circle cx="92" cy="64" r="5" fill="#CBC9F4"/>
      <use href="#plane-white" x="22" y="128" width="78" height="58"/>
      <use href="#star" transform="translate(24 30) scale(6)" fill="#CBC9F4"/>
      <use href="#star" transform="translate(128 150) scale(5)" fill="#CBC9F4"/>
    </symbol>
    <symbol id="cv4" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#5051AE"/>
      <rect x="30" y="128" width="90" height="18" rx="3" fill="#252866"/>
      <rect x="40" y="108" width="76" height="18" rx="3" fill="#CBC9F4"/>
      <rect x="36" y="88" width="66" height="18" rx="3" fill="#E9E7FF" transform="rotate(-7 69 97)"/>
      <use href="#star" transform="translate(32 46) scale(8)" fill="#E9E7FF"/>
      <use href="#star" transform="translate(116 60) scale(6)" fill="#CBC9F4"/>
      <use href="#star" transform="translate(86 28) scale(4)" fill="#E9E7FF"/>
    </symbol>
    <symbol id="cv5" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#E9E7FF"/>
      <path d="M75 24 Q94 50 75 70 Q56 50 75 24Z" fill="#252866"/>
      <g fill="none" stroke-width="7" stroke-linecap="round">
        <path d="M-5 118 Q35 96 75 118 T155 118" stroke="#5051AE"/>
        <path d="M-5 144 Q35 122 75 144 T155 144" stroke="#7775D6"/>
        <path d="M-5 170 Q35 148 75 170 T155 170" stroke="#252866"/>
      </g>
    </symbol>
    <symbol id="cv6" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#252866"/>
      <circle cx="75" cy="122" r="54" fill="#7775D6" opacity=".45"/>
      <rect y="148" width="150" height="52" fill="#12142E"/>
      <rect x="40" y="128" width="70" height="20" rx="5" fill="#CBC9F4"/>
      <g fill="#252866"><rect x="48" y="134" width="10" height="8" rx="2"/><rect x="64" y="134" width="10" height="8" rx="2"/><rect x="80" y="134" width="10" height="8" rx="2"/><rect x="96" y="134" width="8" height="8" rx="2"/></g>
      <g stroke="#5051AE" stroke-width="2"><line x1="0" y1="166" x2="150" y2="166"/><line x1="0" y1="182" x2="150" y2="182"/></g>
      <use href="#star" transform="translate(30 36) scale(6)" fill="#E9E7FF"/>
      <use href="#star" transform="translate(118 52) scale(8)" fill="#CBC9F4"/>
    </symbol>
  </defs>
</svg>

<header class="bar">
  <div class="wrap">
    <a class="brand" href="#inicio" aria-label="SAFIR, inicio">
      <svg viewBox="0 0 380 280" role="img" aria-hidden="true"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </a>
    <nav aria-label="Principal">
      <a href="#leer">Leer</a>
      <a href="#catalogo">Catálogo</a>
      <a href="#escribir">Publicar</a>
      <a href="#coins">Coins</a>
    </nav>
    <button class="theme-toggle" id="themeBtn" type="button" aria-pressed="false">Modo noche</button>
    <% if (logueado) { %>
    <a class="btn small ghost-bar user-chip" href="<%= contexto %>/auth/inicio">Hola, <%= nombreUsuario %></a>
    <a class="btn small on-bar" href="<%= contexto %>/logout">Cerrar sesión</a>
    <% } else { %>
    <a class="btn small ghost-bar" href="<%= contexto %>/auth/login">Iniciar sesión</a>
    <a class="btn small on-bar" href="<%= contexto %>/auth/registro">Crear cuenta</a>
    <% } %>
  </div>
</header>

<main id="inicio">
  <!-- HERO -->
  <div class="hero">
    <div class="wrap">
      <div class="hero-copy">
        <h1>Tus historias, en un solo lugar.</h1>
        <p class="lead">Una biblioteca digital y una comunidad literaria en la misma web. Lee durante horas con comodidad, publica tus obras y continúa siempre donde te quedaste.</p>
        <div class="actions">
          <a class="btn" href="#leer">Explorar historias</a>
          <a class="btn outline" href="#escribir">Publicar una obra</a>
        </div>
        <p class="note">Funciona en computadora y en el navegador del celular.</p>
      </div>

      <div class="stage" aria-hidden="true">
        <!-- Anillos finos alrededor de la luna -->
        <svg class="rings" viewBox="0 0 560 560">
          <circle class="r" cx="370" cy="157" r="190"/>
          <circle class="r" cx="370" cy="157" r="245" stroke-dasharray="2 9" stroke-linecap="round"/>
          <circle class="r" cx="370" cy="157" r="305"/>
          <g class="orbit"><circle cx="615" cy="157" r="5" fill="#7775D6"/></g>
        </svg>

        <svg class="spark s1" viewBox="-1 -1 2 2"><use href="#star" fill="#7775D6"/></svg>
        <svg class="spark s2" viewBox="-1 -1 2 2"><use href="#star" fill="#5051AE"/></svg>
        <svg class="spark s3" viewBox="-1 -1 2 2"><use href="#star" fill="#7775D6"/></svg>

        <!-- Luna (rota) -->
        <div class="moon">
          <svg viewBox="0 0 200 200">
            <defs>
              <radialGradient id="moonG" cx=".36" cy=".32" r=".85">
                <stop offset="0" stop-color="#F6F5FF"/><stop offset=".6" stop-color="#DAD8F8"/><stop offset="1" stop-color="#B9B6EE"/>
              </radialGradient>
            </defs>
            <circle cx="100" cy="100" r="98" fill="url(#moonG)"/>
            <g fill="#C3C0F1">
              <circle cx="62" cy="68" r="17"/><circle cx="130" cy="54" r="10"/><circle cx="138" cy="112" r="20"/>
              <circle cx="86" cy="140" r="13"/><circle cx="50" cy="118" r="8"/><circle cx="114" cy="165" r="9"/><circle cx="164" cy="70" r="6"/>
            </g>
            <g fill="#F6F5FF" opacity=".75">
              <circle cx="58" cy="63" r="6"/><circle cx="133" cy="105" r="7"/><circle cx="84" cy="136" r="4"/>
            </g>
          </svg>
        </div>

        <!-- Avión (detrás del título, delante de la luna) -->
        <div class="plane">
          <svg viewBox="0 0 380 280" class="plane-float"><use href="#plane-color"/></svg>
        </div>

        <!-- Libro abierto: las páginas pasan una tras otra -->
        <div class="openbook">
          <svg viewBox="0 0 300 190">
            <ellipse cx="150" cy="176" rx="132" ry="9" fill="#252866" opacity=".12"/>
            <rect x="14" y="160" width="272" height="10" rx="5" fill="#252866"/>
            <path d="M26 160 L40 126 Q96 112 150 142 V160Z" fill="#E9E7FF"/>
            <path d="M274 160 L260 126 Q204 112 150 142 V160Z" fill="#E9E7FF"/>
            <g fill="none" stroke="#CBC9F4" stroke-width="2" stroke-linecap="round">
              <path d="M34 150 Q92 136 148 152"/><path d="M266 150 Q208 136 152 152"/>
              <path d="M32 156 Q92 144 148 158"/><path d="M268 156 Q208 144 152 158"/>
            </g>
            <path d="M150 140 Q78 108 44 54 Q104 62 150 124Z" fill="#FFFCF7" stroke="#CBC9F4" stroke-width="2" stroke-linejoin="round"/>
            <path d="M150 140 Q222 108 256 54 Q196 62 150 124Z" fill="#FFFCF7" stroke="#CBC9F4" stroke-width="2" stroke-linejoin="round"/>
            <g class="flip" style="--d:1.65s"><path d="M150 138 Q216 104 250 46 Q194 58 150 122Z" fill="#F4F3FF" stroke="#CBC9F4" stroke-width="2" stroke-linejoin="round"/></g>
            <g class="flip" style="--d:1.1s"><path d="M150 138 Q216 104 250 46 Q194 58 150 122Z" fill="#FFFCF7" stroke="#CBC9F4" stroke-width="2" stroke-linejoin="round"/></g>
            <g class="flip" style="--d:.55s"><path d="M150 138 Q216 104 250 46 Q194 58 150 122Z" fill="#F4F3FF" stroke="#CBC9F4" stroke-width="2" stroke-linejoin="round"/></g>
            <g class="flip" style="--d:0s">
              <path d="M150 138 Q216 104 250 46 Q194 58 150 122Z" fill="#FFFCF7" stroke="#CBC9F4" stroke-width="2" stroke-linejoin="round"/>
              <path d="M164 116 Q206 96 230 66 M166 126 Q210 108 238 78" fill="none" stroke="#E3E0F7" stroke-width="2" stroke-linecap="round"/>
            </g>
            <path d="M134 160 Q150 134 166 160Z" fill="#12142E"/>
            <path d="M142 160 Q150 146 158 160Z" fill="#5051AE"/>
          </svg>
        </div>

        <!-- Pila de libros: brinca en cadena -->
        <div class="stack">
          <svg viewBox="0 0 160 150">
            <ellipse class="shadow" cx="80" cy="140" rx="62" ry="7" fill="#252866"/>
            <g class="hop" style="--d:0s;--h:-5px">
              <rect x="10" y="104" width="140" height="28" rx="5" fill="#252866"/>
              <rect x="136" y="108" width="10" height="20" rx="2" fill="#FFFCF7"/>
              <rect x="22" y="104" width="6" height="28" fill="#7775D6"/><rect x="34" y="104" width="3" height="28" fill="#7775D6"/>
            </g>
            <g class="hop" style="--d:.1s;--h:-10px">
              <rect x="22" y="76" width="118" height="26" rx="5" fill="#7775D6"/>
              <rect x="126" y="80" width="10" height="18" rx="2" fill="#FFFCF7"/>
              <rect x="34" y="76" width="5" height="26" fill="#E9E7FF"/>
            </g>
            <g class="hop" style="--d:.2s;--h:-15px">
              <g transform="rotate(-3 75 61)">
                <rect x="12" y="48" width="126" height="26" rx="5" fill="#5051AE"/>
                <rect x="124" y="52" width="10" height="18" rx="2" fill="#FFFCF7"/>
                <rect x="24" y="48" width="5" height="26" fill="#CBC9F4"/><rect x="33" y="48" width="3" height="26" fill="#CBC9F4"/>
              </g>
            </g>
            <g class="hop" style="--d:.3s;--h:-21px">
              <rect x="34" y="22" width="96" height="24" rx="5" fill="#CBC9F4"/>
              <rect x="118" y="26" width="9" height="16" rx="2" fill="#FFFCF7"/>
              <rect x="46" y="22" width="5" height="24" fill="#252866"/>
              <use href="#star" transform="translate(84 10) scale(6)" fill="#7775D6"/>
            </g>
          </svg>
        </div>
      </div>
    </div>
  </div>

  <!-- LECTURA -->
  <section class="reading" id="leer">
    <div class="wrap">
      <div>
        <h2>Pensada para leer durante mucho tiempo</h2>
        <p class="sec-lead">Fondo cálido en lugar de blanco puro, una tipografía creada para leer en pantalla y un modo noche que tú decides activar. Pruébalo aquí mismo.</p>
      </div>
      <div class="reader" aria-label="Ejemplo de lectura">
        <svg class="scene" id="scene" viewBox="0 0 600 220" role="img" aria-label="Un pueblo de noche: las luces de las casas se apagan una a una y solo el jardín sigue brillando bajo las estrellas">
          <defs>
            <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#12142E"/><stop offset="1" stop-color="#2F3180"/></linearGradient>
            <radialGradient id="halo"><stop offset="0" stop-color="#CBC9F4" stop-opacity=".95"/><stop offset="1" stop-color="#CBC9F4" stop-opacity="0"/></radialGradient>
          </defs>
          <rect width="600" height="220" fill="url(#sky)"/>
          <g id="stars"></g>
          <g class="fly"><use href="#plane-white" x="0" y="40" width="46" height="34"/></g>
          <path d="M0 172 Q150 128 300 166 T600 150 V220 H0Z" fill="#1D2042"/>
          <path d="M0 198 Q200 166 400 192 T600 186 V220 H0Z" fill="#181B3A"/>
          <g fill="#252866">
            <rect x="30" y="146" width="70" height="48"/><polygon points="24,146 65,116 106,146" fill="#1D2042"/>
            <rect x="140" y="152" width="64" height="44"/><polygon points="134,152 172,124 210,152" fill="#1D2042"/>
            <rect x="245" y="140" width="76" height="52"/><polygon points="239,140 283,108 327,140" fill="#1D2042"/>
            <rect x="350" y="154" width="60" height="40"/><polygon points="344,154 380,128 416,154" fill="#1D2042"/>
          </g>
          <g>
            <rect class="win" style="--d:.8s" x="42" y="158" width="14" height="14" rx="2"/><rect class="win" style="--d:1.4s" x="72" y="158" width="14" height="14" rx="2"/>
            <rect class="win" style="--d:2s" x="150" y="164" width="13" height="13" rx="2"/><rect class="win" style="--d:2.6s" x="180" y="164" width="13" height="13" rx="2"/>
            <rect class="win" style="--d:3.2s" x="257" y="152" width="14" height="14" rx="2"/><rect class="win" style="--d:3.8s" x="295" y="152" width="14" height="14" rx="2"/>
            <rect class="win" style="--d:4.4s" x="362" y="166" width="12" height="12" rx="2"/><rect class="win" style="--d:5s" x="386" y="166" width="12" height="12" rx="2"/>
          </g>
          <g stroke="#7775D6" stroke-width="2.5"><line x1="458" y1="196" x2="458" y2="164"/><line x1="500" y1="200" x2="500" y2="150"/><line x1="544" y1="196" x2="544" y2="168"/></g>
          <g class="glow"><circle cx="458" cy="160" r="22" fill="url(#halo)"/></g>
          <g class="glow" style="animation-delay:.7s"><circle cx="500" cy="146" r="28" fill="url(#halo)"/></g>
          <g class="glow" style="animation-delay:1.4s"><circle cx="544" cy="164" r="20" fill="url(#halo)"/></g>
          <use href="#star" transform="translate(458 160) scale(8)" fill="#F4F3FF"/>
          <use href="#star" transform="translate(500 146) scale(11)" fill="#F4F3FF"/>
          <use href="#star" transform="translate(544 164) scale(7)" fill="#F4F3FF"/>
        </svg>
        <div class="reader-top">
          <strong>El jardín de las estrellas</strong>
          <div class="ctl" role="group" aria-label="Tamaño del texto">
            <button type="button" id="smaller" aria-label="Reducir texto">A−</button>
            <button type="button" id="bigger" aria-label="Aumentar texto">A+</button>
          </div>
          <button class="theme-toggle" id="themeBtn2" type="button" style="color:var(--link);border-color:var(--outline)" aria-pressed="false">Modo noche</button>
        </div>
        <div class="reader-body">
          <div class="story" id="story">
            <p class="first">Una historia comienza aquí… Las luces del pueblo se apagaron una a una, y solo el jardín siguió brillando bajo un cielo lleno de estrellas.</p>
            <p>Nadie supo decir quién había plantado las primeras semillas. Algunos aseguraban que fue el viento; otros, que una niña con un avión de papel había cruzado el valle antes del amanecer.</p>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- ESCRIBIR -->
  <section class="write" id="escribir">
    <div class="wrap">
      <div>
        <h2>Sube tu PDF y SAFIR lo separa en capítulos</h2>
        <p class="sec-lead">Si ya tienes tu obra escrita, no necesitas copiarla capítulo por capítulo. También puedes crear una obra nueva y publicar cada capítulo desde la plataforma.</p>
        <ol class="steps">
          <li>
            <div><h3>Sube tu archivo</h3><p>Elige el PDF de tu obra desde tu dispositivo.</p></div>
          </li>
          <li>
            <div><h3>Revisa la propuesta</h3><p>SAFIR sugiere dónde empieza cada capítulo. Tú marcas los que quieres conservar.</p></div>
          </li>
          <li>
            <div><h3>Publica</h3><p>Tus lectores ven los capítulos en orden y pueden continuar desde el último que leyeron.</p></div>
          </li>
        </ol>
      </div>

      <div class="demo" aria-label="Vista de ejemplo de la conversión de PDF a capítulos">
        <div class="file">
          <div class="icon" aria-hidden="true">PDF</div>
          <div><b>El jardín de las estrellas.pdf</b><small>48 páginas · ejemplo</small></div>
        </div>
        <button class="btn" id="proposeBtn" type="button">Proponer capítulos</button>
        <ul class="chapters" id="chapters" aria-live="polite"></ul>
        <button class="btn outline" id="publishBtn" type="button" hidden>Publicar capítulos marcados</button>
        <p class="status" id="status" role="status"></p>
      </div>
    </div>
  </section>

  <!-- CATÁLOGO -->
  <section class="catalog" id="catalogo">
    <div class="wrap">
      <h2>Historias para cada noche</h2>
      <p class="sec-lead">Fantasía, aventura, misterio y más. Explora portadas, guarda lo que quieras leer después y vuelve cuando quieras.</p>
    </div>
    <div class="marquee" aria-label="Portadas de ejemplo">
      <div class="track" id="track">
        <figure class="book"><svg viewBox="0 0 150 200" aria-hidden="true"><use href="#cv1"/></svg><figcaption>El jardín de las estrellas<span>Fantasía</span></figcaption></figure>
        <figure class="book"><svg viewBox="0 0 150 200" aria-hidden="true"><use href="#cv2"/></svg><figcaption>Cuentos del Altiplano<span>Relatos</span></figcaption></figure>
        <figure class="book"><svg viewBox="0 0 150 200" aria-hidden="true"><use href="#cv3"/></svg><figcaption>Cartas a la luna<span>Romance</span></figcaption></figure>
        <figure class="book"><svg viewBox="0 0 150 200" aria-hidden="true"><use href="#cv4"/></svg><figcaption>La biblioteca flotante<span>Aventura</span></figcaption></figure>
        <figure class="book"><svg viewBox="0 0 150 200" aria-hidden="true"><use href="#cv5"/></svg><figcaption>Río de tinta<span>Misterio</span></figcaption></figure>
        <figure class="book"><svg viewBox="0 0 150 200" aria-hidden="true"><use href="#cv6"/></svg><figcaption>Última estación<span>Ciencia ficción</span></figcaption></figure>
      </div>
    </div>
    <div class="wrap"><p class="small-note">Portadas ilustradas de ejemplo; los títulos son ficticios.</p></div>
  </section>

  <!-- LECTORES + COINS -->
  <section class="reader-hub" id="coins">
    <div class="wrap">
      <h2>Tu biblioteca te espera donde la dejaste</h2>
      <div class="hub">
        <article class="continue">
          <h3>Continuar leyendo</h3>
          <div class="row">
            <div class="cover" aria-hidden="true"><svg viewBox="0 0 380 280"><use href="#plane-white"/></svg></div>
            <div>
              <div class="book-title">El jardín de las estrellas</div>
              <div class="book-sub">Capítulo 4 · Tu lectura continúa aquí</div>
              <div class="progress" role="progressbar" aria-valuenow="58" aria-valuemin="0" aria-valuemax="100" aria-label="Avance de lectura"><i></i></div>
              <% if (logueado) { %>
              <a class="btn small" href="<%= contexto %>/auth/inicio">Leer ahora</a>
              <% } else { %>
              <a class="btn small" href="<%= contexto %>/auth/login">Leer ahora</a>
              <% } %>
            </div>
          </div>
        </article>
        <article class="coins">
          <h3>Mis coins</h3>
          <p>Tus recompensas de lectura, logros y compras viven en un solo saldo.</p>
          <div class="coin-row">
            <div class="coin" aria-hidden="true">S</div>
            <div class="coin-num" id="coinNum" aria-label="1,000 coins">1,000</div>
          </div>
          <% if (logueado) { %>
          <a class="btn small gold" href="<%= contexto %>/auth/inicio">Ver recompensas</a>
          <% } else { %>
          <a class="btn small gold" href="<%= contexto %>/auth/login">Ver recompensas</a>
          <% } %>
        </article>
      </div>
      <p class="small-note">Vista conceptual de ejemplo; los datos mostrados no son reales.</p>
    </div>
  </section>

  <!-- CTA -->
  <section class="final" id="unirme">
    <div class="wrap">
      <h2>Tu próxima historia te espera.</h2>
      <p>Descubre nuevas historias o continúa leyendo donde te quedaste.</p>
      <div class="actions">
        <% if (logueado) { %>
        <a class="btn on-bar" href="<%= contexto %>/auth/inicio">Ir a mi inicio</a>
        <% } else { %>
        <a class="btn on-bar" href="<%= contexto %>/auth/registro">Crear cuenta</a>
        <a class="btn outline" href="<%= contexto %>/auth/login">Iniciar sesión</a>
        <% } %>
      </div>
    </div>
  </section>
</main>

<footer>
  <div class="wrap">
    <a class="brand" href="#inicio" aria-label="SAFIR, inicio">
      <svg viewBox="0 0 380 280" aria-hidden="true"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </a>
    <span>Tus historias, en un solo lugar.</span>
  </div>
</footer>

<script>
(function () {
  var root = document.documentElement;
  var btns = [document.getElementById('themeBtn'), document.getElementById('themeBtn2')];

  function setTheme(t) {
    if (t === 'dark') root.setAttribute('data-theme', 'dark'); else root.removeAttribute('data-theme');
    btns.forEach(function (b) {
      b.setAttribute('aria-pressed', t === 'dark' ? 'true' : 'false');
      b.textContent = t === 'dark' ? 'Modo claro' : 'Modo noche';
    });
    try { localStorage.setItem('safir-theme', t); } catch (e) {}
  }
  var saved = null;
  try { saved = localStorage.getItem('safir-theme'); } catch (e) {}
  setTheme(saved === 'dark' ? 'dark' : 'light');
  btns.forEach(function (b) {
    b.addEventListener('click', function () {
      setTheme(root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
    });
  });

  // Tamaño del texto de lectura
  var story = document.getElementById('story');
  var size = 1.2;
  function applySize() { story.style.fontSize = size + 'rem'; }
  document.getElementById('bigger').addEventListener('click', function () { size = Math.min(1.7, +(size + 0.1).toFixed(2)); applySize(); });
  document.getElementById('smaller').addEventListener('click', function () { size = Math.max(1, +(size - 0.1).toFixed(2)); applySize(); });

  // Estrellas del cielo (generadas)
  var NS = 'http://www.w3.org/2000/svg';
  var starsG = document.getElementById('stars');
  [[40,30,6],[95,55,4],[150,22,5],[210,48,7],[270,26,4],[330,60,5],[390,24,6],[450,44,4],[520,28,7],[570,66,4],[20,84,4],[300,96,3]].forEach(function (p, i) {
    var o = document.createElementNS(NS, 'g'); o.setAttribute('transform', 'translate(' + p[0] + ' ' + p[1] + ')');
    var t = document.createElementNS(NS, 'g'); t.setAttribute('class', 'tw'); t.style.animationDelay = (i * 0.37) + 's';
    var u = document.createElementNS(NS, 'use'); u.setAttribute('href', '#star'); u.setAttribute('transform', 'scale(' + p[2] + ')'); u.setAttribute('fill', '#E9E7FF');
    t.appendChild(u); o.appendChild(t); starsG.appendChild(o);
  });

  // Carrusel de portadas: se duplica para el bucle continuo
  var track = document.getElementById('track');
  Array.prototype.slice.call(track.children).forEach(function (f) {
    var c = f.cloneNode(true); c.setAttribute('aria-hidden', 'true'); c.setAttribute('data-dup', ''); track.appendChild(c);
  });

  // Animaciones al entrar en pantalla
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  function countUp(el, to, ms) {
    if (reduce) return;
    var s = null;
    function f(t) {
      if (!s) s = t;
      var k = Math.min(1, (t - s) / ms);
      el.textContent = Math.round(to * (1 - Math.pow(1 - k, 3))).toLocaleString('en-US');
      if (k < 1) requestAnimationFrame(f);
    }
    requestAnimationFrame(f);
  }
  var scene = document.getElementById('scene');
  var rvEls = Array.prototype.slice.call(document.querySelectorAll('.hub article, .demo, .steps li'));
  if (!reduce) rvEls.forEach(function (e) { e.classList.add('rv'); });
  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (!en.isIntersecting) return;
        var el = en.target;
        el.classList.add('in');
        if (el === scene) el.classList.add('play');
        if (el.classList.contains('coins')) countUp(document.getElementById('coinNum'), 1000, 1600);
        io.unobserve(el);
      });
    }, { threshold: 0.3 });
    [scene].concat(rvEls).forEach(function (el) { io.observe(el); });
  } else {
    rvEls.forEach(function (e) { e.classList.add('in'); });
    scene.classList.add('play');
  }

  // Demo PDF -> capítulos
  var chapters = [
    { t: 'Capítulo 1 · Las luces del pueblo', p: 'págs. 1–11' },
    { t: 'Capítulo 2 · La niña del avión de papel', p: 'págs. 12–22' },
    { t: 'Capítulo 3 · Semillas', p: 'págs. 23–34' },
    { t: 'Capítulo 4 · Bajo un cielo lleno de estrellas', p: 'págs. 35–48' }
  ];
  var list = document.getElementById('chapters');
  var propose = document.getElementById('proposeBtn');
  var publish = document.getElementById('publishBtn');
  var status = document.getElementById('status');

  propose.addEventListener('click', function () {
    list.innerHTML = '';
    status.textContent = '';
    chapters.forEach(function (c, i) {
      var li = document.createElement('li');
      li.style.animationDelay = (i * 80) + 'ms';
      li.innerHTML = '<input type="checkbox" id="ch' + i + '" checked><label for="ch' + i + '">' + c.t + '</label><span>' + c.p + '</span>';
      list.appendChild(li);
    });
    publish.hidden = false;
    propose.textContent = 'Volver a proponer';
    status.textContent = 'SAFIR propone ' + chapters.length + ' capítulos. Desmarca los que no quieras publicar.';
  });

  publish.addEventListener('click', function () {
    var n = list.querySelectorAll('input:checked').length;
    status.textContent = n === 0
      ? 'Marca al menos un capítulo para publicar.'
      : (n === 1 ? 'Se publicó 1 capítulo (ejemplo).' : 'Se publicaron ' + n + ' capítulos (ejemplo).');
  });
})();
</script>
</body>
</html>
