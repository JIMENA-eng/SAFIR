<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<c:set var="esAutor" value="false"/>
<c:forEach var="rol" items="${sessionScope.roles}">
    <c:if test="${rol.toString().trim() == 'autor'}">
        <c:set var="esAutor" value="true"/>
    </c:if>
</c:forEach>

<%@ include file="/WEB-INF/vistas/comunes/encabezado-datos.jspf" %>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Mi perfil · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,300;7..72,400;7..72,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="${ctx}/assets/inicio/encabezadoinicio.css">
<link rel="stylesheet" href="${ctx}/assets/perfil/perfil.css">
<script>
  // Mismo modo claro/noche que el resto de SAFIR
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}
</script>
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/encabezado.jspf" %>

<main class="pf-main">

    <c:if test="${param.ok == '1'}"><p class="aviso ok" role="status">Perfil actualizado.</p></c:if>
    <c:if test="${param.error == 'autor'}"><p class="aviso error" role="alert">No se pudo activar el rol de autor. Inténtalo de nuevo.</p></c:if>
    <c:if test="${not empty error}"><p class="aviso error" role="alert"><c:out value="${error}"/></p></c:if>

    <!-- Cabecera -->
    <section class="pf-hero" aria-label="Tu perfil">
        <div class="pf-cover">
            <img id="portadaImg" alt="Portada"
                 <c:if test="${empty portadaRuta}">hidden</c:if>
                 <c:if test="${not empty portadaRuta}">src="${ctx}/media/<c:out value='${portadaRuta}'/>"</c:if>>
        </div>
        <div class="pf-body">
            <div class="pf-avatar">
                <span id="avatarInicial"
                      <c:if test="${not empty avatarRuta}">hidden</c:if>>${fn:toUpperCase(fn:substring(sessionScope.nombreUsuario, 0, 1))}</span>
                <img id="avatarImg" alt="Foto de perfil"
                     <c:if test="${empty avatarRuta}">hidden</c:if>
                     <c:if test="${not empty avatarRuta}">src="${ctx}/media/<c:out value='${avatarRuta}'/>"</c:if>>
            </div>
            <h1 class="pf-nombre"><c:out value="${not empty menuSobrenombre ? menuSobrenombre : sessionScope.nombreUsuario}"/></h1>
            <c:if test="${not empty menuUsuario}"><p class="pf-user">@<c:out value="${menuUsuario}"/></p></c:if>
            <c:if test="${not empty menuBiografia}"><p class="pf-bio"><c:out value="${menuBiografia}"/></p></c:if>
            <c:if test="${not empty enlaces}">
                <ul class="pf-enlaces">
                    <c:forEach var="e" items="${enlaces}">
                        <li><a href="<c:out value='${e[1]}'/>" target="_blank" rel="noopener noreferrer nofollow"><c:out value="${e[0]}"/></a></li>
                    </c:forEach>
                </ul>
            </c:if>
            <div class="pf-roles">
                <c:forEach var="rol" items="${sessionScope.roles}">
                    <span class="pf-chip"><c:out value="${rol}"/></span>
                </c:forEach>
            </div>
        </div>
    </section>

    <!-- Editar perfil -->
    <section class="seccion" id="editar-perfil">
        <h2>Editar perfil</h2>
        <form class="panel pf-form" method="post" action="${ctx}/perfil" enctype="multipart/form-data">
            <p class="ayuda">Formatos JPG, PNG o WebP. Foto de perfil hasta 2 MB y portada hasta 5 MB.</p>
            <div class="subidas">
                <label class="subida">
                    <strong>Foto de perfil</strong>
                    <span id="avatarNombre">Ningún archivo seleccionado</span>
                    <input type="file" name="avatar" id="avatarInput" accept="image/png,image/jpeg,image/webp">
                </label>
                <label class="subida">
                    <strong>Portada</strong>
                    <span id="portadaNombre">Ningún archivo seleccionado</span>
                    <input type="file" name="portada" id="portadaInput" accept="image/png,image/jpeg,image/webp">
                </label>
            </div>

            <label class="pf-campo">Sobrenombre
                <input type="text" name="nombre" maxlength="60" required
                       value="<c:out value='${not empty fNombre ? fNombre : menuSobrenombre}'/>">
            </label>

            <label class="pf-campo">Nombre de usuario
                <input type="text" name="usuario" maxlength="30" required pattern="[A-Za-z0-9_.]{3,30}"
                       value="<c:out value='${not empty fUsuario ? fUsuario : menuUsuario}'/>">
                <span class="pf-ayuda">3 a 30 caracteres: letras, números, _ y .</span>
            </label>

            <label class="pf-campo">Descripción
                <textarea name="biografia" maxlength="300" rows="4"
                          placeholder="Cuéntales a tus lectores quién eres"><c:out value="${not empty fBio ? fBio : menuBiografia}"/></textarea>
                <span class="pf-ayuda">Hasta 300 caracteres.</span>
            </label>

            <fieldset class="pf-redes">
                <legend>Redes sociales y enlaces (hasta 5)</legend>
                <c:forEach begin="0" end="4" varStatus="s">
                    <c:set var="en" value="${enlaces[s.index]}"/>
                    <div class="pf-fila">
                        <select name="red" aria-label="Red ${s.index + 1}">
                            <c:forTokens var="r" items="instagram,facebook,x,tiktok,youtube,web,otro" delims=",">
                                <option value="${r}" ${en != null && en[0] == r ? 'selected' : ''}>${r}</option>
                            </c:forTokens>
                        </select>
                        <input type="text" name="url" maxlength="255" placeholder="https://..."
                               aria-label="Enlace ${s.index + 1}"
                               value="<c:out value='${en != null ? en[1] : ""}'/>">
                    </div>
                </c:forEach>
            </fieldset>

            <div class="acciones">
                <button class="btn" type="submit">Guardar cambios</button>
            </div>
        </form>
    </section>

    <!-- Ser autor -->
    <c:if test="${not esAutor}">
        <section class="seccion">
            <div class="panel autor-cta">
                <div>
                    <h3>¿Quieres publicar tus obras?</h3>
                    <p>Activa el rol de autor para crear obras y capítulos.</p>
                </div>
                <form method="post" action="${ctx}/auth/ser-autor">
                    <button class="btn" type="submit">Quiero ser autor</button>
                </form>
            </div>
        </section>
    </c:if>
</main>

<script>
(function () {
  // Vista previa al elegir una imagen (antes de guardar)
  function vincular(inputId, nombreId, imgId, inicialId) {
    var input = document.getElementById(inputId);
    input.addEventListener('change', function () {
      var f = input.files && input.files[0];
      document.getElementById(nombreId).textContent = f ? f.name : 'Ningún archivo seleccionado';
      if (!f) return;
      var img = document.getElementById(imgId);
      img.src = URL.createObjectURL(f);
      img.hidden = false;
      if (inicialId) document.getElementById(inicialId).hidden = true;
    });
  }
  vincular('avatarInput', 'avatarNombre', 'avatarImg', 'avatarInicial');
  vincular('portadaInput', 'portadaNombre', 'portadaImg', null);
})();
</script>
<script src="${ctx}/assets/js/inicio.js"></script>
</body>
</html>