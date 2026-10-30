<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Mi biblioteca - SAFIR</title>
</head>
<body>

<h1>Mi biblioteca</h1>

<c:choose>
    <c:when test="${empty obras}">
        <p>Aún no tienes obras en tu biblioteca.</p>
        <a href="${pageContext.request.contextPath}/catalogo">
            Explorar catálogo
        </a>
    </c:when>

    <c:otherwise>
        <c:forEach var="obra" items="${obras}">
            <article>
                <h2>
                    <a href="${pageContext.request.contextPath}/obra?id=${obra.id}">
                        <c:out value="${obra.titulo}"/>
                    </a>
                </h2>

                <p>
                    Autor: <c:out value="${obra.autor}"/>
                </p>

                <p>
                    Estado: <c:out value="${obra.estadoBiblioteca}"/>
                </p>

                <form method="post"
                      action="${pageContext.request.contextPath}/biblioteca">
                    <input type="hidden" name="obraId" value="${obra.id}">
                    <input type="hidden" name="accion" value="estado">

                    <label for="estado-${obra.id}">
                        Estado de lectura
                    </label>

                    <select id="estado-${obra.id}" name="estado">
                        <option value="por_leer"
                            ${obra.estadoBiblioteca == 'por_leer' ? 'selected' : ''}>
                            Por leer
                        </option>
                        <option value="leyendo"
                            ${obra.estadoBiblioteca == 'leyendo' ? 'selected' : ''}>
                            Leyendo
                        </option>
                        <option value="terminada"
                            ${obra.estadoBiblioteca == 'terminada' ? 'selected' : ''}>
                            Terminada
                        </option>
                        <option value="abandonada"
                            ${obra.estadoBiblioteca == 'abandonada' ? 'selected' : ''}>
                            Abandonada
                        </option>
                    </select>

                    <button type="submit">Guardar estado</button>
                </form>

                <form method="post"
                      action="${pageContext.request.contextPath}/biblioteca">
                    <input type="hidden" name="obraId" value="${obra.id}">
                    <input type="hidden" name="accion" value="favorito">
                    <input type="hidden" name="favorita"
                           value="${!obra.favorita}">

                    <button type="submit">
                        <c:choose>
                            <c:when test="${obra.favorita}">
                                Quitar de favoritos
                            </c:when>
                            <c:otherwise>
                                Marcar como favorita
                            </c:otherwise>
                        </c:choose>
                    </button>
                </form>

                <form method="post"
                      action="${pageContext.request.contextPath}/biblioteca">
                    <input type="hidden" name="obraId" value="${obra.id}">
                    <input type="hidden" name="accion" value="eliminar">
                    <button type="submit">Eliminar de mi biblioteca</button>
                </form>

                <hr>
            </article>
        </c:forEach>
    </c:otherwise>
</c:choose>

</body>
</html>
