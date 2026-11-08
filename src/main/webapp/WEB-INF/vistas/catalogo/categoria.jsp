<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><c:out value="${genero.nombre}"/> · Catálogo | SAFIR</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/catalogo/catalogo.css">
</head>

<body>

<%@ include file="/WEB-INF/vistas/catalogo/navbar.jspf" %>

<main class="container">

    <p class="breadcrumb">
        <a href="${pageContext.request.contextPath}/catalogo">Catálogo</a>
        › <c:out value="${genero.nombre}"/>
    </p>

    <section class="hero">
        <span class="hero-icon" aria-hidden="true"><c:out value="${genero.icono}"/></span>
        <h1><c:out value="${genero.nombre}"/></h1>
        <p>
            <c:choose>
                <c:when test="${genero.totalObras == 0}">
                    Todavía no hay obras publicadas en esta categoría.
                </c:when>
                <c:when test="${genero.totalObras == 1}">
                    1 obra publicada en esta categoría.
                </c:when>
                <c:otherwise>
                    <c:out value="${genero.totalObras}"/> obras publicadas en esta categoría.
                </c:otherwise>
            </c:choose>
        </p>
    </section>

    <!-- Saltar a otra categoría sin volver al catálogo -->
    <nav class="chips" aria-label="Otras categorías">
        <a class="chip" href="${pageContext.request.contextPath}/catalogo">Todas</a>
        <c:forEach var="g" items="${generos}">
            <a class="chip" href="${pageContext.request.contextPath}/catalogo/categoria?id=${g.id}"
               <c:if test="${g.id == genero.id}">aria-current="page"</c:if>>
                <c:out value="${g.nombre}"/>
            </a>
        </c:forEach>
    </nav>

    <section class="search-card">
        <h2>Buscar en <c:out value="${genero.nombre}"/></h2>

        <form class="search-form" method="get"
              action="${pageContext.request.contextPath}/catalogo/categoria">

            <input type="hidden" name="id" value="${genero.id}">

            <div class="field">
                <label for="q">Título, autor o etiqueta</label>
                <input type="text" id="q" name="q"
                       placeholder="¿Qué historia buscas?"
                       value="<c:out value='${busqueda}'/>">
            </div>

            <button class="btn" type="submit">Buscar</button>

            <a class="btn btn-clear"
               href="${pageContext.request.contextPath}/catalogo/categoria?id=${genero.id}">
                Limpiar
            </a>
        </form>
    </section>

    <section>
        <div class="section-title">
            <c:choose>
                <c:when test="${not empty busqueda}">
                    <h2>Resultados para «<c:out value="${busqueda}"/>»</h2>
                </c:when>
                <c:otherwise>
                    <h2>Obras de <c:out value="${genero.nombre}"/></h2>
                </c:otherwise>
            </c:choose>
            <span class="result-count"><c:out value="${obras.size()}"/> obras</span>
        </div>

        <c:choose>
            <c:when test="${not empty busqueda}">
                <c:set var="vacioTitulo" value="No encontramos obras"/>
                <c:set var="vacioTexto" value="Ninguna obra de esta categoría coincide con tu búsqueda."/>
            </c:when>
            <c:otherwise>
                <c:set var="vacioTitulo" value="Aún no hay obras en ${genero.nombre}"/>
                <c:set var="vacioTexto" value="Vuelve pronto o explora otra categoría."/>
            </c:otherwise>
        </c:choose>

        <%@ include file="/WEB-INF/vistas/catalogo/obras-grid.jspf" %>
    </section>

    <div style="text-align:center;">
        <a class="library-link"
           href="${pageContext.request.contextPath}/catalogo">
            ← Volver a todas las categorías
        </a>
    </div>

</main>

<footer>
    SAFIR · Un lugar para descubrir y compartir historias ✦
</footer>

</body>
</html>
