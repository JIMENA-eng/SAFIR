<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Catálogo de obras | SAFIR</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/catalogo/catalogo.css">
</head>

<body>

<%@ include file="/WEB-INF/vistas/catalogo/navbar.jspf" %>

<main class="container">

    <section class="hero">
        <h1>Descubre nuevas historias</h1>
        <p>
            Un universo de historias te espera.
            Elige una categoría o busca por título o autor
            y encuentra tu próxima lectura favorita.
        </p>
    </section>

    <!-- DESGLOSE DE CATEGORÍAS: cada tarjeta abre su propia página -->
    <section class="categories" aria-labelledby="titCategorias">
        <div class="section-title">
            <h2 id="titCategorias">Explora por categoría</h2>
        </div>
        <p class="sec-lead">Toca una categoría para ver solo las obras de ese género.</p>

        <c:choose>
            <c:when test="${empty generos}">
                <p class="sec-lead">Aún no hay categorías registradas.</p>
            </c:when>
            <c:otherwise>
                <div class="cat-grid">
                    <c:forEach var="g" items="${generos}">
                        <a class="cat-card${g.totalObras == 0 ? ' vacia' : ''}"
                           href="${pageContext.request.contextPath}/catalogo/categoria?id=${g.id}">
                            <span class="cat-icon" aria-hidden="true"><c:out value="${g.icono}"/></span>
                            <span>
                                <b><c:out value="${g.nombre}"/></b>
                                <small>
                                    <c:choose>
                                        <c:when test="${g.totalObras == 1}">1 obra</c:when>
                                        <c:otherwise><c:out value="${g.totalObras}"/> obras</c:otherwise>
                                    </c:choose>
                                </small>
                            </span>
                        </a>
                    </c:forEach>
                </div>
            </c:otherwise>
        </c:choose>
    </section>

    <section class="search-card">
        <h2>Encuentra tu próxima lectura</h2>

        <form class="search-form" method="get"
              action="${pageContext.request.contextPath}/catalogo">

            <div class="field">
                <label for="q">Buscar por título, autor o etiqueta</label>
                <input type="text" id="q" name="q"
                       placeholder="¿Qué historia buscas?"
                       value="<c:out value='${busqueda}'/>">
            </div>

            <button class="btn" type="submit">Buscar obras</button>

            <a class="btn btn-clear"
               href="${pageContext.request.contextPath}/catalogo">
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
                    <h2>Todas las historias</h2>
                </c:otherwise>
            </c:choose>
            <span class="result-count"><c:out value="${obras.size()}"/> obras</span>
        </div>

        <c:choose>
            <c:when test="${not empty busqueda}">
                <c:set var="vacioTitulo" value="No encontramos obras"/>
                <c:set var="vacioTexto" value="Prueba con otras palabras o explora una categoría."/>
            </c:when>
            <c:otherwise>
                <c:set var="vacioTitulo" value="Aún no hay historias disponibles"/>
                <c:set var="vacioTexto" value="Estamos preparando este espacio para ti. Pronto encontrarás nuevas historias para leer y disfrutar en SAFIR."/>
            </c:otherwise>
        </c:choose>

        <%@ include file="/WEB-INF/vistas/catalogo/obras-grid.jspf" %>
    </section>

    <div style="text-align:center;">
        <a class="library-link"
           href="${pageContext.request.contextPath}/biblioteca">
            ♡ Ir a mi biblioteca
        </a>
    </div>

</main>

<footer>
    SAFIR · Un lugar para descubrir y compartir historias ✦
</footer>

</body>
</html>
