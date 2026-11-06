
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Panel de autor - SAFIR</title>
    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/assets/css/estilos.css">
</head>
<body>

<main>
    <h1>Panel de autor</h1>
    <p>Administra tus obras y revisa sus estadísticas.</p>

    <c:if test="${param.guardado == '1'}">
        <p class="mensaje-exito">La obra se guardó correctamente.</p>
    </c:if>
    <p>
        Para publicar una obra, publica su primer capítulo: la obra se
        publica automáticamente con él. Tus borradores están en
        <a href="${pageContext.request.contextPath}/auth/cuenta#obras-borradores">Mi cuenta</a>.
    </p>

    <a href="${pageContext.request.contextPath}/autor/obra/nueva">
        Crear una obra
    </a>

    <hr>

    <c:choose>
        <c:when test="${empty obras}">
            <p>Todavía no has creado ninguna obra.</p>
        </c:when>

        <c:otherwise>
            <c:forEach var="obra" items="${obras}">
                <section>
                    <h2><c:out value="${obra.titulo}"/></h2>

                    <p>
                        Estado:
                        <c:out value="${obra.estado}"/>
                    </p>

                    <p>
                        Avance:
                        <c:out value="${obra.avance}"/>
                    </p>

                    <p>
                        Capítulos publicados:
                        <c:out value="${obra.capitulosPublicados}"/>
                    </p>

                    <p>
                        Capítulos en borrador:
                        <c:out value="${obra.capitulosBorrador}"/>
                    </p>

                    <p>
                        Lecturas:
                        <c:out value="${obra.totalLecturas}"/>
                    </p>

                    <p>
                        Valoración promedio:
                        <c:out value="${obra.promedio}"/>
                    </p>

                    <p>
                        Seguidores:
                        <c:out value="${obra.totalSeguidores}"/>
                    </p>

                    <a href="${pageContext.request.contextPath}/autor/obra/editar?id=${obra.obraId}">
                        Editar obra
                    </a>

                    <a href="${pageContext.request.contextPath}/autor/capitulos?obraId=${obra.obraId}">
                        Administrar capítulos
                    </a>

                    <c:choose>
                        <c:when test="${obra.estado == 'borrador'}">
                            <small>
                                Borrador: se publicará sola al publicar su primer capítulo.
                            </small>
                        </c:when>

                        <c:when test="${obra.estado == 'publicada'}">
                            <a href="${pageContext.request.contextPath}/obra?id=${obra.obraId}">
                                Ver en el catálogo
                            </a>
                            <form method="post" style="display:inline"
                                  action="${pageContext.request.contextPath}/autor/obra/despublicar">
                                <input type="hidden" name="obraId" value="${obra.obraId}">
                                <button type="submit">Volver a borrador</button>
                            </form>
                        </c:when>
                    </c:choose>

                    <hr>
                </section>
            </c:forEach>
        </c:otherwise>
    </c:choose>
</main>

</body>
</html>
