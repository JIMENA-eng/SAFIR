<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ include file="/WEB-INF/vistas/comunes/encabezado-datos.jspf" %>
<%--
    Mi biblioteca. Lo usa BibliotecaServlet (GET /biblioteca).
    Atributo: obras (lista de Obra con estadoBiblioteca y favorita).
    Las acciones (estado, favorito, eliminar) son POST a /biblioteca, igual que antes.
    El encabezado es el compartido (encabezado-datos.jspf + encabezado.jspf), igual que en Mi cuenta y Obra.
--%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Mi biblioteca · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,300;7..72,400;7..72,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/inicio/encabezadoinicio.css">
<link rel="stylesheet" href="<%= contexto %>/assets/biblioteca/biblioteca.css">
<script>
  // Mismo modo claro/noche que el resto de SAFIR
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}
</script>
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/encabezado.jspf" %>

<main class="bi-main">

  <a class="bi-volver" href="<%= contexto %>/auth/cuenta">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
    Volver a Mi cuenta
  </a>

  <div class="bi-titulo">
    <h1>Mi biblioteca</h1>
    <p>Tus lecturas guardadas, organizadas por cómo vas con cada una.</p>
  </div>

  <c:choose>
    <c:when test="${empty obras}">
      <div class="bi-vacio">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg>
        <p><b>Aún no tienes obras en tu biblioteca.</b></p>
        <p>Explora el catálogo y guarda las historias que quieras leer.</p>
        <a class="btn" href="<%= contexto %>/catalogo">Explorar catálogo</a>
      </div>
    </c:when>

    <c:otherwise>
      <!-- Filtros (los cuenta y aplica biblioteca.js sin recargar la página) -->
      <div class="bi-filtros" role="group" aria-label="Filtrar por estado">
        <button type="button" class="bi-filtro activo" data-filtro="todas" aria-pressed="true">Todas <span class="bi-n">0</span></button>
        <button type="button" class="bi-filtro" data-filtro="favoritas" aria-pressed="false">Favoritas <span class="bi-n">0</span></button>
        <button type="button" class="bi-filtro" data-filtro="por_leer" aria-pressed="false">Por leer <span class="bi-n">0</span></button>
        <button type="button" class="bi-filtro" data-filtro="leyendo" aria-pressed="false">Leyendo <span class="bi-n">0</span></button>
        <button type="button" class="bi-filtro" data-filtro="terminada" aria-pressed="false">Terminadas <span class="bi-n">0</span></button>
        <button type="button" class="bi-filtro" data-filtro="abandonada" aria-pressed="false">Abandonadas <span class="bi-n">0</span></button>
      </div>

      <ul class="bi-grid" id="biGrid">
        <c:forEach var="obra" items="${obras}">
          <li class="bi-card" data-estado="${obra.estadoBiblioteca}" data-fav="${obra.favorita}">

            <a class="bi-portada" href="<%= contexto %>/obra?id=${obra.id}" aria-label="Ver <c:out value='${obra.titulo}'/>">
              <c:choose>
                <c:when test="${not empty obra.portadaRuta}">
                  <img src="<%= contexto %>/media/<c:out value='${obra.portadaRuta}'/>" alt="" loading="lazy">
                </c:when>
                <c:otherwise>
                  <span aria-hidden="true"><c:out value="${not empty obra.titulo ? fn:toUpperCase(fn:substring(obra.titulo, 0, 1)) : '?'}"/></span>
                </c:otherwise>
              </c:choose>
            </a>

            <div class="bi-info">
              <h2><a href="<%= contexto %>/obra?id=${obra.id}"><c:out value="${obra.titulo}"/></a></h2>
              <p class="bi-autor">de <c:out value="${obra.autor}"/></p>
              <p class="bi-etiquetas">
                <c:if test="${not empty obra.genero}"><span class="bi-etiqueta"><c:out value="${obra.genero}"/></span></c:if>
                <span class="bi-etiqueta alt"><c:out value="${obra.capitulosPublicados}"/> cap.</span>
              </p>

              <!-- Estado de lectura: se guarda al elegir una opción -->
              <form class="bi-estado" method="post" action="<%= contexto %>/biblioteca">
                <input type="hidden" name="obraId" value="${obra.id}">
                <input type="hidden" name="accion" value="estado">
                <label class="bi-sr" for="estado-${obra.id}">Estado de lectura</label>
                <select id="estado-${obra.id}" name="estado" data-autoenviar>
                  <option value="por_leer"   ${obra.estadoBiblioteca == 'por_leer'   ? 'selected' : ''}>Por leer</option>
                  <option value="leyendo"    ${obra.estadoBiblioteca == 'leyendo'    ? 'selected' : ''}>Leyendo</option>
                  <option value="terminada"  ${obra.estadoBiblioteca == 'terminada'  ? 'selected' : ''}>Terminada</option>
                  <option value="abandonada" ${obra.estadoBiblioteca == 'abandonada' ? 'selected' : ''}>Abandonada</option>
                </select>
                <noscript><button type="submit" class="btn outline small">Guardar</button></noscript>
              </form>
            </div>

            <div class="bi-acciones">
              <form method="post" action="<%= contexto %>/biblioteca">
                <input type="hidden" name="obraId" value="${obra.id}">
                <input type="hidden" name="accion" value="favorito">
                <input type="hidden" name="favorita" value="${!obra.favorita}">
                <button type="submit" class="bi-icono ${obra.favorita ? 'on' : ''}"
                        aria-pressed="${obra.favorita}"
                        title="${obra.favorita ? 'Quitar de favoritos' : 'Marcar como favorita'}"
                        aria-label="${obra.favorita ? 'Quitar de favoritos' : 'Marcar como favorita'}">
                  <svg viewBox="0 0 24 24" fill="${obra.favorita ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg>
                </button>
              </form>

              <form method="post" action="<%= contexto %>/biblioteca"
                    data-confirmar="¿Quitar esta obra de tu biblioteca?">
                <input type="hidden" name="obraId" value="${obra.id}">
                <input type="hidden" name="accion" value="eliminar">
                <button type="submit" class="bi-icono peligro" title="Eliminar de mi biblioteca" aria-label="Eliminar de mi biblioteca">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 6h18"/><path d="M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2"/><path d="m19 6-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/></svg>
                </button>
              </form>
            </div>
          </li>
        </c:forEach>
      </ul>

      <p class="bi-sin-resultados" id="biSinResultados" hidden>No hay obras con este filtro.</p>
    </c:otherwise>
  </c:choose>

</main>

<script src="<%= contexto %>/assets/js/inicio.js"></script>
<script src="<%= contexto %>/assets/js/biblioteca.js"></script>
</body>
</html>
