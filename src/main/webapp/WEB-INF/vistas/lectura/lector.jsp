<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title><c:out value="${capitulo.titulo}"/> - SAFIR</title>
</head>
<body>

<p>
    <a href="${pageContext.request.contextPath}/obra?id=${obraId}">
        Volver a la obra
    </a>
</p>

<h1>
    <c:if test="${not empty capitulo.numero}">
        Capítulo <c:out value="${capitulo.numero}"/>:
    </c:if>
    <c:out value="${capitulo.titulo}"/>
</h1>

<c:if test="${not empty capitulo.palabras}">
    <p><c:out value="${capitulo.palabras}"/> palabras</p>
</c:if>

<%-- Música que el autor guardó con el capítulo (YouTube o archivo de audio) --%>
<c:if test="${not empty pista}">
    <section aria-label="Música del capítulo"
             style="margin: 1rem 0; padding: .8rem 1rem; border: 1px solid #ddd; border-radius: 12px; max-width: 560px;">
        <p style="margin: 0 0 .6rem;">
            🎵 Música del capítulo: <strong><c:out value="${pista.titulo}"/></strong>
        </p>
        <c:choose>
            <c:when test="${pista.youtube}">
                <%-- loop de YouTube necesita playlist=<mismo id> --%>
                <div style="position: relative; width: 100%; aspect-ratio: 16 / 9;">
                    <iframe src="https://www.youtube-nocookie.com/embed/${pista.youtubeId}?rel=0${pista.enBucle ? '&amp;loop=1&amp;playlist='.concat(pista.youtubeId) : ''}"
                            title="Música del capítulo"
                            style="position: absolute; inset: 0; width: 100%; height: 100%; border: 0;"
                            allow="autoplay; encrypted-media; picture-in-picture"
                            allowfullscreen></iframe>
                </div>
            </c:when>
            <c:otherwise>
                <audio controls preload="metadata" style="width: 100%;" ${pista.enBucle ? 'loop' : ''}
                       src="${pageContext.request.contextPath}/media/${pista.archivoRuta}">
                    Tu navegador no puede reproducir este audio.
                </audio>
            </c:otherwise>
        </c:choose>
    </section>
</c:if>

<p>
    <c:if test="${not empty capituloAnterior}">
        <a href="${pageContext.request.contextPath}/lectura?obraId=${obraId}&capituloId=${capituloAnterior.id}">
            &laquo; Capítulo anterior
        </a>
    </c:if>

    <c:if test="${not empty capituloSiguiente}">
        <a href="${pageContext.request.contextPath}/lectura?obraId=${obraId}&capituloId=${capituloSiguiente.id}">
            Capítulo siguiente &raquo;
        </a>
    </c:if>
</p>

<hr>

<div style="white-space: pre-wrap;"><c:out value="${capitulo.contenido}"/></div>

<hr>

<p>
    <c:if test="${not empty capituloAnterior}">
        <a href="${pageContext.request.contextPath}/lectura?obraId=${obraId}&capituloId=${capituloAnterior.id}">
            &laquo; Capítulo anterior
        </a>
    </c:if>

    <c:if test="${not empty capituloSiguiente}">
        <a href="${pageContext.request.contextPath}/lectura?obraId=${obraId}&capituloId=${capituloSiguiente.id}">
            Capítulo siguiente &raquo;
        </a>
    </c:if>
</p>

<h2>Capítulos</h2>

<ul>
    <c:forEach var="cap" items="${capitulos}">
        <li>
            <c:choose>
                <c:when test="${cap.id == capitulo.id}">
                    <strong>
                        <c:out value="${cap.numero}"/>.
                        <c:out value="${cap.titulo}"/>
                    </strong>
                </c:when>
                <c:otherwise>
                    <a href="${pageContext.request.contextPath}/lectura?obraId=${obraId}&capituloId=${cap.id}">
                        <c:out value="${cap.numero}"/>.
                        <c:out value="${cap.titulo}"/>
                        <c:if test="${bloqueados.contains(cap.id)}"> 🔒</c:if>
                    </a>
                </c:otherwise>
            </c:choose>
        </li>
    </c:forEach>
</ul>

<script>
    (function () {
        var url = "${pageContext.request.contextPath}/lectura";
        var obraId = "${obraId}";
        var capituloId = "${capitulo.id}";
        var guardada = Number("${posicionGuardada}") || 0;
        var temporizador = null;

        function maximo() {
            return document.documentElement.scrollHeight - window.innerHeight;
        }

        function posicionActual() {
            var max = maximo();
            if (max <= 0) {
                return 0;
            }
            var p = (window.scrollY / max) * 100;
            return Math.min(100, Math.max(0, p)).toFixed(2);
        }

        // Token CSRF (lo agrega CsrfFilter en el head). Va en el cuerpo porque
        // sendBeacon no permite cabeceras.
        var meta = document.querySelector('meta[name="csrf-token"]');
        var csrf = meta ? meta.getAttribute("content") : "";

        function datos() {
            return new URLSearchParams({
                obraId: obraId,
                capituloId: capituloId,
                posicion: posicionActual(),
                _csrf: csrf
            });
        }

        function guardar() {
            fetch(url, {
                method: "POST",
                body: datos(),
                credentials: "same-origin"
            }).catch(function () {});
        }

        window.addEventListener("load", function () {
            var max = maximo();
            if (guardada > 0 && max > 0) {
                window.scrollTo(0, (guardada / 100) * max);
            }
        });

        window.addEventListener("scroll", function () {
            clearTimeout(temporizador);
            temporizador = setTimeout(guardar, 1500);
        });

        window.addEventListener("pagehide", function () {
            if (navigator.sendBeacon) {
                navigator.sendBeacon(url, datos());
            }
        });
    })();
</script>

</body>
</html>
