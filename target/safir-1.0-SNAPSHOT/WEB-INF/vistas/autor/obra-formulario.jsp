<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%--
    Formulario de obra (crear / editar). Lo usa ObraEdicionServlet.
    Atributos: generos (lista de {id, nombre}), modoEdicion, obra (mapa, solo al editar),
    error y los valores *Formulario cuando se vuelve a mostrar tras un error de validación.
--%>
<c:set var="tituloSel"
       value="${not empty tituloFormulario ? tituloFormulario : (modoEdicion ? obra.titulo : '')}"/>
<c:set var="descripcionSel"
       value="${not empty descripcionFormulario ? descripcionFormulario : (modoEdicion ? obra.descripcion : '')}"/>
<c:set var="generoSel"
       value="${not empty generoFormulario ? generoFormulario : (modoEdicion ? obra.generoId : '')}"/>
<c:set var="clasificacionSel"
       value="${not empty clasificacionFormulario ? clasificacionFormulario : (modoEdicion ? obra.clasificacion : 'todo_publico')}"/>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>
        <c:choose>
            <c:when test="${modoEdicion}">Editar obra</c:when>
            <c:otherwise>Nueva obra</c:otherwise>
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
            <c:when test="${modoEdicion}">Editar obra</c:when>
            <c:otherwise>Crear una obra</c:otherwise>
        </c:choose>
    </h1>

    <c:if test="${not empty error}">
        <div class="mensaje-error" role="alert">
            <c:out value="${error}"/>
        </div>
    </c:if>

    <c:choose>
        <c:when test="${modoEdicion}">
            <c:url var="urlFormulario" value="/autor/obra/editar">
                <c:param name="id" value="${obra.id}"/>
            </c:url>
        </c:when>
        <c:otherwise>
            <c:url var="urlFormulario" value="/autor/obra/nueva"/>
        </c:otherwise>
    </c:choose>

    <form method="post" action="${urlFormulario}">

        <div class="campo">
            <label for="titulo">Título *</label>
            <input type="text" id="titulo" name="titulo"
                   maxlength="100" required
                   value="<c:out value='${tituloSel}'/>">
            <small>Máximo 100 caracteres.</small>
        </div>

        <div class="campo">
            <label for="descripcion">Descripción</label>
            <textarea id="descripcion" name="descripcion"
                      rows="6"><c:out value="${descripcionSel}"/></textarea>
        </div>

        <div class="campo">
            <label for="generoId">Género *</label>
            <select id="generoId" name="generoId" required>
                <option value="">Selecciona un género</option>
                <c:forEach var="g" items="${generos}">
                    <option value="${g.id}" ${g.id == generoSel ? 'selected' : ''}>
                        <c:out value="${g.nombre}"/>
                    </option>
                </c:forEach>
            </select>
        </div>

        <div class="campo">
            <label for="clasificacion">Clasificación *</label>
            <select id="clasificacion" name="clasificacion" required>
                <option value="todo_publico"
                        ${clasificacionSel == 'todo_publico' ? 'selected' : ''}>
                    Todo público
                </option>
                <option value="mayores_13"
                        ${clasificacionSel == 'mayores_13' ? 'selected' : ''}>
                    Mayores de 13
                </option>
                <option value="mayores_18"
                        ${clasificacionSel == 'mayores_18' ? 'selected' : ''}>
                    Mayores de 18 (+18)
                </option>
            </select>
        </div>

        <div class="acciones-formulario">
            <button type="submit">
                <c:choose>
                    <c:when test="${modoEdicion}">Guardar cambios</c:when>
                    <c:otherwise>Crear obra</c:otherwise>
                </c:choose>
            </button>

            <a href="${pageContext.request.contextPath}/autor/panel">Cancelar</a>
        </div>
    </form>
</main>

</body>
</html>
