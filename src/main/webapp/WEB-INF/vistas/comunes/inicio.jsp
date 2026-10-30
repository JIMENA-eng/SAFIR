<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%
    String contexto = request.getContextPath();

    jakarta.servlet.http.HttpSession sesion = request.getSession(false);
    String nombreUsuario = "lector";
    if (sesion != null && sesion.getAttribute("nombreUsuario") != null) {
        nombreUsuario = String.valueOf(sesion.getAttribute("nombreUsuario"));
    }
    // Roles guardados en sesión por LoginServlet (texto "lector, autor", colección o arreglo).
    boolean esAutor = false;
    if (sesion != null && sesion.getAttribute("roles") != null) {
        Object rolesSesion = sesion.getAttribute("roles");
        java.util.List<String> listaRoles = new java.util.ArrayList<String>();
        if (rolesSesion instanceof java.util.Collection<?>) {
            for (Object r : (java.util.Collection<?>) rolesSesion) listaRoles.add(String.valueOf(r));
        } else if (rolesSesion instanceof String[]) {
            for (String r : (String[]) rolesSesion) listaRoles.add(r);
        } else {
            for (String r : String.valueOf(rolesSesion).split("[,;]")) listaRoles.add(r);
        }
        for (String r : listaRoles) {
            String rol = r == null ? "" : r.trim();
            if (rol.equalsIgnoreCase("autor") || rol.equalsIgnoreCase("administrador")) { esAutor = true; }
        }
    }
    String inicial = nombreUsuario.isBlank() ? "S"
            : nombreUsuario.trim().substring(0, 1).toUpperCase();

    nombreUsuario = nombreUsuario
            .replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            .replace("\"", "&quot;").replace("'", "&#39;");
    inicial = inicial
            .replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            .replace("\"", "&quot;").replace("'", "&#39;");
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Inicio · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,400;7..72,500&display=swap" rel="stylesheet">
<style>
  :root {
    --indigo: #252866;
    --lav: #7775D6;
    --lav-soft: #E9E7FF;
    --warm: #FFFCF7;
    --carbon: #292936;
    --gold: #F2B84B;

    --bg: var(--warm);
    --surface: #ffffff;
    --soft: var(--lav-soft);
    --text: var(--carbon);
    --title: var(--indigo);
    --muted: #5b5b72;
    --line: #E3E0F7;
    --bar: var(--indigo);
    --btn: var(--indigo);
    --btn-text: #ffffff;
    --link: var(--indigo);
    --outline: var(--lav);
    --panel: #ffffff;

    --sans: "DM Sans", "Plus Jakarta Sans", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
    --serif: "Literata", "Source Serif 4", Georgia, "Times New Roman", serif;

    box-sizing: border-box;
    padding-top: env(safe-area-inset-top, 0px);
    padding-bottom: env(safe-area-inset-bottom, 0px);
  }
  :root[data-theme="dark"] {
    --bg: #12142E;
    --surface: #1D2042;
    --soft: #181B3A;
    --text: #D9D9E8;
    --title: #F1F0FF;
    --muted: #A5A6C4;
    --line: #2C3060;
    --bar: #1D2042;
    --btn: #7775D6;
    --btn-text: #12142E;
    --link: #B9B7F5;
    --outline: #7775D6;
    --panel: #1D2042;
  }
  *, *::before, *::after { box-sizing: border-box; }
  html { height: auto; background: var(--bar); scroll-padding-top: env(safe-area-inset-top, 0px); scroll-behavior: smooth; }
  body {
    margin: 0;
    background: var(--bg);
    color: var(--text);
    font-family: var(--sans);
    font-size: 1.0625rem;
    line-height: 1.6;
    -webkit-font-smoothing: antialiased;
    transition: background .3s, color .3s;
  }
  h1, h2, h3 { font-family: var(--sans); color: var(--title); font-weight: 300; line-height: 1.1; margin: 0; letter-spacing: -0.01em; }
  p { margin: 0; }
  a { color: inherit; }
  :focus-visible { outline: 3px solid var(--lav); outline-offset: 3px; border-radius: 6px; }
  .wrap { width: min(1120px, 100% - 2.5rem); margin-inline: auto; }

  /* Botones */
  .btn {
    display: inline-flex; align-items: center; justify-content: center;
    font: 500 1rem/1 var(--sans);
    padding: .95rem 1.6rem; border-radius: 999px; border: 1.5px solid transparent;
    background: var(--btn); color: var(--btn-text); cursor: pointer; text-decoration: none;
    transition: transform .15s, background .2s;
  }
  .btn:hover { transform: translateY(-1px); }
  .btn.outline { background: transparent; color: var(--link); border-color: var(--outline); }
  .btn.small { padding: .65rem 1.15rem; font-size: .95rem; }
  .btn.on-bar { background: var(--lav-soft); color: var(--indigo); }

  /* Barra de navegación */
  header.bar { background: var(--bar); color: #fff; }
  header.bar .wrap { display: flex; align-items: center; gap: 2rem; min-height: 72px; }
  .brand { display: flex; align-items: center; gap: .7rem; text-decoration: none; color: #fff; }
  .brand svg { width: 52px; height: 38px; }
  .brand span { font: 500 1.5rem/1 var(--sans); letter-spacing: .28em; }
  nav { display: flex; gap: 1.6rem; margin-right: auto; }
  nav a { color: #E9E7FF; text-decoration: none; font-size: .98rem; }
  nav a:hover { color: #fff; text-decoration: underline; text-underline-offset: 6px; }
  .theme-toggle {
    background: transparent; color: #E9E7FF; border: 1.5px solid rgba(233,231,255,.4);
    border-radius: 999px; padding: .5rem .95rem; font: 400 .9rem var(--sans); cursor: pointer;
  }
  .theme-toggle:hover { border-color: #fff; color: #fff; }

  /* Hero: el texto siempre va al frente; el escenario queda detrás */
  .hero { position: relative; overflow: hidden; padding: clamp(3rem, 7vw, 5.5rem) 0; }
  .hero::before { /* resplandor suave en lugar de círculos planos */
    content: ""; position: absolute; width: 820px; height: 820px; border-radius: 50%;
    background: radial-gradient(circle, var(--soft) 0%, var(--soft) 34%, transparent 68%);
    top: 50%; right: -230px; transform: translateY(-50%); z-index: 0; pointer-events: none;
  }
  .hero::after { /* anillos finos que se desvanecen */
    content: ""; position: absolute; width: 540px; height: 540px; border-radius: 50%;
    left: -210px; bottom: -280px; z-index: 0; pointer-events: none;
    background: repeating-radial-gradient(circle, transparent 0 34px, var(--line) 34px 35.5px);
    -webkit-mask-image: radial-gradient(circle, #000 22%, transparent 70%);
    mask-image: radial-gradient(circle, #000 22%, transparent 70%);
  }
  .hero .wrap { position: relative; z-index: 1; min-height: 560px; display: flex; align-items: center; }
  .hero-copy { position: relative; z-index: 3; width: 100%; }
  .hero h1 { font-size: clamp(2.7rem, 6.4vw, 4.9rem); max-width: 10em; text-shadow: 0 0 22px var(--bg), 0 0 8px var(--bg); }
  .hero .lead { margin-top: 1.5rem; font-size: 1.2rem; max-width: 30em; color: var(--text); text-shadow: 0 0 14px var(--bg); }
  .hero .actions { margin-top: 2.2rem; display: flex; flex-wrap: wrap; gap: .9rem; }
  .hero .note { margin-top: 1.4rem; font-size: .95rem; color: var(--muted); }

  /* Escenario: luna (fondo) → avión → libro abierto y pila de libros */
  .stage { position: absolute; right: 0; top: 50%; transform: translateY(-50%); width: min(560px, 52%); aspect-ratio: 1; z-index: 1; pointer-events: none; }
  .stage > * { position: absolute; }
  .stage svg { display: block; }
  .rings { inset: 0; width: 100%; height: 100%; overflow: visible; }
  .rings .r { fill: none; stroke: var(--line); stroke-width: 1.5; }
  .moon { left: 40%; top: 2%; width: 52%; aspect-ratio: 1; border-radius: 50%; z-index: 1; box-shadow: 0 0 70px 14px rgba(203,201,244,.5); }
  .moon svg { width: 100%; height: 100%; }
  .plane { left: 6%; top: 12%; width: 60%; z-index: 2; }
  .plane svg { width: 100%; height: auto; overflow: visible; }
  .openbook { left: 22%; top: 57%; width: 50%; z-index: 3; }
  .openbook svg, .stack svg { width: 100%; height: auto; overflow: visible; }
  .stack { left: 76%; top: 67%; width: 23%; z-index: 3; }

  /* Secciones */
  section { padding: clamp(3.5rem, 8vw, 6rem) 0; }
  h2 { font-size: clamp(2rem, 4.2vw, 3.1rem); max-width: 16em; }
  .sec-lead { margin-top: 1.1rem; max-width: 36em; color: var(--text); }

  /* Lectura */
  .reading { background: var(--soft); }
  .reading .wrap { display: grid; grid-template-columns: .8fr 1.2fr; gap: 3.5rem; align-items: center; }
  .reader {
    background: var(--panel); border: 1px solid var(--line); border-radius: 22px; overflow: hidden;
  }
  .reader-top {
    display: flex; align-items: center; gap: .8rem; padding: .9rem 1.3rem;
    border-bottom: 1px solid var(--line); font-size: .95rem; color: var(--muted);
  }
  .reader-top strong { color: var(--title); font-weight: 500; margin-right: auto; font-family: var(--serif); }
  .ctl { display: inline-flex; border: 1.5px solid var(--outline); border-radius: 999px; overflow: hidden; }
  .ctl button {
    background: transparent; color: var(--link); border: 0; font: 500 .95rem var(--sans);
    padding: .4rem .85rem; cursor: pointer;
  }
  .ctl button:hover { background: var(--soft); }
  .ctl button + button { border-left: 1.5px solid var(--outline); }
  .reader-body { padding: clamp(1.4rem, 4vw, 2.6rem); }
  .story { font-family: var(--serif); font-size: 1.2rem; line-height: 1.8; max-width: 34em; color: var(--text); transition: font-size .2s; }
  .story p + p { margin-top: 1.1em; }
  .story .first::first-letter { font-size: 3.1em; float: left; line-height: .85; padding: .08em .12em 0 0; color: var(--title); font-weight: 500; }

  /* Escribir */
  .write .wrap { display: grid; grid-template-columns: 1fr 1fr; gap: 3.5rem; align-items: start; }
  .steps { list-style: none; padding: 0; margin: 2.2rem 0 0; display: grid; gap: 1.5rem; counter-reset: s; }
  .steps li { display: grid; grid-template-columns: 2.6rem 1fr; gap: 1rem; counter-increment: s; }
  .steps li::before {
    content: counter(s); width: 2.6rem; height: 2.6rem; border-radius: 50%;
    display: grid; place-items: center; background: var(--soft); color: var(--title);
    font-weight: 500; border: 1px solid var(--line);
  }
  .steps h3 { font-size: 1.2rem; font-weight: 500; letter-spacing: 0; }
  .steps p { margin-top: .2rem; color: var(--muted); }
  .demo { background: var(--panel); border: 1px solid var(--line); border-radius: 22px; padding: 1.6rem; }
  .file {
    display: flex; align-items: center; gap: 1rem; padding: 1rem 1.1rem;
    border: 1.5px dashed var(--outline); border-radius: 14px; background: var(--bg);
  }
  .file .icon { width: 42px; height: 52px; border-radius: 6px; background: var(--lav); color: #fff; display: grid; place-items: center; font-size: .72rem; font-weight: 600; letter-spacing: .06em; flex: none; }
  .file b { display: block; font-weight: 500; color: var(--title); }
  .file small { color: var(--muted); }
  .demo .btn { margin-top: 1rem; }
  .chapters { list-style: none; padding: 0; margin: 1.3rem 0 0; display: grid; gap: .6rem; }
  .chapters li {
    display: grid; grid-template-columns: auto 1fr auto; gap: .8rem; align-items: center;
    padding: .8rem 1rem; border: 1px solid var(--line); border-radius: 12px; background: var(--bg);
    animation: pop .35s ease both;
  }
  @keyframes pop { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: none; } }
  .chapters input { width: 1.15rem; height: 1.15rem; accent-color: var(--lav); }
  .chapters label { cursor: pointer; font-family: var(--serif); color: var(--title); }
  .chapters span { font-size: .88rem; color: var(--muted); }
  .status { margin-top: 1rem; min-height: 1.6em; font-weight: 500; color: var(--title); }

  /* Lectores + coins */
  .reader-hub { background: var(--bg); }
  .hub { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-top: 2.6rem; }
  .coins { background: var(--indigo); color: #fff; border-radius: 22px; padding: 2rem; display: flex; flex-direction: column; }
  :root[data-theme="dark"] .coins { background: #1D2042; border: 1px solid var(--line); }
  .coins h3 { color: #fff; font-size: 1.4rem; font-weight: 400; }
  .coins p { color: #D9D9E8; margin-top: .4rem; }
  .coin-row { display: flex; align-items: center; gap: 1rem; margin: 2rem 0 1.4rem; }
  .coin {
    width: 66px; height: 66px; border-radius: 50%; background: var(--gold); color: #B8832A;
    display: grid; place-items: center; font: 500 1.7rem var(--sans); box-shadow: inset 0 0 0 5px rgba(184,131,42,.25); flex: none;
  }
  .coin-num { font: 300 3.4rem/1 var(--sans); color: var(--gold); }
  .btn.gold { background: var(--gold); color: #3a2a06; align-self: flex-start; margin-top: auto; }
  .continue { background: var(--panel); border: 1px solid var(--line); border-radius: 22px; padding: 2rem; }
  .continue h3 { font-size: 1.4rem; font-weight: 400; }
  .continue .row { display: grid; grid-template-columns: 112px 1fr; gap: 1.4rem; margin-top: 1.6rem; align-items: center; }
  .cover { aspect-ratio: 3/4; border-radius: 12px; background: var(--lav); display: grid; place-items: center; }
  .cover svg { width: 76%; }
  .book-title { font-family: var(--serif); font-size: 1.2rem; color: var(--title); font-weight: 500; }
  .book-sub { color: var(--muted); font-size: .95rem; margin-top: .15rem; }
  .progress { height: 8px; border-radius: 99px; background: var(--soft); margin: 1rem 0 1.2rem; overflow: hidden; }
  .progress i { display: block; height: 100%; width: 58%; background: var(--lav); border-radius: 99px; }
  .small-note { margin-top: 1.4rem; font-size: .88rem; color: var(--muted); }

  /* CTA final */
  .final { background: var(--bar); color: #fff; text-align: center; border-top: 6px solid var(--gold); }
  .final h2 { color: #fff; margin-inline: auto; max-width: 14em; }
  .final p { margin: 1.2rem auto 0; max-width: 32em; color: #D9D9E8; }
  .final .actions { margin-top: 2rem; display: flex; justify-content: center; flex-wrap: wrap; gap: .9rem; }
  .final .btn.outline { color: #fff; border-color: rgba(255,255,255,.55); }

  footer { background: var(--bar); color: #C9C8EC; padding: 2rem 0 2.4rem; font-size: .92rem; border-top: 1px solid rgba(255,255,255,.1); }
  footer .wrap { display: flex; justify-content: space-between; gap: 1rem; flex-wrap: wrap; align-items: center; }
  footer .brand span { font-size: 1.15rem; }
  footer .brand svg { width: 40px; height: 30px; }

  /* ===== Animaciones e ilustraciones ===== */
  .plane .plane-float { animation: launch 1.3s cubic-bezier(.2,.8,.2,1) both, drift 7s ease-in-out 1.3s infinite; }
  @keyframes launch { from { opacity: 0; transform: translate(-55%, 45%) rotate(-14deg) scale(.7); } to { opacity: 1; transform: none; } }
  @keyframes drift { 0%,100% { transform: translateY(0) rotate(0); } 50% { transform: translateY(-12px) rotate(-1.5deg); } }
  .spark { position: absolute; width: 26px; height: 26px; animation: twinkle 3s ease-in-out infinite; }
  .spark.s1 { left: 3%; top: 6%; width: 30px; height: 30px; }
  .spark.s2 { left: 91%; top: 42%; width: 20px; height: 20px; animation-delay: 1s; }
  .spark.s3 { left: 12%; top: 52%; width: 22px; height: 22px; animation-delay: 2s; }
  @keyframes twinkle { 0%,100% { opacity: .35; transform: scale(.8); } 50% { opacity: 1; transform: scale(1.15); } }
  @keyframes spin { to { transform: rotate(360deg); } }

  /* La luna rota y un punto orbita sus anillos */
  .moon svg { animation: spin 50s linear infinite; }
  .orbit { animation: spin 60s linear infinite; transform-origin: 370px 157px; transform-box: view-box; }

  /* Libro abierto: las páginas pasan una tras otra */
  .flip { animation: flip 6s ease-in-out infinite; animation-delay: var(--d, 0s); transform-origin: 150px 0; transform-box: view-box; }
  @keyframes flip {
    0%, 8%  { transform: scaleX(1);  opacity: 1; }
    34%     { transform: scaleX(-1); opacity: 1; }
    82%     { transform: scaleX(-1); opacity: 1; }
    92%     { transform: scaleX(-1); opacity: 0; }
    93%     { transform: scaleX(1);  opacity: 0; }
    100%    { transform: scaleX(1);  opacity: 1; }
  }

  /* Pila de libros: brinca en cadena, de abajo hacia arriba */
  .hop { animation: hop 1.8s cubic-bezier(.3,.1,.4,1) infinite; animation-delay: var(--d, 0s); }
  @keyframes hop {
    0%, 55%, 100% { transform: translateY(0); }
    15% { transform: translateY(var(--h, -14px)); }
    30% { transform: translateY(0); }
    38% { transform: translateY(calc(var(--h, -14px) * .35)); }
    46% { transform: translateY(0); }
  }
  .stack .shadow { animation: shade 1.8s ease-in-out infinite; transform-origin: 80px 140px; transform-box: view-box; }
  @keyframes shade { 0%, 55%, 100% { transform: scaleX(1); opacity: .16; } 15% { transform: scaleX(.72); opacity: .08; } }

  /* Escena del pueblo */
  .scene { display: block; width: 100%; height: auto; background: #12142E; }
  .scene .win { fill: #FFFCF7; }
  .scene.play .win { animation: lightOff .9s ease forwards; animation-delay: var(--d); }
  @keyframes lightOff { to { fill: #2B2E63; } }
  .tw { animation: twinkle 3.4s ease-in-out infinite; transform-box: fill-box; transform-origin: center; }
  .glow { animation: glow 2.6s ease-in-out infinite; transform-box: fill-box; transform-origin: center; }
  @keyframes glow { 0%,100% { opacity: .65; transform: scale(1); } 50% { opacity: 1; transform: scale(1.25); } }
  .fly { animation: fly 11s linear 1.5s infinite; }
  @keyframes fly { from { transform: translate(-90px, 30px); opacity: 0; } 8% { opacity: 1; } 92% { opacity: 1; } to { transform: translate(680px, -40px); opacity: 0; } }

  /* Catálogo con portadas */
  .catalog { padding-bottom: 2.5rem; }
  .marquee { margin-top: 2.4rem; overflow: hidden; -webkit-mask-image: linear-gradient(90deg, transparent, #000 6%, #000 94%, transparent); mask-image: linear-gradient(90deg, transparent, #000 6%, #000 94%, transparent); }
  .track { display: flex; gap: 1.6rem; width: max-content; padding: .8rem 0 1rem; animation: slide 48s linear infinite; }
  .marquee:hover .track, .marquee:focus-within .track { animation-play-state: paused; }
  @keyframes slide { to { transform: translateX(calc(-50% - .8rem)); } }
  .book { margin: 0; width: 170px; flex: none; }
  .book svg { width: 100%; height: auto; display: block; border-radius: 12px; box-shadow: 0 12px 26px -14px rgba(37,40,102,.55); transition: transform .25s; }
  .book:hover svg { transform: translateY(-8px) rotate(-1.5deg); }
  .book figcaption { margin-top: .75rem; font-family: var(--serif); color: var(--title); font-size: 1rem; line-height: 1.3; }
  .book figcaption span { display: block; font-family: var(--sans); font-size: .85rem; color: var(--muted); margin-top: .15rem; }

  /* Entradas al hacer scroll */
  .rv { opacity: 0; transform: translateY(18px); transition: opacity .7s ease, transform .7s ease; }
  .rv.in { opacity: 1; transform: none; }
  .continue .progress i { width: 0; transition: width 1.5s cubic-bezier(.2,.7,.2,1) .3s; }
  .continue.in .progress i { width: 58%; }
  .coins.in .coin { animation: coinSpin 1.4s cubic-bezier(.2,.8,.2,1); }
  @keyframes coinSpin { from { transform: rotateY(540deg) scale(.6); } to { transform: none; } }

  @media (prefers-reduced-motion: reduce) {
    .plane .plane-float, .spark, .tw, .glow, .fly, .track, .coins.in .coin, .moon svg, .orbit, .flip, .hop, .stack .shadow { animation: none !important; }
    .scene.play .win { animation: none; }
    .fly { display: none; }
    .rv { opacity: 1; transform: none; }
    .continue .progress i { width: 58%; }
    .marquee { overflow-x: auto; -webkit-mask-image: none; mask-image: none; }
    .book[data-dup] { display: none; }
  }

  /* ===== Ventanas flotantes (iniciar sesión / registrarse) ===== */
  .btn.ghost-bar { background: transparent; color: #E9E7FF; border-color: rgba(233,231,255,.5); }
  .btn.ghost-bar:hover { border-color: #fff; color: #fff; }
  .overlay[hidden], .modal[hidden] { display: none; }
  .overlay {
    position: fixed; inset: 0; z-index: 100; display: grid; place-items: center;
    padding: max(1rem, env(safe-area-inset-top, 0px)) 1rem max(1rem, env(safe-area-inset-bottom, 0px));
    background: rgba(18,20,46,.5); -webkit-backdrop-filter: blur(6px); backdrop-filter: blur(6px);
    animation: fadeIn .25s ease;
  }
  .modal {
    position: relative; width: min(430px, 100%); max-height: 100%; overflow-y: auto;
    padding: 2.2rem 1.9rem 1.8rem; border-radius: 26px; color: var(--text);
    background: rgba(255,252,247,.82); -webkit-backdrop-filter: blur(18px) saturate(1.2); backdrop-filter: blur(18px) saturate(1.2);
    border: 1px solid rgba(255,255,255,.65); box-shadow: 0 30px 80px -20px rgba(18,20,46,.6);
    animation: rise .3s cubic-bezier(.2,.8,.2,1);
  }
  :root[data-theme="dark"] .modal { background: rgba(29,32,66,.82); border-color: rgba(119,117,214,.4); }
  @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
  @keyframes rise { from { opacity: 0; transform: translateY(16px) scale(.97); } to { opacity: 1; transform: none; } }
  .modal .close {
    position: absolute; top: .9rem; right: .9rem; width: 38px; height: 38px; border-radius: 50%;
    border: 0; background: rgba(119,117,214,.15); color: var(--title); font: 400 1.5rem/1 var(--sans); cursor: pointer;
  }
  .modal .close:hover { background: rgba(119,117,214,.3); }
  .m-brand { display: flex; align-items: center; justify-content: center; gap: .6rem; margin-bottom: 1.1rem; }
  .m-brand svg { width: 48px; height: 36px; }
  .m-brand .dk { display: none; }
  :root[data-theme="dark"] .m-brand .lt { display: none; }
  :root[data-theme="dark"] .m-brand .dk { display: block; }
  .m-brand span { font: 500 1.3rem/1 var(--sans); letter-spacing: .28em; color: var(--title); }
  .modal h2 { font-size: 1.9rem; max-width: none; text-align: center; }
  .m-sub { text-align: center; color: var(--muted); margin-top: .4rem; font-size: .98rem; }
  .modal form { margin-top: 1.2rem; }
  .modal label { display: block; margin: 1rem 0 .35rem; font-size: .92rem; font-weight: 500; color: var(--title); }
  .modal input {
    width: 100%; font: inherit; font-size: 1rem; padding: .85rem 1rem; border-radius: 12px;
    border: 1.5px solid var(--line); background: rgba(255,255,255,.75); color: var(--text);
  }
  :root[data-theme="dark"] .modal input { background: rgba(18,20,46,.6); }
  .modal input::placeholder { color: #8b8ba3; }
  .modal input:focus { outline: none; border-color: var(--lav); box-shadow: 0 0 0 3px rgba(119,117,214,.28); }
  .pw { position: relative; }
  .pw input { padding-right: 5.2rem; }
  .pw-toggle { position: absolute; right: .5rem; top: 50%; transform: translateY(-50%); border: 0; background: transparent; color: var(--link); font: 500 .88rem var(--sans); cursor: pointer; padding: .4rem .6rem; border-radius: 8px; }
  .form-msg { min-height: 1.4em; margin-top: .8rem; font-size: .92rem; color: var(--muted); }
  .form-msg.err { color: #B3261E; }
  :root[data-theme="dark"] .form-msg.err { color: #FF9C94; }
  .form-msg.ok { color: var(--title); font-weight: 500; }
  .m-submit { width: 100%; margin-top: .6rem; padding: 1rem; }
  .m-switch { margin-top: 1.3rem; text-align: center; font-size: .95rem; color: var(--muted); }
  .link { background: none; border: 0; padding: 0; font: inherit; font-weight: 600; color: var(--link); text-decoration: underline; text-underline-offset: 3px; cursor: pointer; }
  .s-btn {
    display: flex; align-items: center; gap: .85rem; width: 100%; margin-top: .75rem; padding: .85rem 1.2rem;
    border-radius: 999px; border: 1.5px solid var(--outline); background: rgba(255,255,255,.55); color: var(--title);
    font: 500 1rem var(--sans); cursor: pointer; text-align: left; transition: transform .15s, background .2s;
  }
  :root[data-theme="dark"] .s-btn { background: rgba(18,20,46,.45); }
  .s-btn:hover { transform: translateY(-1px); background: rgba(233,231,255,.8); }
  :root[data-theme="dark"] .s-btn:hover { background: rgba(119,117,214,.25); }
  .s-btn.primary { background: var(--btn); color: var(--btn-text); border-color: transparent; }
  .s-btn.primary:hover { background: var(--btn); }
  .s-btn svg { width: 22px; height: 22px; flex: none; }
  .m-or { display: flex; align-items: center; gap: .8rem; margin: 1.1rem 0 .1rem; color: var(--muted); font-size: .88rem; }
  .m-or::before, .m-or::after { content: ""; height: 1px; flex: 1; background: var(--line); }
  .m-legal { margin-top: 1rem; font-size: .82rem; color: var(--muted); text-align: center; }
  @media (prefers-reduced-motion: reduce) { .overlay, .modal { animation: none; } }

  .user-chip { max-width: 18ch; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

  /* Responsive */
  @media (max-width: 900px) {
    .reading .wrap, .write .wrap, .hub { grid-template-columns: 1fr; }
    .hero .wrap { flex-direction: column; min-height: 0; }
    .stage { position: relative; right: auto; top: auto; transform: none; width: min(92%, 440px); margin: 1.5rem auto 0; }
    nav { display: none; }
    header.bar .wrap { justify-content: space-between; }
    .theme-toggle { margin-left: auto; }
  }
  @media (max-width: 480px) {
    .continue .row { grid-template-columns: 90px 1fr; }
    .coin-num { font-size: 2.7rem; }
    header.bar .btn.ghost-bar { display: none; }
  }
  @media (prefers-reduced-motion: reduce) {
    .plane-float, .chapters li { animation: none; }
    html { scroll-behavior: auto; }
    * { transition: none !important; }
  }

  /* ===== Inicio (usuario con sesión) ===== */
  .btn.user { background: transparent; color: #E9E7FF; border-color: rgba(233,231,255,.5); gap: .55rem; max-width: 20ch; }
  .btn.user:hover { border-color: #fff; color: #fff; }
  .btn.user b { font-weight: 500; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .avatar { width: 28px; height: 28px; border-radius: 50%; background: var(--lav-soft); color: var(--indigo); display: inline-grid; place-items: center; font: 600 .85rem var(--sans); flex: none; }

  .welcome { background: var(--soft); padding: clamp(2.5rem, 6vw, 4.2rem) 0; }
  .welcome h1 { font-size: clamp(2.2rem, 5.2vw, 3.8rem); max-width: 14em; }
  .welcome .lead { margin-top: .9rem; color: var(--text); max-width: 34em; }
  .search { margin-top: 1.7rem; display: flex; gap: .7rem; max-width: 680px; }
  .search input {
    flex: 1; min-width: 0; font: inherit; padding: .95rem 1.4rem; border-radius: 999px;
    border: 1.5px solid var(--outline); background: var(--surface); color: var(--text);
  }
  .search input::placeholder { color: #8b8ba3; }
  .search input:focus { outline: none; box-shadow: 0 0 0 3px rgba(119,117,214,.28); }

  .block { padding: clamp(2.6rem, 6vw, 4rem) 0 0; }
  .block:last-of-type { padding-bottom: clamp(3rem, 7vw, 5rem); }
  .block h2 { font-size: clamp(1.7rem, 3.4vw, 2.3rem); }
  .block .sec-lead { margin-top: .6rem; }

  .resume-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1.2rem; margin-top: 1.7rem; }
  .resume { display: grid; grid-template-columns: 84px 1fr; gap: 1.1rem; align-items: center; background: var(--panel); border: 1px solid var(--line); border-radius: 18px; padding: 1.1rem; }
  .resume .cv svg { width: 100%; height: auto; display: block; border-radius: 8px; }
  .resume .progress { margin: .8rem 0 .5rem; }
  .resume .progress i { width: var(--p, 0%); }
  .resume .pct { font-size: .85rem; color: var(--muted); margin-bottom: .8rem; }

  .shelf { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 1.7rem 1.3rem; margin-top: 1.8rem; }
  .shelf .book { width: auto; }
  .tabs { display: flex; flex-wrap: wrap; gap: .5rem; margin-top: 1.5rem; }
  .tab { font: 500 .95rem var(--sans); padding: .6rem 1.15rem; border-radius: 999px; border: 1.5px solid var(--outline); background: transparent; color: var(--link); cursor: pointer; }
  .tab:hover { background: var(--soft); }
  .tab[aria-selected="true"] { background: var(--btn); color: var(--btn-text); border-color: transparent; }
  .tab small { opacity: .75; margin-left: .25rem; }

  .off { display: none !important; }
  .nores { display: none; margin-top: 2.5rem; color: var(--muted); }
  .nores.on { display: block; }
  .hint { margin-top: 1.6rem; font-size: .88rem; color: var(--muted); }

  /* Menú de usuario */
  header.bar { position: relative; z-index: 50; }
  .menu-wrap { position: relative; }
  .btn.user .caret { width: 12px; height: 12px; flex: none; transition: transform .2s; }
  .btn.user[aria-expanded="true"] .caret { transform: rotate(180deg); }
  .menu {
    position: absolute; right: 0; top: calc(100% + .6rem); min-width: 240px; padding: .5rem;
    background: var(--surface); color: var(--text); border: 1px solid var(--line); border-radius: 16px;
    box-shadow: 0 24px 50px -18px rgba(18,20,46,.5); animation: rise .2s cubic-bezier(.2,.8,.2,1);
  }
  .menu[hidden] { display: none; }
  .menu-head { padding: .6rem .8rem .7rem; border-bottom: 1px solid var(--line); margin-bottom: .35rem; }
  .menu-head b { display: block; color: var(--title); font-weight: 500; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .menu-head small { color: var(--muted); }
  .menu a { display: block; padding: .65rem .8rem; border-radius: 10px; text-decoration: none; color: var(--text); font-size: .98rem; }
  .menu a:hover, .menu a:focus-visible { background: var(--soft); color: var(--title); }
  @keyframes rise { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: none; } }

  /* Avión de papel en la bienvenida */
  .welcome { position: relative; overflow: hidden; }
  .welcome .wrap { position: relative; }
  .welcome .wrap > *:not(.welcome-plane) { position: relative; z-index: 1; }
  .welcome-plane { position: absolute; right: 0; top: 50%; transform: translateY(-50%); width: min(340px, 34%); pointer-events: none; z-index: 0; }
  .welcome-plane svg { width: 100%; height: auto; overflow: visible; display: block; }

  /* Mis obras */
  .new-work {
    aspect-ratio: 3/4; border: 1.5px dashed var(--outline); border-radius: 12px; background: transparent;
    color: var(--link); font: 500 1rem var(--sans); cursor: pointer; padding: 1rem; text-align: center;
    display: grid; place-content: center; gap: .4rem;
  }
  .new-work:hover { background: var(--soft); }
  .new-work span { font-size: 2rem; line-height: 1; font-weight: 300; }

  @media (max-width: 760px) {
    .welcome-plane { position: relative; top: auto; right: auto; transform: none; width: 200px; margin: 1.6rem 0 0 auto; }
  }

  /* ===== Accesos rápidos y navegación entre vistas ===== */
  nav a[aria-current="page"] { color: #fff; text-decoration: underline; text-underline-offset: 6px; }
  .icon-btn {
    position: relative; display: inline-grid; place-items: center; width: 40px; height: 40px; flex: none;
    border-radius: 50%; color: #E9E7FF; border: 1.5px solid rgba(233,231,255,.4); text-decoration: none;
  }
  .icon-btn:hover { border-color: #fff; color: #fff; }
  .icon-btn svg { width: 20px; height: 20px; }
  .menu .sep { height: 1px; background: var(--line); margin: .35rem .4rem; }

  .quick { padding: clamp(2rem, 5vw, 3rem) 0 0; }
  .quick h2 { font-size: clamp(1.5rem, 3vw, 2rem); }
  .quick-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(210px, 1fr)); gap: 1rem; margin-top: 1.4rem; }
  .qcard {
    display: grid; gap: .35rem; align-content: start; padding: 1.2rem 1.25rem; text-decoration: none;
    background: var(--panel); border: 1px solid var(--line); border-radius: 18px; color: var(--text);
    transition: transform .15s, border-color .2s, box-shadow .2s;
  }
  .qcard:hover { transform: translateY(-3px); border-color: var(--lav); box-shadow: 0 16px 30px -22px rgba(37,40,102,.6); }
  .qcard .qi { width: 42px; height: 42px; border-radius: 12px; display: grid; place-items: center; background: var(--soft); color: var(--title); }
  .qcard .qi svg { width: 22px; height: 22px; }
  .qcard b { margin-top: .5rem; font-weight: 500; color: var(--title); font-size: 1.05rem; }
  .qcard small { color: var(--muted); font-size: .9rem; line-height: 1.4; }

  .empty { margin-top: 1.7rem; display: flex; flex-wrap: wrap; align-items: center; gap: 1rem 1.4rem;
    background: var(--panel); border: 1px dashed var(--outline); border-radius: 18px; padding: 1.3rem 1.5rem; }
  .empty p { color: var(--muted); max-width: 36em; }
  .actions-row { margin-top: 1.7rem; display: flex; flex-wrap: wrap; gap: .8rem; }

  footer .links { display: flex; flex-wrap: wrap; gap: .4rem 1.3rem; }
  footer .links a { color: #C9C8EC; text-decoration: none; }
  footer .links a:hover { color: #fff; text-decoration: underline; text-underline-offset: 4px; }
</style>
</head>
<body>

<!-- Símbolo del logo (aproximación vectorial; reemplazar por el archivo oficial) -->
<svg width="0" height="0" style="position:absolute" aria-hidden="true" focusable="false">
  <defs>
    <path id="star" d="M0,-1 Q.12,-.12 1,0 Q.12,.12 0,1 Q-.12,.12 -1,0 Q-.12,-.12 0,-1Z"/>
    <linearGradient id="orb" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#CBC9F4"/><stop offset="1" stop-color="#A9A5EE"/>
    </linearGradient>
    <symbol id="plane-color" viewBox="300 230 380 280">
      <use href="#star" transform="translate(368 275) scale(35)" fill="#5051AE"/>
      <use href="#star" transform="translate(322 327) scale(17)" fill="#5051AE"/>
      <path d="M388 405C330 440 310 480 360 493C420 502 480 482 528 459C470 475 400 478 372 462C350 448 360 425 388 405Z" fill="url(#orb)"/>
      <polygon points="368,350 642,258 440,382" fill="#CBC9F4"/>
      <polygon points="440,382 642,258 458,461" fill="#5051AE"/>
      <polygon points="458,461 440,382 500,420" fill="#28296D"/>
      <polygon points="642,258 545,453 484,404" fill="#BDB9F2"/>
      <path d="M620 345C662 345 676 366 656 396C640 419 610 431 582 439C620 421 646 400 646 380C646 365 636 352 620 345Z" fill="url(#orb)"/>
    </symbol>
    <symbol id="plane-white" viewBox="300 230 380 280">
      <use href="#star" transform="translate(368 275) scale(35)" fill="#F4F3FF"/>
      <use href="#star" transform="translate(322 327) scale(17)" fill="#F4F3FF"/>
      <path d="M388 405C330 440 310 480 360 493C420 502 480 482 528 459C470 475 400 478 372 462C350 448 360 425 388 405Z" fill="#B7B6D6"/>
      <polygon points="368,350 642,258 440,382" fill="#C9C8DC"/>
      <polygon points="440,382 642,258 458,461" fill="#A9A8C6"/>
      <polygon points="458,461 440,382 500,420" fill="#8E8DB0"/>
      <polygon points="642,258 545,453 484,404" fill="#E9E8F5"/>
      <path d="M620 345C662 345 676 366 656 396C640 419 610 431 582 439C620 421 646 400 646 380C646 365 636 352 620 345Z" fill="#B7B6D6"/>
    </symbol>
  </defs>
</svg>

<!-- Portadas ilustradas (SVG propio, paleta SAFIR) -->
<svg width="0" height="0" style="position:absolute" aria-hidden="true" focusable="false">
  <defs>
    <symbol id="cv1" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#252866"/>
      <use href="#star" transform="translate(30 35) scale(9)" fill="#CBC9F4"/>
      <use href="#star" transform="translate(112 28) scale(6)" fill="#CBC9F4"/>
      <use href="#star" transform="translate(82 66) scale(5)" fill="#E9E7FF"/>
      <path d="M0 165 Q75 122 150 165 V200 H0Z" fill="#1D2042"/>
      <g stroke="#7775D6" stroke-width="2.5"><line x1="38" y1="182" x2="38" y2="152"/><line x1="75" y1="186" x2="75" y2="140"/><line x1="112" y1="182" x2="112" y2="155"/></g>
      <use href="#star" transform="translate(38 150) scale(9)" fill="#E9E7FF"/>
      <use href="#star" transform="translate(75 138) scale(11)" fill="#E9E7FF"/>
      <use href="#star" transform="translate(112 153) scale(8)" fill="#E9E7FF"/>
    </symbol>
    <symbol id="cv2" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#CBC9F4"/>
      <circle cx="108" cy="56" r="22" fill="#FFFCF7"/>
      <polygon points="0,150 46,82 92,150" fill="#7775D6"/>
      <polygon points="52,150 106,96 150,150" fill="#5051AE"/>
      <rect y="150" width="150" height="50" fill="#252866"/>
      <rect x="38" y="165" width="74" height="3" rx="1.5" fill="#7775D6"/>
      <rect x="56" y="178" width="40" height="3" rx="1.5" fill="#7775D6"/>
    </symbol>
    <symbol id="cv3" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#12142E"/>
      <circle cx="78" cy="82" r="44" fill="#E9E7FF"/>
      <circle cx="58" cy="72" r="8" fill="#CBC9F4"/>
      <circle cx="94" cy="98" r="10" fill="#CBC9F4"/>
      <circle cx="92" cy="64" r="5" fill="#CBC9F4"/>
      <use href="#plane-white" x="22" y="128" width="78" height="58"/>
      <use href="#star" transform="translate(24 30) scale(6)" fill="#CBC9F4"/>
      <use href="#star" transform="translate(128 150) scale(5)" fill="#CBC9F4"/>
    </symbol>
    <symbol id="cv4" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#5051AE"/>
      <rect x="30" y="128" width="90" height="18" rx="3" fill="#252866"/>
      <rect x="40" y="108" width="76" height="18" rx="3" fill="#CBC9F4"/>
      <rect x="36" y="88" width="66" height="18" rx="3" fill="#E9E7FF" transform="rotate(-7 69 97)"/>
      <use href="#star" transform="translate(32 46) scale(8)" fill="#E9E7FF"/>
      <use href="#star" transform="translate(116 60) scale(6)" fill="#CBC9F4"/>
      <use href="#star" transform="translate(86 28) scale(4)" fill="#E9E7FF"/>
    </symbol>
    <symbol id="cv5" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#E9E7FF"/>
      <path d="M75 24 Q94 50 75 70 Q56 50 75 24Z" fill="#252866"/>
      <g fill="none" stroke-width="7" stroke-linecap="round">
        <path d="M-5 118 Q35 96 75 118 T155 118" stroke="#5051AE"/>
        <path d="M-5 144 Q35 122 75 144 T155 144" stroke="#7775D6"/>
        <path d="M-5 170 Q35 148 75 170 T155 170" stroke="#252866"/>
      </g>
    </symbol>
    <symbol id="cv6" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#252866"/>
      <circle cx="75" cy="122" r="54" fill="#7775D6" opacity=".45"/>
      <rect y="148" width="150" height="52" fill="#12142E"/>
      <rect x="40" y="128" width="70" height="20" rx="5" fill="#CBC9F4"/>
      <g fill="#252866"><rect x="48" y="134" width="10" height="8" rx="2"/><rect x="64" y="134" width="10" height="8" rx="2"/><rect x="80" y="134" width="10" height="8" rx="2"/><rect x="96" y="134" width="8" height="8" rx="2"/></g>
      <g stroke="#5051AE" stroke-width="2"><line x1="0" y1="166" x2="150" y2="166"/><line x1="0" y1="182" x2="150" y2="182"/></g>
      <use href="#star" transform="translate(30 36) scale(6)" fill="#E9E7FF"/>
      <use href="#star" transform="translate(118 52) scale(8)" fill="#CBC9F4"/>
    </symbol>
  </defs>
</svg>

<header class="bar">
  <div class="wrap">
    <a class="brand" href="<%= contexto %>/auth/inicio" aria-label="SAFIR, inicio">
      <svg viewBox="0 0 380 280" role="img" aria-hidden="true"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </a>
    <nav aria-label="Principal">
      <a href="<%= contexto %>/catalogo">Catálogo</a>
      <a href="<%= contexto %>/biblioteca">Mi biblioteca</a>
      <a href="<%= contexto %>/notificaciones">Notificaciones</a>
      <a href="<%= contexto %>/perfil">Mi perfil</a>
      <% if (esAutor) { %>
      <a href="<%= contexto %>/autor/panel">Panel de autor</a>
      <% } %>
    </nav>
    <button class="theme-toggle" id="themeBtn" type="button" aria-pressed="false">Modo noche</button>
    <a class="icon-btn" href="<%= contexto %>/notificaciones" aria-label="Notificaciones" title="Notificaciones"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 9a6 6 0 0 1 12 0c0 6 2.5 7.5 2.5 7.5h-17S6 15 6 9"/><path d="M10 20a2 2 0 0 0 4 0"/></svg></a>
    <div class="menu-wrap">
      <button class="btn small user" id="userMenuBtn" type="button" aria-haspopup="true" aria-expanded="false" aria-controls="userMenu">
        <span class="avatar" aria-hidden="true"><%= inicial %></span><b><%= nombreUsuario %></b>
        <svg class="caret" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m2 4 4 4 4-4"/></svg>
      </button>
      <div class="menu" id="userMenu" role="menu" aria-label="Menú de usuario" hidden>
        <div class="menu-head"><b><%= nombreUsuario %></b><small>Sesión iniciada</small></div>
        <a role="menuitem" href="<%= contexto %>/perfil">Mi perfil</a>
        <a role="menuitem" href="<%= contexto %>/auth/cuenta">Mi cuenta</a>
        <a role="menuitem" href="<%= contexto %>/biblioteca">Mi biblioteca</a>
        <a role="menuitem" href="<%= contexto %>/notificaciones">Notificaciones</a>
        <a role="menuitem" href="<%= contexto %>/catalogo">Catálogo</a>
        <% if (esAutor) { %>
        <div class="sep" role="separator"></div>
        <a role="menuitem" href="<%= contexto %>/autor/panel">Panel de autor</a>
        <a role="menuitem" href="<%= contexto %>/autor/obra/nueva">Nueva obra</a>
        <% } %>
        <div class="sep" role="separator"></div>
        <a role="menuitem" href="#" data-pendiente>Configuraciones</a>
        <a role="menuitem" href="#" data-pendiente>Mensajes</a>
      </div>
    </div>
    <a class="btn small on-bar" href="<%= contexto %>/auth/logout">Cerrar sesión</a>
  </div>
</header>

<main id="inicio">
  <!-- BIENVENIDA + BUSCADOR -->
  <section class="welcome">
    <div class="wrap">
      <div class="welcome-plane" aria-hidden="true">
        <svg viewBox="0 0 380 280" class="plane-float"><use href="#plane-color"/></svg>
      </div>
      <h1>Hola, <%= nombreUsuario %>.</h1>
      <p class="lead">Qué bueno verte de nuevo. Busca una obra o sigue leyendo donde te quedaste.</p>
      <%-- La búsqueda se envía al catálogo (CatalogoServlet, parámetro "q"). --%>
      <form class="search" id="searchForm" role="search" method="get" action="<%= contexto %>/catalogo">
        <input type="search" id="searchInput" name="q" placeholder="Buscar obras por título o género…" aria-label="Buscar obras" autocomplete="off">
        <button class="btn" type="submit">Buscar</button>
      </form>
    </div>
  </section>

  <!-- ACCESOS RÁPIDOS: una puerta a cada vista de la aplicación -->
  <section class="quick" id="accesos">
    <div class="wrap">
      <h2>Accesos rápidos</h2>
      <div class="quick-grid">
        <a class="qcard" href="<%= contexto %>/catalogo">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3.5" y="3.5" width="7" height="7" rx="1.5"/><rect x="13.5" y="3.5" width="7" height="7" rx="1.5"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.5"/><rect x="13.5" y="13.5" width="7" height="7" rx="1.5"/></svg></span>
          <b>Catálogo</b>
          <small>Explora las obras publicadas y filtra por título o género.</small>
        </a>
        <a class="qcard" href="<%= contexto %>/biblioteca">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v16H6.5A2.5 2.5 0 0 0 4 21.5z"/><path d="M4 5.5v16"/></svg></span>
          <b>Mi biblioteca</b>
          <small>Tus obras guardadas, su estado de lectura y tus favoritas.</small>
        </a>
        <a class="qcard" href="<%= contexto %>/notificaciones">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 9a6 6 0 0 1 12 0c0 6 2.5 7.5 2.5 7.5h-17S6 15 6 9"/><path d="M10 20a2 2 0 0 0 4 0"/></svg></span>
          <b>Notificaciones</b>
          <small>Capítulos nuevos y avisos de las obras que sigues.</small>
        </a>
        <a class="qcard" href="<%= contexto %>/perfil">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg></span>
          <b>Mi perfil</b>
          <small>Tu nombre público, tus roles y tus accesos.</small>
        </a>
        <a class="qcard" href="<%= contexto %>/auth/cuenta">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3.5" y="5" width="17" height="14" rx="2.5"/><circle cx="9" cy="12" r="2.2"/><path d="M13.5 10.5h4M13.5 13.5h4"/></svg></span>
          <b>Mi cuenta</b>
          <small>Datos de tu cuenta y de acceso.</small>
        </a>
<% if (esAutor) { %>
        <a class="qcard" href="<%= contexto %>/autor/panel">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 20l1-4L16.5 4.5a2.1 2.1 0 0 1 3 3L8 19z"/><path d="M14.5 6.5l3 3"/></svg></span>
          <b>Panel de autor</b>
          <small>Tus obras, avance, lecturas y valoraciones.</small>
        </a>
        <a class="qcard" href="<%= contexto %>/autor/obra/nueva">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 8v8M8 12h8"/></svg></span>
          <b>Nueva obra</b>
          <small>Crea una historia y empieza a publicar capítulos.</small>
        </a>
<% } %>
      </div>
    </div>
  </section>

  <!-- CONTINUAR LEYENDO: la lectura (/lectura) se abre desde una obra o desde la biblioteca -->
  <section class="block" id="continuar">
    <div class="wrap">
      <h2>Continuar leyendo</h2>
      <p class="sec-lead">Vuelve justo donde lo dejaste.</p>
      <div class="empty">
        <p>Abre una obra de tu biblioteca y el lector retomará tu última posición guardada.</p>
        <a class="btn small" href="<%= contexto %>/biblioteca">Ir a mi biblioteca</a>
      </div>
    </div>
  </section>

  <!-- RECOMENDADOS -->
  <section class="block" id="recomendados">
    <div class="wrap">
      <h2>Recomendados para ti</h2>
      <p class="sec-lead">Historias que podrían gustarte esta noche.</p>
      <div class="empty">
        <p>Encuentra tu próxima lectura entre todas las obras publicadas.</p>
        <a class="btn small" href="<%= contexto %>/catalogo">Explorar el catálogo</a>
      </div>
    </div>
  </section>

  <!-- MIS LISTADOS -->
  <section class="block" id="listados">
    <div class="wrap">
      <h2>Mis listados</h2>
      <p class="sec-lead">Tus obras guardadas, organizadas a tu manera.</p>
      <div class="empty">
        <p>En tu biblioteca puedes marcar cada obra como por leer, leyendo, terminada o abandonada, y guardar tus favoritas.</p>
        <a class="btn small" href="<%= contexto %>/biblioteca">Abrir mi biblioteca</a>
      </div>
    </div>
  </section>

<% if (esAutor) { %>
  <!-- MIS OBRAS (solo autores y administradores) -->
  <section class="block" id="mis-obras">
    <div class="wrap">
      <h2>Mis obras</h2>
      <p class="sec-lead">Las historias que escribes y publicas en SAFIR.</p>
      <div class="actions-row">
        <a class="btn" href="<%= contexto %>/autor/panel">Ir al panel de autor</a>
        <a class="btn outline" href="<%= contexto %>/autor/obra/nueva">Nueva obra</a>
      </div>
    </div>
  </section>
<% } %>

  <!-- NOTIFICACIONES -->
  <section class="block" id="avisos">
    <div class="wrap">
      <h2>Notificaciones</h2>
      <p class="sec-lead">Entérate de los capítulos nuevos de las obras que sigues.</p>
      <div class="actions-row">
        <a class="btn outline" href="<%= contexto %>/notificaciones">Ver mis notificaciones</a>
        <a class="btn outline" href="<%= contexto %>/perfil">Mi perfil</a>
      </div>
    </div>
  </section>
</main>

<footer>
  <div class="wrap">
    <a class="brand" href="<%= contexto %>/auth/inicio" aria-label="SAFIR, inicio">
      <svg viewBox="0 0 380 280" aria-hidden="true"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </a>
    <div class="links">
      <a href="<%= contexto %>/catalogo">Catálogo</a>
      <a href="<%= contexto %>/biblioteca">Mi biblioteca</a>
      <a href="<%= contexto %>/notificaciones">Notificaciones</a>
      <a href="<%= contexto %>/perfil">Mi perfil</a>
    </div>
    <span>Tus historias, en un solo lugar.</span>
  </div>
</footer>

<script>
(function () {
  // Modo noche
  var root = document.documentElement;
  var themeBtn = document.getElementById('themeBtn');
  function setTheme(t) {
    if (t === 'dark') root.setAttribute('data-theme', 'dark'); else root.removeAttribute('data-theme');
    themeBtn.setAttribute('aria-pressed', t === 'dark' ? 'true' : 'false');
    themeBtn.textContent = t === 'dark' ? 'Modo claro' : 'Modo noche';
    try { localStorage.setItem('safir-theme', t); } catch (e) {}
  }
  var saved = null;
  try { saved = localStorage.getItem('safir-theme'); } catch (e) {}
  setTheme(saved === 'dark' ? 'dark' : 'light');
  themeBtn.addEventListener('click', function () {
    setTheme(root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
  });

  // Buscador: evita enviar una búsqueda vacía al catálogo
  var form = document.getElementById('searchForm');
  var input = document.getElementById('searchInput');
  form.addEventListener('submit', function (e) {
    if (input.value.trim() === '') { e.preventDefault(); input.focus(); }
  });

  // Menú de usuario
  var menuBtn = document.getElementById('userMenuBtn');
  var menu = document.getElementById('userMenu');
  function setMenu(open) {
    menu.hidden = !open;
    menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
  }
  menuBtn.addEventListener('click', function (e) { e.stopPropagation(); setMenu(menu.hidden); });
  document.addEventListener('click', function (e) {
    if (!menu.hidden && !menu.contains(e.target)) setMenu(false);
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && !menu.hidden) { setMenu(false); menuBtn.focus(); }
  });
  Array.prototype.forEach.call(menu.querySelectorAll('a'), function (a) {
    a.addEventListener('click', function (e) {
      if (a.hasAttribute('data-pendiente')) e.preventDefault();
      setMenu(false);
    });
  });
})();
</script>
</body>
</html>
