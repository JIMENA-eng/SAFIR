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

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Mi perfil · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,300;7..72,400&display=swap" rel="stylesheet">
<style>
  :root {
    --indigo: #252866; --lav: #7775D6; --lav-soft: #E9E7FF; --warm: #FFFCF7; --carbon: #292936;
    --bg: var(--warm); --card: #ffffff; --soft: var(--lav-soft); --text: var(--carbon); --title: var(--indigo);
    --muted: #5b5b72; --line: #E3E0F7; --btn: var(--indigo); --btn-text: #fff; --link: var(--indigo);
    --ok-bg: #E6F4EA; --ok: #1E7A46; --err-bg: #FDECEA; --err: #B3261E;
    --shadow: 0 12px 34px -18px rgba(37,40,102,.35);
    --sans: "DM Sans", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
    --serif: "Literata", Georgia, serif;
  }
  :root[data-theme="dark"] {
    --bg: #12142E; --card: #181B3A; --soft: #20244D; --text: #D9D9E8; --title: #F1F0FF; --muted: #A5A6C4;
    --line: #2C3060; --btn: #7775D6; --btn-text: #12142E; --link: #B9B7F5;
    --ok-bg: #16301f; --ok: #7fd6a0; --err-bg: #3a1b1b; --err: #f1a39d;
    --shadow: 0 12px 34px -18px rgba(0,0,0,.7);
  }
  *, *::before, *::after { box-sizing: border-box; }
  body { margin: 0; background: var(--bg); color: var(--text); font-family: var(--sans); font-size: 1rem; line-height: 1.6; -webkit-font-smoothing: antialiased; }
  h1, h2, h3, p { margin: 0; }
  a { color: var(--link); text-decoration: none; }
  :focus-visible { outline: 3px solid var(--lav); outline-offset: 3px; border-radius: 8px; }

  /* Barra superior */
  .top { display: flex; align-items: center; justify-content: space-between; max-width: 920px; margin: 0 auto; padding: 1rem 1.25rem; }
  .brand { font-weight: 600; letter-spacing: .32em; color: var(--title); font-size: 1.05rem; }
  .top nav { display: flex; align-items: center; gap: .5rem; }
  .pill { display: inline-flex; align-items: center; gap: .4rem; padding: .45rem .95rem; border-radius: 999px; border: 1px solid var(--line);
    background: var(--card); color: var(--title); font: inherit; font-size: .9rem; font-weight: 500; cursor: pointer; }
  .pill:hover { border-color: var(--lav); }

  main { max-width: 920px; margin: 0 auto; padding: 0 1.25rem 3rem; }

  /* Mensajes */
  .aviso { padding: .75rem 1rem; border-radius: 12px; margin-bottom: 1rem; font-size: .95rem; }
  .aviso.ok { background: var(--ok-bg); color: var(--ok); }
  .aviso.error { background: var(--err-bg); color: var(--err); }

  /* Cabecera del perfil */
  .hero { background: var(--card); border: 1px solid var(--line); border-radius: 24px; box-shadow: var(--shadow); overflow: hidden; }
  .cover { position: relative; height: 210px;
    background:
      radial-gradient(circle at 78% 30%, rgba(255,255,255,.55) 0 60px, transparent 62px),
      repeating-radial-gradient(circle at 12% 120%, transparent 0 30px, rgba(255,255,255,.18) 30px 31.5px),
      linear-gradient(135deg, var(--indigo), var(--lav)); }
  .cover img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }
  .hero-body { position: relative; padding: 0 1.75rem 1.6rem; }
  .avatar { width: 112px; height: 112px; border-radius: 50%; margin-top: -56px; overflow: hidden; display: grid; place-items: center;
    background: var(--soft); border: 5px solid var(--card); color: var(--title); font-family: var(--serif); font-size: 2.6rem; position: relative; }
  .avatar img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }
  .nombre { font-family: var(--serif); font-weight: 300; font-size: clamp(1.7rem, 4vw, 2.2rem); color: var(--title); line-height: 1.15; margin-top: .75rem; }
  .roles { display: flex; flex-wrap: wrap; gap: .45rem; margin-top: .6rem; }
  .chip { padding: .2rem .75rem; border-radius: 999px; background: var(--soft); color: var(--title); font-size: .82rem; font-weight: 500; text-transform: capitalize; }

  /* Secciones */
  .seccion { margin-top: 2rem; }
  .seccion > h2 { font-family: var(--serif); font-weight: 300; color: var(--title); font-size: 1.4rem; margin-bottom: .9rem; }
  .panel { background: var(--card); border: 1px solid var(--line); border-radius: 20px; padding: 1.4rem; }
  .panel p.ayuda { color: var(--muted); font-size: .92rem; margin-bottom: 1rem; }

  /* Subida de imágenes */
  .subidas { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
  .subida { display: flex; flex-direction: column; gap: .35rem; padding: 1rem; border: 1.5px dashed var(--line); border-radius: 14px;
    cursor: pointer; transition: border-color .15s, background .15s; }
  .subida:hover, .subida:focus-within { border-color: var(--lav); background: var(--soft); }
  .subida strong { color: var(--title); font-weight: 600; }
  .subida span { color: var(--muted); font-size: .88rem; word-break: break-all; }
  .subida input { position: absolute; width: 1px; height: 1px; opacity: 0; overflow: hidden; }
  .acciones { margin-top: 1.1rem; display: flex; align-items: center; gap: .8rem; flex-wrap: wrap; }

  .btn { display: inline-flex; align-items: center; justify-content: center; padding: .7rem 1.5rem; border: 0; border-radius: 999px;
    background: var(--btn); color: var(--btn-text); font: inherit; font-weight: 600; cursor: pointer; }
  .btn:hover { filter: brightness(1.1); }
  .btn.suave { background: transparent; color: var(--title); border: 1px solid var(--line); }
  .btn.suave:hover { border-color: var(--lav); filter: none; }

  /* Invitación a ser autor */
  .autor-cta { display: flex; align-items: center; justify-content: space-between; gap: 1rem; flex-wrap: wrap;
    background: linear-gradient(135deg, var(--soft), var(--card)); }
  .autor-cta h3 { font-family: var(--serif); font-weight: 300; color: var(--title); font-size: 1.2rem; }
  .autor-cta p { color: var(--muted); font-size: .92rem; margin-top: .2rem; }

  /* Accesos */
  .accesos { display: grid; grid-template-columns: repeat(auto-fill, minmax(210px, 1fr)); gap: 1rem; }
  .acceso { display: flex; flex-direction: column; gap: .25rem; padding: 1.1rem 1.2rem; background: var(--card); border: 1px solid var(--line);
    border-radius: 18px; color: var(--title); transition: transform .15s, border-color .15s, box-shadow .15s; }
  .acceso:hover { transform: translateY(-2px); border-color: var(--lav); box-shadow: var(--shadow); }
  .acceso b { font-weight: 600; }
  .acceso small { color: var(--muted); font-size: .85rem; }
  .acceso.destacado { background: var(--btn); border-color: var(--btn); }
  .acceso.destacado b, .acceso.destacado small { color: var(--btn-text); }

  .salir { margin-top: 2rem; text-align: center; }

  @media (max-width: 600px) {
    .subidas { grid-template-columns: 1fr; }
    .cover { height: 150px; }
    .hero-body { padding: 0 1.1rem 1.3rem; }
  }
  @media (prefers-reduced-motion: reduce) { * { transition: none !important; } }
</style>
<script>
  // Mismo modo claro/noche que el resto de SAFIR
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}
</script>
</head>
<body>

