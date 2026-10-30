<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>
        <c:choose>
            <c:when test="${not empty capitulo}">Editar capítulo</c:when>
            <c:otherwise>Nuevo capítulo</c:otherwise>
        </c:choose>
        | SAFIR
    </title>
    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/assets/css/estilos.css">
</head>
<body>

<main class="contenedor-formulario">
    <h1>
        <c:choose>
            <c:when test="${not empty capitulo}">Editor de capítulo</c:when>
            <c:otherwise>Escribir un capítulo nuevo</c:otherwise>
        </c:choose>
    </h1>

    <p>Guarda tu avance como borrador y publícalo cuando esté listo.</p>

    <c:if test="${not empty error}">
        <div class="mensaje-error" role="alert">
            <c:out value="${error}"/>
        </div>
    </c:if>

    <c:choose>
        <c:when test="${not empty capitulo}">
            <c:url var="urlFormulario" value="/autor/capitulo/editar">
                <c:param name="id" value="${capitulo.id}"/>
            </c:url>
        </c:when>
        <c:otherwise>
            <c:url var="urlFormulario" value="/autor/capitulo/nuevo"/>
        </c:otherwise>
    </c:choose>

    <form method="post" action="${urlFormulario}">
        <input type="hidden" name="obraId" value="${obraId}">

        <div class="campo">
            <label for="titulo">Título del capítulo *</label>
            <input
                type="text"
                id="titulo"
                name="titulo"
                maxlength="150"
                required
                value="<c:out value='${not empty tituloFormulario ? tituloFormulario : capitulo.titulo}'/>">
            <small>Máximo 150 caracteres.</small>
        </div>

        <div class="campo">
            <label for="contenido">Contenido *</label>
            <textarea
                id="contenido"
                name="contenido"
                rows="22"
                required><c:out value="${not empty contenidoFormulario ? contenidoFormulario : capitulo.contenido}"/></textarea>
        </div>

        <div class="acciones-formulario">
            <button type="submit">Guardar borrador</button>

            <a href="${pageContext.request.contextPath}/autor/capitulos?obraId=${obraId}">
                Cancelar
            </a>
        </div>
    </form>

    <c:if test="${not empty capitulo and capitulo.estado == 'borrador'}">
        <form method="post"
              action="${pageContext.request.contextPath}/autor/capitulo/publicar">
            <input type="hidden" name="id" value="${capitulo.id}">
            <p>
                Guarda primero tus cambios: al publicar se usa la última
                versión guardada del borrador.
            </p>
            <button type="submit">Publicar capítulo</button>
        </form>
    </c:if>
</main>

</body>
</html>
