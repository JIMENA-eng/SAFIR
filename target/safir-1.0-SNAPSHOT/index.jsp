<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%
    String contexto = request.getContextPath();

    jakarta.servlet.http.HttpSession sesion = request.getSession(false);
    boolean logueado = sesion != null && sesion.getAttribute("usuarioId") != null;

    String nombreUsuario = "";
    if (logueado && sesion.getAttribute("nombreUsuario") != null) {
        nombreUsuario = String.valueOf(sesion.getAttribute("nombreUsuario"))
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>SAFIR · Tus historias, en un solo lugar</title>
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
    <a class="brand" href="#inicio" aria-label="SAFIR, inicio">
      <svg viewBox="0 0 380 280" role="img" aria-hidden="true"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </a>
    <nav aria-label="Principal">
      <a href="#leer">Leer</a>
      <a href="#catalogo">Catálogo</a>
      <a href="#escribir">Publicar</a>
      <a href="#coins">Coins</a>
    </nav>
    <button class="theme-toggle" id="themeBtn" type="button" aria-pressed="false">Modo noche</button>
    <% if (logueado) { %>
    <a class="btn small ghost-bar user-chip" href="<%= contexto %>/auth/inicio">Hola, <%= nombreUsuario %></a>
    <a class="btn small on-bar" href="<%= contexto %>/logout">Cerrar sesión</a>
    <% } else { %>
    <a class="btn small ghost-bar" href="<%= contexto %>/auth/login" data-open="login">Iniciar sesión</a>
    <a class="btn small on-bar" href="<%= contexto %>/auth/registro" data-open="register">Crear cuenta</a>
    <% } %>
  </div>
</header>

<main id="inicio">
  <!-- HERO -->
  <div class="hero">
    <div class="wrap">
      <div class="hero-copy">
        <h1>Tus historias, en un solo lugar.</h1>
        <p class="lead">Una biblioteca digital y una comunidad literaria en la misma web. Lee durante horas con comodidad, publica tus obras y continúa siempre donde te quedaste.</p>
        <div class="actions">
          <a class="btn" href="#leer">Explorar historias</a>
          <a class="btn outline" href="#escribir">Publicar una obra</a>
        </div>
        <p class="note">Funciona en computadora y en el navegador del celular.</p>
      </div>

      <div class="stage" aria-hidden="true">
        <!-- Anillos finos alrededor de la luna -->
        <svg class="rings" viewBox="0 0 560 560">
          <circle class="r" cx="370" cy="157" r="190"/>
          <circle class="r" cx="370" cy="157" r="245" stroke-dasharray="2 9" stroke-linecap="round"/>
          <circle class="r" cx="370" cy="157" r="305"/>
          <g class="orbit"><circle cx="615" cy="157" r="5" fill="#7775D6"/></g>
        </svg>

        <svg class="spark s1" viewBox="-1 -1 2 2"><use href="#star" fill="#7775D6"/></svg>
        <svg class="spark s2" viewBox="-1 -1 2 2"><use href="#star" fill="#5051AE"/></svg>
        <svg class="spark s3" viewBox="-1 -1 2 2"><use href="#star" fill="#7775D6"/></svg>

        <!-- Luna (rota) -->
        <div class="moon">
          <svg viewBox="0 0 200 200">
            <defs>
              <radialGradient id="moonG" cx=".36" cy=".32" r=".85">
                <stop offset="0" stop-color="#F6F5FF"/><stop offset=".6" stop-color="#DAD8F8"/><stop offset="1" stop-color="#B9B6EE"/>
              </radialGradient>
            </defs>
            <circle cx="100" cy="100" r="98" fill="url(#moonG)"/>
            <g fill="#C3C0F1">
              <circle cx="62" cy="68" r="17"/><circle cx="130" cy="54" r="10"/><circle cx="138" cy="112" r="20"/>
              <circle cx="86" cy="140" r="13"/><circle cx="50" cy="118" r="8"/><circle cx="114" cy="165" r="9"/><circle cx="164" cy="70" r="6"/>
            </g>
            <g fill="#F6F5FF" opacity=".75">
              <circle cx="58" cy="63" r="6"/><circle cx="133" cy="105" r="7"/><circle cx="84" cy="136" r="4"/>
            </g>
          </svg>
        </div>

        <!-- Avión (detrás del título, delante de la luna) -->
        <div class="plane">
          <svg viewBox="0 0 380 280" class="plane-float"><use href="#plane-color"/></svg>
        </div>

        <!-- Libro abierto: las páginas pasan una tras otra -->
        <div class="openbook">
          <svg viewBox="0 0 300 190">
            <ellipse cx="150" cy="176" rx="132" ry="9" fill="#252866" opacity=".12"/>
            <rect x="14" y="160" width="272" height="10" rx="5" fill="#252866"/>
            <path d="M26 160 L40 126 Q96 112 150 142 V160Z" fill="#E9E7FF"/>
            <path d="M274 160 L260 126 Q204 112 150 142 V160Z" fill="#E9E7FF"/>
            <g fill="none" stroke="#CBC9F4" stroke-width="2" stroke-linecap="round">
              <path d="M34 150 Q92 136 148 152"/><path d="M266 150 Q208 136 152 152"/>
              <path d="M32 156 Q92 144 148 158"/><path d="M268 156 Q208 144 152 158"/>
            </g>
            <path d="M150 140 Q78 108 44 54 Q104 62 150 124Z" fill="#FFFCF7" stroke="#CBC9F4" stroke-width="2" stroke-linejoin="round"/>
            <path d="M150 140 Q222 108 256 54 Q196 62 150 124Z" fill="#FFFCF7" stroke="#CBC9F4" stroke-width="2" stroke-linejoin="round"/>
            <g class="flip" style="--d:1.65s"><path d="M150 138 Q216 104 250 46 Q194 58 150 122Z" fill="#F4F3FF" stroke="#CBC9F4" stroke-width="2" stroke-linejoin="round"/></g>
            <g class="flip" style="--d:1.1s"><path d="M150 138 Q216 104 250 46 Q194 58 150 122Z" fill="#FFFCF7" stroke="#CBC9F4" stroke-width="2" stroke-linejoin="round"/></g>
            <g class="flip" style="--d:.55s"><path d="M150 138 Q216 104 250 46 Q194 58 150 122Z" fill="#F4F3FF" stroke="#CBC9F4" stroke-width="2" stroke-linejoin="round"/></g>
            <g class="flip" style="--d:0s">
              <path d="M150 138 Q216 104 250 46 Q194 58 150 122Z" fill="#FFFCF7" stroke="#CBC9F4" stroke-width="2" stroke-linejoin="round"/>
              <path d="M164 116 Q206 96 230 66 M166 126 Q210 108 238 78" fill="none" stroke="#E3E0F7" stroke-width="2" stroke-linecap="round"/>
            </g>
            <path d="M134 160 Q150 134 166 160Z" fill="#12142E"/>
            <path d="M142 160 Q150 146 158 160Z" fill="#5051AE"/>
          </svg>
        </div>

        <!-- Pila de libros: brinca en cadena -->
        <div class="stack">
          <svg viewBox="0 0 160 150">
            <ellipse class="shadow" cx="80" cy="140" rx="62" ry="7" fill="#252866"/>
            <g class="hop" style="--d:0s;--h:-5px">
              <rect x="10" y="104" width="140" height="28" rx="5" fill="#252866"/>
              <rect x="136" y="108" width="10" height="20" rx="2" fill="#FFFCF7"/>
              <rect x="22" y="104" width="6" height="28" fill="#7775D6"/><rect x="34" y="104" width="3" height="28" fill="#7775D6"/>
            </g>
            <g class="hop" style="--d:.1s;--h:-10px">
              <rect x="22" y="76" width="118" height="26" rx="5" fill="#7775D6"/>
              <rect x="126" y="80" width="10" height="18" rx="2" fill="#FFFCF7"/>
              <rect x="34" y="76" width="5" height="26" fill="#E9E7FF"/>
            </g>
            <g class="hop" style="--d:.2s;--h:-15px">
              <g transform="rotate(-3 75 61)">
                <rect x="12" y="48" width="126" height="26" rx="5" fill="#5051AE"/>
                <rect x="124" y="52" width="10" height="18" rx="2" fill="#FFFCF7"/>
                <rect x="24" y="48" width="5" height="26" fill="#CBC9F4"/><rect x="33" y="48" width="3" height="26" fill="#CBC9F4"/>
              </g>
            </g>
            <g class="hop" style="--d:.3s;--h:-21px">
              <rect x="34" y="22" width="96" height="24" rx="5" fill="#CBC9F4"/>
              <rect x="118" y="26" width="9" height="16" rx="2" fill="#FFFCF7"/>
              <rect x="46" y="22" width="5" height="24" fill="#252866"/>
              <use href="#star" transform="translate(84 10) scale(6)" fill="#7775D6"/>
            </g>
          </svg>
        </div>
      </div>
    </div>
  </div>

  <!-- LECTURA -->
  <section class="reading" id="leer">
    <div class="wrap">
      <div>
        <h2>Pensada para leer durante mucho tiempo</h2>
        <p class="sec-lead">Fondo cálido en lugar de blanco puro, una tipografía creada para leer en pantalla y un modo noche que tú decides activar. Pruébalo aquí mismo.</p>
      </div>
      <div class="reader" aria-label="Ejemplo de lectura">
        <svg class="scene" id="scene" viewBox="0 0 600 220" role="img" aria-label="Un pueblo de noche: las luces de las casas se apagan una a una y solo el jardín sigue brillando bajo las estrellas">
          <defs>
            <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#12142E"/><stop offset="1" stop-color="#2F3180"/></linearGradient>
            <radialGradient id="halo"><stop offset="0" stop-color="#CBC9F4" stop-opacity=".95"/><stop offset="1" stop-color="#CBC9F4" stop-opacity="0"/></radialGradient>
          </defs>
          <rect width="600" height="220" fill="url(#sky)"/>
          <g id="stars"></g>
          <g class="fly"><use href="#plane-white" x="0" y="40" width="46" height="34"/></g>
          <path d="M0 172 Q150 128 300 166 T600 150 V220 H0Z" fill="#1D2042"/>
          <path d="M0 198 Q200 166 400 192 T600 186 V220 H0Z" fill="#181B3A"/>
          <g fill="#252866">
            <rect x="30" y="146" width="70" height="48"/><polygon points="24,146 65,116 106,146" fill="#1D2042"/>
            <rect x="140" y="152" width="64" height="44"/><polygon points="134,152 172,124 210,152" fill="#1D2042"/>
            <rect x="245" y="140" width="76" height="52"/><polygon points="239,140 283,108 327,140" fill="#1D2042"/>
            <rect x="350" y="154" width="60" height="40"/><polygon points="344,154 380,128 416,154" fill="#1D2042"/>
          </g>
          <g>
            <rect class="win" style="--d:.8s" x="42" y="158" width="14" height="14" rx="2"/><rect class="win" style="--d:1.4s" x="72" y="158" width="14" height="14" rx="2"/>
            <rect class="win" style="--d:2s" x="150" y="164" width="13" height="13" rx="2"/><rect class="win" style="--d:2.6s" x="180" y="164" width="13" height="13" rx="2"/>
            <rect class="win" style="--d:3.2s" x="257" y="152" width="14" height="14" rx="2"/><rect class="win" style="--d:3.8s" x="295" y="152" width="14" height="14" rx="2"/>
            <rect class="win" style="--d:4.4s" x="362" y="166" width="12" height="12" rx="2"/><rect class="win" style="--d:5s" x="386" y="166" width="12" height="12" rx="2"/>
          </g>
          <g stroke="#7775D6" stroke-width="2.5"><line x1="458" y1="196" x2="458" y2="164"/><line x1="500" y1="200" x2="500" y2="150"/><line x1="544" y1="196" x2="544" y2="168"/></g>
          <g class="glow"><circle cx="458" cy="160" r="22" fill="url(#halo)"/></g>
          <g class="glow" style="animation-delay:.7s"><circle cx="500" cy="146" r="28" fill="url(#halo)"/></g>
          <g class="glow" style="animation-delay:1.4s"><circle cx="544" cy="164" r="20" fill="url(#halo)"/></g>
          <use href="#star" transform="translate(458 160) scale(8)" fill="#F4F3FF"/>
          <use href="#star" transform="translate(500 146) scale(11)" fill="#F4F3FF"/>
          <use href="#star" transform="translate(544 164) scale(7)" fill="#F4F3FF"/>
        </svg>
        <div class="reader-top">
          <strong>El jardín de las estrellas</strong>
          <div class="ctl" role="group" aria-label="Tamaño del texto">
            <button type="button" id="smaller" aria-label="Reducir texto">A−</button>
            <button type="button" id="bigger" aria-label="Aumentar texto">A+</button>
          </div>
          <button class="theme-toggle" id="themeBtn2" type="button" style="color:var(--link);border-color:var(--outline)" aria-pressed="false">Modo noche</button>
        </div>
        <div class="reader-body">
          <div class="story" id="story">
            <p class="first">Una historia comienza aquí… Las luces del pueblo se apagaron una a una, y solo el jardín siguió brillando bajo un cielo lleno de estrellas.</p>
            <p>Nadie supo decir quién había plantado las primeras semillas. Algunos aseguraban que fue el viento; otros, que una niña con un avión de papel había cruzado el valle antes del amanecer.</p>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- ESCRIBIR -->
  <section class="write" id="escribir">
    <div class="wrap">
      <div>
        <h2>Sube tu PDF y SAFIR lo separa en capítulos</h2>
        <p class="sec-lead">Si ya tienes tu obra escrita, no necesitas copiarla capítulo por capítulo. También puedes crear una obra nueva y publicar cada capítulo desde la plataforma.</p>
        <ol class="steps">
          <li>
            <div><h3>Sube tu archivo</h3><p>Elige el PDF de tu obra desde tu dispositivo.</p></div>
          </li>
          <li>
            <div><h3>Revisa la propuesta</h3><p>SAFIR sugiere dónde empieza cada capítulo. Tú marcas los que quieres conservar.</p></div>
          </li>
          <li>
            <div><h3>Publica</h3><p>Tus lectores ven los capítulos en orden y pueden continuar desde el último que leyeron.</p></div>
          </li>
        </ol>
      </div>

      <div class="demo" aria-label="Vista de ejemplo de la conversión de PDF a capítulos">
        <div class="file">
          <div class="icon" aria-hidden="true">PDF</div>
          <div><b>El jardín de las estrellas.pdf</b><small>48 páginas · ejemplo</small></div>
        </div>
        <button class="btn" id="proposeBtn" type="button">Proponer capítulos</button>
        <ul class="chapters" id="chapters" aria-live="polite"></ul>
        <button class="btn outline" id="publishBtn" type="button" hidden>Publicar capítulos marcados</button>
        <p class="status" id="status" role="status"></p>
      </div>
    </div>
  </section>

  <!-- CATÁLOGO -->
  <section class="catalog" id="catalogo">
    <div class="wrap">
      <h2>Historias para cada noche</h2>
      <p class="sec-lead">Fantasía, aventura, misterio y más. Explora portadas, guarda lo que quieras leer después y vuelve cuando quieras.</p>
    </div>
    <div class="marquee" aria-label="Portadas de ejemplo">
      <div class="track" id="track">
        <figure class="book"><svg viewBox="0 0 150 200" aria-hidden="true"><use href="#cv1"/></svg><figcaption>El jardín de las estrellas<span>Fantasía</span></figcaption></figure>
        <figure class="book"><svg viewBox="0 0 150 200" aria-hidden="true"><use href="#cv2"/></svg><figcaption>Cuentos del Altiplano<span>Relatos</span></figcaption></figure>
        <figure class="book"><svg viewBox="0 0 150 200" aria-hidden="true"><use href="#cv3"/></svg><figcaption>Cartas a la luna<span>Romance</span></figcaption></figure>
        <figure class="book"><svg viewBox="0 0 150 200" aria-hidden="true"><use href="#cv4"/></svg><figcaption>La biblioteca flotante<span>Aventura</span></figcaption></figure>
        <figure class="book"><svg viewBox="0 0 150 200" aria-hidden="true"><use href="#cv5"/></svg><figcaption>Río de tinta<span>Misterio</span></figcaption></figure>
        <figure class="book"><svg viewBox="0 0 150 200" aria-hidden="true"><use href="#cv6"/></svg><figcaption>Última estación<span>Ciencia ficción</span></figcaption></figure>
      </div>
    </div>
    <div class="wrap"><p class="small-note">Portadas ilustradas de ejemplo; los títulos son ficticios.</p></div>
  </section>

  <!-- LECTORES + COINS -->
  <section class="reader-hub" id="coins">
    <div class="wrap">
      <h2>Tu biblioteca te espera donde la dejaste</h2>
      <div class="hub">
        <article class="continue">
          <h3>Continuar leyendo</h3>
          <div class="row">
            <div class="cover" aria-hidden="true"><svg viewBox="0 0 380 280"><use href="#plane-white"/></svg></div>
            <div>
              <div class="book-title">El jardín de las estrellas</div>
              <div class="book-sub">Capítulo 4 · Tu lectura continúa aquí</div>
              <div class="progress" role="progressbar" aria-valuenow="58" aria-valuemin="0" aria-valuemax="100" aria-label="Avance de lectura"><i></i></div>
              <% if (logueado) { %>
              <a class="btn small" href="<%= contexto %>/auth/inicio">Leer ahora</a>
              <% } else { %>
              <a class="btn small" href="<%= contexto %>/auth/login" data-open="login">Leer ahora</a>
              <% } %>
            </div>
          </div>
        </article>
        <article class="coins">
          <h3>Mis coins</h3>
          <p>Tus recompensas de lectura, logros y compras viven en un solo saldo.</p>
          <div class="coin-row">
            <div class="coin" aria-hidden="true">S</div>
            <div class="coin-num" id="coinNum" aria-label="1,000 coins">1,000</div>
          </div>
          <% if (logueado) { %>
          <a class="btn small gold" href="<%= contexto %>/auth/inicio">Ver recompensas</a>
          <% } else { %>
          <a class="btn small gold" href="<%= contexto %>/auth/login" data-open="login">Ver recompensas</a>
          <% } %>
        </article>
      </div>
      <p class="small-note">Vista conceptual de ejemplo; los datos mostrados no son reales.</p>
    </div>
  </section>

  <!-- CTA -->
  <section class="final" id="unirme">
    <div class="wrap">
      <h2>Tu próxima historia te espera.</h2>
      <p>Descubre nuevas historias o continúa leyendo donde te quedaste.</p>
      <div class="actions">
        <% if (logueado) { %>
        <a class="btn on-bar" href="<%= contexto %>/auth/inicio">Ir a mi inicio</a>
        <% } else { %>
        <a class="btn on-bar" href="<%= contexto %>/auth/registro" data-open="register">Crear cuenta</a>
        <a class="btn outline" href="<%= contexto %>/auth/login" data-open="login">Iniciar sesión</a>
        <% } %>
      </div>
    </div>
  </section>
</main>

<footer>
  <div class="wrap">
    <a class="brand" href="#inicio" aria-label="SAFIR, inicio">
      <svg viewBox="0 0 380 280" aria-hidden="true"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </a>
    <span>Tus historias, en un solo lugar.</span>
  </div>
</footer>

<!-- Ventanas flotantes -->
<div class="overlay" id="overlay" hidden>

  <!-- INICIAR SESIÓN  →  POST /auth/login -->
  <div class="modal" id="modal-login" role="dialog" aria-modal="true" aria-labelledby="loginTitle" hidden>
    <button class="close" type="button" data-close aria-label="Cerrar">×</button>
    <div class="m-brand" aria-hidden="true">
      <svg class="lt" viewBox="0 0 380 280"><use href="#plane-color"/></svg>
      <svg class="dk" viewBox="0 0 380 280"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </div>
    <h2 id="loginTitle">Iniciar sesión</h2>
    <p class="m-sub">Entra para continuar tu lectura.</p>
    <form id="loginForm" action="<%= contexto %>/auth/login" method="post" novalidate>
      <label for="loginUser">Correo electrónico</label>
      <input id="loginUser" name="correo" type="email" maxlength="254" autocomplete="username" placeholder="tucorreo@ejemplo.com">
      <label for="loginPass">Contraseña</label>
      <div class="pw">
        <input id="loginPass" name="clave" type="password" autocomplete="current-password" placeholder="Tu contraseña">
        <button class="pw-toggle" type="button" aria-pressed="false" aria-label="Mostrar contraseña">Mostrar</button>
      </div>
      <p class="form-msg" id="loginMsg" role="status"></p>
      <button class="btn m-submit" type="submit">Iniciar sesión</button>
    </form>
    <p class="m-switch">¿No tienes una cuenta? <button class="link" type="button" data-open="register">Registrarse</button></p>
  </div>

  <!-- REGISTRO  →  POST /auth/registro -->
  <div class="modal" id="modal-register" role="dialog" aria-modal="true" aria-labelledby="regTitle" hidden>
    <button class="close" type="button" data-close aria-label="Cerrar">×</button>
    <div class="m-brand" aria-hidden="true">
      <svg class="lt" viewBox="0 0 380 280"><use href="#plane-color"/></svg>
      <svg class="dk" viewBox="0 0 380 280"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </div>
    <h2 id="regTitle">Crea tu cuenta</h2>
    <p class="m-sub">Únete para leer y publicar tus historias.</p>
    <form id="regForm" action="<%= contexto %>/auth/registro" method="post" novalidate>
      <label for="regNombre">Nombre público</label>
      <input id="regNombre" name="nombre" type="text" maxlength="60" autocomplete="nickname" placeholder="Cómo te verán los demás">
      <label for="regEmail">Correo electrónico</label>
      <input id="regEmail" name="correo" type="email" maxlength="254" autocomplete="email" placeholder="tucorreo@ejemplo.com">
      <label for="regPass">Contraseña (mínimo 8 caracteres)</label>
      <div class="pw">
        <input id="regPass" name="clave" type="password" minlength="8" autocomplete="new-password" placeholder="Crea una contraseña">
        <button class="pw-toggle" type="button" aria-pressed="false" aria-label="Mostrar contraseña">Mostrar</button>
      </div>
      <label for="regPass2">Repetir contraseña</label>
      <div class="pw">
        <input id="regPass2" name="repetir" type="password" minlength="8" autocomplete="new-password" placeholder="Repite tu contraseña">
        <button class="pw-toggle" type="button" aria-pressed="false" aria-label="Mostrar contraseña">Mostrar</button>
      </div>
      <p class="form-msg" id="regMsg" role="status"></p>
      <button class="btn m-submit" type="submit">Crear cuenta</button>
    </form>
    <p class="m-switch" style="margin-top:1.1rem">¿Ya tienes una cuenta? <button class="link" type="button" data-open="login">Iniciar sesión</button></p>
    <p class="m-legal">Al registrarte aceptas los términos de uso y la política de privacidad.</p>
  </div>
</div>

<script>
(function () {
  var root = document.documentElement;
  var btns = [document.getElementById('themeBtn'), document.getElementById('themeBtn2')];

  function setTheme(t) {
    if (t === 'dark') root.setAttribute('data-theme', 'dark'); else root.removeAttribute('data-theme');
    btns.forEach(function (b) {
      b.setAttribute('aria-pressed', t === 'dark' ? 'true' : 'false');
      b.textContent = t === 'dark' ? 'Modo claro' : 'Modo noche';
    });
    try { localStorage.setItem('safir-theme', t); } catch (e) {}
  }
  var saved = null;
  try { saved = localStorage.getItem('safir-theme'); } catch (e) {}
  setTheme(saved === 'dark' ? 'dark' : 'light');
  btns.forEach(function (b) {
    b.addEventListener('click', function () {
      setTheme(root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
    });
  });

  // Tamaño del texto de lectura
  var story = document.getElementById('story');
  var size = 1.2;
  function applySize() { story.style.fontSize = size + 'rem'; }
  document.getElementById('bigger').addEventListener('click', function () { size = Math.min(1.7, +(size + 0.1).toFixed(2)); applySize(); });
  document.getElementById('smaller').addEventListener('click', function () { size = Math.max(1, +(size - 0.1).toFixed(2)); applySize(); });

  // Estrellas del cielo (generadas)
  var NS = 'http://www.w3.org/2000/svg';
  var starsG = document.getElementById('stars');
  [[40,30,6],[95,55,4],[150,22,5],[210,48,7],[270,26,4],[330,60,5],[390,24,6],[450,44,4],[520,28,7],[570,66,4],[20,84,4],[300,96,3]].forEach(function (p, i) {
    var o = document.createElementNS(NS, 'g'); o.setAttribute('transform', 'translate(' + p[0] + ' ' + p[1] + ')');
    var t = document.createElementNS(NS, 'g'); t.setAttribute('class', 'tw'); t.style.animationDelay = (i * 0.37) + 's';
    var u = document.createElementNS(NS, 'use'); u.setAttribute('href', '#star'); u.setAttribute('transform', 'scale(' + p[2] + ')'); u.setAttribute('fill', '#E9E7FF');
    t.appendChild(u); o.appendChild(t); starsG.appendChild(o);
  });

  // Carrusel de portadas: se duplica para el bucle continuo
  var track = document.getElementById('track');
  Array.prototype.slice.call(track.children).forEach(function (f) {
    var c = f.cloneNode(true); c.setAttribute('aria-hidden', 'true'); c.setAttribute('data-dup', ''); track.appendChild(c);
  });

  // Animaciones al entrar en pantalla
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  function countUp(el, to, ms) {
    if (reduce) return;
    var s = null;
    function f(t) {
      if (!s) s = t;
      var k = Math.min(1, (t - s) / ms);
      el.textContent = Math.round(to * (1 - Math.pow(1 - k, 3))).toLocaleString('en-US');
      if (k < 1) requestAnimationFrame(f);
    }
    requestAnimationFrame(f);
  }
  var scene = document.getElementById('scene');
  var rvEls = Array.prototype.slice.call(document.querySelectorAll('.hub article, .demo, .steps li'));
  if (!reduce) rvEls.forEach(function (e) { e.classList.add('rv'); });
  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (!en.isIntersecting) return;
        var el = en.target;
        el.classList.add('in');
        if (el === scene) el.classList.add('play');
        if (el.classList.contains('coins')) countUp(document.getElementById('coinNum'), 1000, 1600);
        io.unobserve(el);
      });
    }, { threshold: 0.3 });
    [scene].concat(rvEls).forEach(function (el) { io.observe(el); });
  } else {
    rvEls.forEach(function (e) { e.classList.add('in'); });
    scene.classList.add('play');
  }

  // Ventanas flotantes: iniciar sesión / registrarse
  var overlay = document.getElementById('overlay');
  var modals = { login: document.getElementById('modal-login'), register: document.getElementById('modal-register') };
  var lastFocus = null, current = null;

  function openModal(name) {
    if (overlay.hidden) lastFocus = document.activeElement;
    Object.keys(modals).forEach(function (k) { modals[k].hidden = (k !== name); });
    overlay.hidden = false;
    current = name;
    document.body.style.overflow = 'hidden';
    var first = modals[name].querySelector('input, .s-btn');
    setTimeout(function () { if (first) first.focus(); }, 40);
  }
  function closeModal() {
    overlay.hidden = true;
    current = null;
    document.body.style.overflow = '';
    if (lastFocus && lastFocus.focus) lastFocus.focus();
  }

  document.addEventListener('click', function (e) {
    var opener = e.target.closest('[data-open]');
    if (opener) { e.preventDefault(); openModal(opener.getAttribute('data-open')); return; }
    if (e.target.closest('[data-close]') || e.target === overlay) closeModal();
  });

  document.addEventListener('keydown', function (e) {
    if (overlay.hidden) return;
    if (e.key === 'Escape') { closeModal(); return; }
    if (e.key !== 'Tab') return;
    var items = Array.prototype.filter.call(
      modals[current].querySelectorAll('button, input, a[href]'),
      function (el) { return el.offsetParent !== null; }
    );
    if (!items.length) return;
    var first = items[0], last = items[items.length - 1];
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
  });

  function say(el, text, kind) {
    el.className = 'form-msg' + (kind ? ' ' + kind : '');
    el.textContent = text;
  }
  function isEmail(v) { return /^[^ @]+@[^ @]+[.][^ @]+$/.test(v); }
  // Mostrar / ocultar contraseña
  Array.prototype.forEach.call(document.querySelectorAll('.pw-toggle'), function (btn) {
    btn.addEventListener('click', function () {
      var input = btn.previousElementSibling;
      var show = input.type === 'password';
      input.type = show ? 'text' : 'password';
      btn.textContent = show ? 'Ocultar' : 'Mostrar';
      btn.setAttribute('aria-pressed', show ? 'true' : 'false');
      btn.setAttribute('aria-label', show ? 'Ocultar contraseña' : 'Mostrar contraseña');
    });
  });

  function stop(e, el, text) { e.preventDefault(); say(el, text, 'err'); }

  // Iniciar sesión: valida y, si todo está bien, envía el formulario a /auth/login
  document.getElementById('loginForm').addEventListener('submit', function (e) {
    var user = document.getElementById('loginUser').value.trim();
    var pass = document.getElementById('loginPass').value;
    var msg = document.getElementById('loginMsg');
    if (!isEmail(user)) return stop(e, msg, 'Escribe un correo electrónico válido.');
    if (!pass) return stop(e, msg, 'Escribe tu contraseña.');
    say(msg, 'Ingresando…', 'ok');
  });

  // Registro: valida y, si todo está bien, envía el formulario a /auth/registro
  document.getElementById('regForm').addEventListener('submit', function (e) {
    var nombre = document.getElementById('regNombre').value.trim();
    var mail = document.getElementById('regEmail').value.trim();
    var pass = document.getElementById('regPass').value;
    var pass2 = document.getElementById('regPass2').value;
    var msg = document.getElementById('regMsg');
    if (!nombre) return stop(e, msg, 'Escribe tu nombre público.');
    if (nombre.length > 60) return stop(e, msg, 'El nombre público admite hasta 60 caracteres.');
    if (!isEmail(mail)) return stop(e, msg, 'Escribe un correo electrónico válido.');
    if (pass.length < 8) return stop(e, msg, 'La contraseña debe tener al menos 8 caracteres.');
    if (pass !== pass2) return stop(e, msg, 'Las contraseñas no coinciden.');
    say(msg, 'Creando tu cuenta…', 'ok');
  });

  // Demo PDF -> capítulos
  var chapters = [
    { t: 'Capítulo 1 · Las luces del pueblo', p: 'págs. 1–11' },
    { t: 'Capítulo 2 · La niña del avión de papel', p: 'págs. 12–22' },
    { t: 'Capítulo 3 · Semillas', p: 'págs. 23–34' },
    { t: 'Capítulo 4 · Bajo un cielo lleno de estrellas', p: 'págs. 35–48' }
  ];
  var list = document.getElementById('chapters');
  var propose = document.getElementById('proposeBtn');
  var publish = document.getElementById('publishBtn');
  var status = document.getElementById('status');

  propose.addEventListener('click', function () {
    list.innerHTML = '';
    status.textContent = '';
    chapters.forEach(function (c, i) {
      var li = document.createElement('li');
      li.style.animationDelay = (i * 80) + 'ms';
      li.innerHTML = '<input type="checkbox" id="ch' + i + '" checked><label for="ch' + i + '">' + c.t + '</label><span>' + c.p + '</span>';
      list.appendChild(li);
    });
    publish.hidden = false;
    propose.textContent = 'Volver a proponer';
    status.textContent = 'SAFIR propone ' + chapters.length + ' capítulos. Desmarca los que no quieras publicar.';
  });

  publish.addEventListener('click', function () {
    var n = list.querySelectorAll('input:checked').length;
    status.textContent = n === 0
      ? 'Marca al menos un capítulo para publicar.'
      : (n === 1 ? 'Se publicó 1 capítulo (ejemplo).' : 'Se publicaron ' + n + ' capítulos (ejemplo).');
  });
})();
</script>
</body>
</html>
