<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Mis capítulos | SAFIR</title>
    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/assets/css/estilos.css">
</head>
<body>

<main class="contenedor-formulario">
    <h1>Gestión de capítulos</h1>
    <p>Administra los capítulos de tu obra.</p>

    <c:if test="${param.guardado == '1'}">
        <p class="mensaje-exito">El borrador se guardó correctamente.</p>
    </c:if>

    <c:if test="${param.publicado == '1'}">
        <p class="mensaje-exito">El capítulo se publicó correctamente.</p>
    </c:if>

    <p>
        <a href="${pageContext.request.contextPath}/autor/capitulo/nuevo?obraId=${obraId}">
            Crear capítulo
        </a>
    </p>

    <c:choose>
        <c:when test="${empty capitulos}">
            <p>Todavía no tienes capítulos registrados en esta obra.</p>
        </c:when>

        <c:otherwise>
            <table>
                <thead>
                    <tr>
                        <th>Número</th>
                        <th>Título</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="capitulo" items="${capitulos}">
                        <tr>
                            <td>
                                <c:choose>
                                    <c:when test="${not empty capitulo.numero}">
                                        <c:out value="${capitulo.numero}"/>
                                    </c:when>
                                    <c:otherwise>Sin número</c:otherwise>
                                </c:choose>
                            </td>

                            <td><c:out value="${capitulo.titulo}"/></td>
                            <td><c:out value="${capitulo.estado}"/></td>

                            <td>
                                <c:if test="${capitulo.estado == 'borrador'}">
                                    <a href="${pageContext.request.contextPath}/autor/capitulo/editar?id=${capitulo.id}">
                                        Editar
                                    </a>

                                    <form method="post"
                                          action="${pageContext.request.contextPath}/autor/capitulo/publicar"
                                          style="display:inline">
                                        <input type="hidden"
                                               name="id"
                                               value="${capitulo.id}">
                                        <button type="submit">
                                            Publicar
                                        </button>
                                    </form>
                                </c:if>
                            </td>
                        </tr>
                    </c:forEach>
                </tbody>
            </table>
        </c:otherwise>
    </c:choose>

    <p>
        <a href="${pageContext.request.contextPath}/autor/panel">
            Volver al panel del autor
        </a>
    </p>
</main>

</body>
</html>
