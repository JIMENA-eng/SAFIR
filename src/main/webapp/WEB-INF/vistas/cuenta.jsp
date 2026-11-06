<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ include file="/WEB-INF/vistas/comunes/encabezado-datos.jspf" %>
<%@ include file="/WEB-INF/vistas/cuenta/cuenta-datos.jspf" %>
<%@ include file="/WEB-INF/vistas/cuenta/cuenta-helpers.jspf" %>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Mi cuenta · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,400;7..72,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/base.css">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/landing.css">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/animaciones.css">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/ventanas.css">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/responsive.css">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/inicio.css">
<link rel="stylesheet" href="<%= contexto %>/assets/inicio/encabezadoinicio.css">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/cuenta.css">
</head>
<body>

<%@ include file="/WEB-INF/vistas/cuenta/cuenta-portadas.jspf" %>

<%@ include file="/WEB-INF/vistas/comunes/encabezado.jspf" %>

<main id="cuenta">
  <!-- PERFIL: portada a todo el ancho, perfil a la izquierda y "Encuéntrame en" a la derecha -->
  <section class="cuenta-hero" aria-label="Mi perfil">
    <div class="cuenta-cover">
      <% if (portadaRuta != null) { %>
      <img src="<%= contexto %>/media/<%= esc(portadaRuta) %>" alt="">
      <% } %>
    </div>

    <div class="cuenta-hero-body">
      <div class="cuenta-lado cuenta-lado-perfil">
        <div class="cuenta-avatar" aria-hidden="true"><%= avatarHtml %></div>
        <div class="cuenta-nombres">
          <h1 class="cuenta-nombre"><%= nombrePublico %></h1>
          <% if (!usuarioArroba.isEmpty()) { %>
          <p class="cuenta-usuario"><%= usuarioArroba %></p>
          <% } %>
          <ul class="cuenta-stats" aria-label="Estadísticas del perfil">
            <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg><b><%= nSeguidores %></b><span>Seguidores</span></li>
            <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="19" x2="19" y1="8" y2="14"/><line x1="22" x2="16" y1="11" y2="11"/></svg><b><%= nSeguidos %></b><span>Siguiendo</span></li>
            <li><svg viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg><b><%= nValoraciones %></b><span>Valoraciones</span></li>
            <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="8" x2="21" y1="6" y2="6"/><line x1="8" x2="21" y1="12" y2="12"/><line x1="8" x2="21" y1="18" y2="18"/><line x1="3" x2="3.01" y1="6" y2="6"/><line x1="3" x2="3.01" y1="12" y2="12"/><line x1="3" x2="3.01" y1="18" y2="18"/></svg><b><%= nListas %></b><span>Listas</span></li>
            <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg><b><%= nObras %></b><span>Obras publicadas</span></li>
          </ul>
        </div>
      </div>

      <div class="cuenta-lado cuenta-lado-redes">
        <h2 class="cuenta-redes-titulo">Encuéntrame en:</h2>
        <% if (enlacesCuenta.isEmpty()) { %>
        <p class="muted">Aún no has añadido tus redes. Usa el lápiz para agregarlas.</p>
        <% } else { %>
        <ul class="cuenta-redes">
          <% for (String[] en : enlacesCuenta) { %>
          <li><a class="cuenta-red" href="<%= esc(en[1]) %>" target="_blank" rel="noopener noreferrer nofollow"
                 title="<%= nombreRed(en[0]) %>"><%= iconoRed(en[0]) %><span><%= nombreRed(en[0]) %></span></a></li>
          <% } %>
        </ul>
        <% } %>
      </div>
    </div>

    <a class="cuenta-edit" href="<%= contexto %>/perfil#editar-perfil" aria-label="Editar perfil" title="Editar perfil">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/></svg>
    </a>
  </section>

  <!-- CONTENIDO: izquierda = más sobre mí, siguiendo y seguidores; derecha = el resto -->
  <section class="block">
    <div class="wrap">
      <div class="cuenta-cols">

        <aside class="cuenta-col-izq">
          <article class="cuenta-panel" id="mas-sobre-mi">
            <h3>Más sobre mí</h3>
            <% if (bioCuenta.isEmpty()) { %>
            <p class="muted">Aún no has escrito nada sobre ti. Usa el lápiz de arriba para añadir tu descripción.</p>
            <% } else { %>
            <p class="cuenta-bio"><%= bioCuenta %></p>
            <% } %>
          </article>

          <article class="cuenta-panel" id="siguiendo">
            <h3>Siguiendo <span class="cuenta-count"><%= nSeguidos %></span></h3>
            <% if (siguiendoLista.isEmpty()) { %>
            <p class="muted">Aún no sigues a ningún autor.</p>
            <% } else { %>
            <ul class="cuenta-personas">
              <% for (String[] pr : siguiendoLista) { %><%= filaPersona(pr, contexto) %><% } %>
            </ul>
            <% if (est[4] > siguiendoLista.size()) { %>
            <p class="cuenta-mas">y <%= est[4] - siguiendoLista.size() %> más</p>
            <% } %>
            <% } %>
          </article>

          <article class="cuenta-panel" id="seguidores">
            <h3>Seguidores <span class="cuenta-count"><%= nSeguidores %></span></h3>
            <% if (seguidoresLista.isEmpty()) { %>
            <p class="muted">Todavía nadie te sigue.</p>
            <% } else { %>
            <ul class="cuenta-personas">
              <% for (String[] pr : seguidoresLista) { %><%= filaPersona(pr, contexto) %><% } %>
            </ul>
            <% if (est[0] > seguidoresLista.size()) { %>
            <p class="cuenta-mas">y <%= est[0] - seguidoresLista.size() %> más</p>
            <% } %>
            <% } %>
          </article>
          <article class="cuenta-panel" id="movimientos">
            <h3>Monedas ganadas</h3>
            <p class="muted">El detalle de cómo ha crecido tu saldo.</p>
            <ul class="moves">
              <li class="move">
                <span class="coin sm" aria-hidden="true">S</span>
                <div class="move-text"><b>Bono de bienvenida</b><small>Por ser tu primera vez en SAFIR al registrarte</small></div>
                <span class="plus">+1,000</span>
              </li>
            </ul>
            <div class="total-row"><span>Saldo actual</span><b><%= monedasTxt %> monedas</b></div>
          </article>
        </aside>

        <div class="cuenta-col-der">
          <!-- ACCESOS -->
          <div class="cuenta-bloque" id="accesos">
            <h2>Accesos</h2>
            <div class="cuenta-accesos">
              <a class="cuenta-acceso" href="<%= contexto %>/biblioteca"><b>Mi biblioteca</b><small>Tus lecturas guardadas</small></a>
              <a class="cuenta-acceso" href="<%= contexto %>/billetera"><b>Mi billetera</b><small>Monedas y compras</small></a>
              <a class="cuenta-acceso" href="<%= contexto %>/notificaciones"><b>Mis notificaciones</b><small>Novedades de tus obras</small></a>
              <a class="cuenta-acceso" href="<%= contexto %>/mensajes" data-pendiente><b>Mis mensajes</b><small>Próximamente</small></a>
            </div>
          </div>

          <!-- MIS OBRAS Y LISTAS: tres bloques -->
          <div class="cuenta-bloque" id="mis-obras">
            <h2>Mis obras y listas</h2>

            <!-- Bloque 1: obras publicadas -->
            <section class="mo-bloque" id="obras-publicadas" aria-labelledby="mo-t1">
              <header class="mo-cab">
                <h3 id="mo-t1">Mis obras publicadas <span class="cuenta-count"><%= obrasPub.size() %></span></h3>
              </header>
              <% if (obrasPub.isEmpty()) { %>
              <div class="mo-vacio">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg>
                <p>¡Ups! Aún no tienes obras.</p>
              </div>
              <% } else { %>
              <ul class="mo-lista">
                <% for (String[] ob : obrasPub) { %><%= tarjetaObra(ob, contexto, false) %><% } %>
              </ul>
              <% } %>
            </section>

            <!-- Bloque 2: borradores -->
            <section class="mo-bloque" id="obras-borradores" aria-labelledby="mo-t2">
              <header class="mo-cab">
                <h3 id="mo-t2">Mis borradores <span class="cuenta-count"><%= obrasBor.size() %></span></h3>
                <% if (esAutor) { %>
                <a class="mo-crear" href="<%= contexto %>/autor/obra/nueva">+ Crear</a>
                <% } else { %>
                <form method="post" action="<%= contexto %>/auth/ser-autor" class="mo-crear-form">
                  <button type="submit" class="mo-crear">+ Crear</button>
                </form>
                <% } %>
              </header>
              <% if (obrasBor.isEmpty()) { %>
              <div class="mo-vacio">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/></svg>
                <p>Anímate, aún estás a tiempo de hacer volar tu imaginación.</p>
              </div>
              <% } else { %>
              <ul class="mo-lista">
                <% for (String[] ob : obrasBor) { %><%= tarjetaObra(ob, contexto, true) %><% } %>
              </ul>
              <% } %>
            </section>

            <!-- Bloque 3: listas -->
            <section class="mo-bloque" id="obras-listas" aria-labelledby="mo-t3">
              <header class="mo-cab">
                <h3 id="mo-t3">Mis listas <span class="cuenta-count"><%= listasUsuario.size() %></span></h3>
              </header>
              <% if (listasUsuario.isEmpty()) { %>
              <div class="mo-vacio">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="8" x2="21" y1="6" y2="6"/><line x1="8" x2="21" y1="12" y2="12"/><line x1="8" x2="21" y1="18" y2="18"/><line x1="3" x2="3.01" y1="6" y2="6"/><line x1="3" x2="3.01" y1="12" y2="12"/><line x1="3" x2="3.01" y1="18" y2="18"/></svg>
                <p>Aún no tienes listas.</p>
              </div>
              <% } else { %>
              <ul class="mo-listas">
                <% for (String[] li : listasUsuario) { %><%= tarjetaLista(li) %><% } %>
              </ul>
              <% } %>
            </section>
          </div>
        </div>

      </div>
    </div>
  </section>
</main>

<footer>
  <div class="wrap">
    <a class="brand" href="<%= contexto %>/auth/inicio" aria-label="SAFIR, inicio">
      <svg viewBox="0 0 380 280" aria-hidden="true"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </a>
    <span>Tus historias, en un solo lugar.</span>
  </div>
</footer>

<script src="<%= contexto %>/assets/js/inicio.js"></script>
<script src="<%= contexto %>/assets/js/cuenta.js"></script>
</body>
</html>
