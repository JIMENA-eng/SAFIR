<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Notificaciones - SAFIR</title>
    <link rel="stylesheet"
          href="${pageContext.request.contextPath}/assets/css/estilos.css">
</head>
<body>

<main>
    <h1>Mis notificaciones</h1>

    <p>
        Notificaciones pendientes:
        <strong><c:out value="${pendientes}"/></strong>
    </p>

    <c:if test="${pendientes > 0}">
        <form method="post"
              action="${pageContext.request.contextPath}/notificaciones">
            <input type="hidden" name="accion" value="leerTodas">
            <button type="submit">
                Marcar todas como leídas
            </button>
        </form>
    </c:if>

    <c:choose>
        <c:when test="${empty notificaciones}">
            <p>No tienes notificaciones todavía.</p>
        </c:when>

        <c:otherwise>
            <c:forEach var="n" items="${notificaciones}">
                <article class="${n.leida ? 'notificacion-leida' : 'notificacion-pendiente'}">

                    <h2>
                        <c:out value="${n.tipo}"/>
                    </h2>

                    <p>
                        <c:out value="${n.mensaje}"/>
                    </p>

                    <p>
                        <small>
                            <c:out value="${n.creadoEn}"/>
                        </small>
                    </p>

                    <c:choose>
                        <c:when test="${not empty n.capituloId and not empty n.obraId}">
                            <a href="${pageContext.request.contextPath}/lectura?obraId=${n.obraId}&capituloId=${n.capituloId}">
                                Abrir capítulo
                            </a>
                        </c:when>

                        <c:when test="${not empty n.obraId}">
                            <a href="${pageContext.request.contextPath}/obra?id=${n.obraId}">
                                Ver obra
                            </a>
                        </c:when>
                    </c:choose>

                    <c:if test="${not n.leida}">
                        <form method="post"
                              action="${pageContext.request.contextPath}/notificaciones">
                            <input type="hidden" name="accion" value="leer">
                            <input type="hidden" name="notificacionId"
                                   value="${n.id}">
                            <button type="submit">
                                Marcar como leída
                            </button>
                        </form>
                    </c:if>

                    <hr>
                </article>
            </c:forEach>
        </c:otherwise>
    </c:choose>

</main>

</body>
</html>