<header class="top">
    <a class="brand" href="${ctx}/catalogo">SAFIR</a>
    <nav>
        <a class="pill" href="${ctx}/catalogo">Catálogo</a>
        <button class="pill" type="button" id="temaBtn" aria-pressed="false">Modo noche</button>
    </nav>
</header>

<main>

    <c:if test="${param.ok == '1'}"><p class="aviso ok" role="status">Imágenes actualizadas.</p></c:if>
    <c:if test="${param.error == 'autor'}"><p class="aviso error" role="alert">No se pudo activar el rol de autor. Inténtalo de nuevo.</p></c:if>
    <c:if test="${not empty error}"><p class="aviso error" role="alert"><c:out value="${error}"/></p></c:if>

    <!-- Cabecera -->
    <section class="hero" aria-label="Tu perfil">
        <div class="cover">
            <img id="portadaImg" alt="Portada"
                 <c:if test="${empty portadaRuta}">hidden</c:if>
                 <c:if test="${not empty portadaRuta}">src="${ctx}/media/<c:out value='${portadaRuta}'/>"</c:if>>
        </div>
        <div class="hero-body">
            <div class="avatar">
                <span id="avatarInicial"
                      <c:if test="${not empty avatarRuta}">hidden</c:if>>${fn:toUpperCase(fn:substring(sessionScope.nombreUsuario, 0, 1))}</span>
                <img id="avatarImg" alt="Foto de perfil"
                     <c:if test="${empty avatarRuta}">hidden</c:if>
                     <c:if test="${not empty avatarRuta}">src="${ctx}/media/<c:out value='${avatarRuta}'/>"</c:if>>
            </div>
            <h1 class="nombre"><c:out value="${sessionScope.nombreUsuario}"/></h1>
            <div class="roles">
                <c:forEach var="rol" items="${sessionScope.roles}">
                    <span class="chip"><c:out value="${rol}"/></span>
                </c:forEach>
            </div>
        </div>
    </section>

    <!-- Imágenes -->
    <section class="seccion">
        <h2>Tus imágenes</h2>
        <form class="panel" method="post" action="${ctx}/perfil" enctype="multipart/form-data">
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
            <div class="acciones">
                <button class="btn" type="submit">Guardar imágenes</button>
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

    <!-- Accesos -->
    <section class="seccion">
        <h2>Accesos</h2>
        <div class="accesos">
            <c:if test="${esAutor}">
                <a class="acceso destacado" href="${ctx}/autor/panel"><b>Panel de autor</b><small>Gestiona tus obras</small></a>
            </c:if>
            <a class="acceso" href="${ctx}/biblioteca"><b>Mi biblioteca</b><small>Tus lecturas guardadas</small></a>
            <a class="acceso" href="${ctx}/billetera"><b>Mi billetera</b><small>Monedas y compras</small></a>
            <a class="acceso" href="${ctx}/notificaciones"><b>Mis notificaciones</b><small>Novedades de tus obras</small></a>
            <a class="acceso" href="${ctx}/auth/cuenta"><b>Mi cuenta</b><small>Datos de tu cuenta</small></a>
            <a class="acceso" href="${ctx}/catalogo"><b>Explorar el catálogo</b><small>Descubre nuevas historias</small></a>
        </div>
    </section>

    <p class="salir"><a class="btn suave" href="${ctx}/auth/logout">Cerrar sesión</a></p>
</main>

<script>
(function () {
  // Modo claro / noche
  var root = document.documentElement, btn = document.getElementById('temaBtn');
  function pintar() {
    var noche = root.getAttribute('data-theme') === 'dark';
    btn.textContent = noche ? 'Modo claro' : 'Modo noche';
    btn.setAttribute('aria-pressed', noche ? 'true' : 'false');
  }
  btn.addEventListener('click', function () {
    var noche = root.getAttribute('data-theme') === 'dark';
    if (noche) root.removeAttribute('data-theme'); else root.setAttribute('data-theme', 'dark');
    try { localStorage.setItem('safir-theme', noche ? 'light' : 'dark'); } catch (e) {}
    pintar();
  });
  pintar();

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
</body>
</html>