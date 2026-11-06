
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Catálogo de obras | SAFIR</title>

    <style>
        :root {
            --indigo: #292866;
            --indigo-light: #414080;
            --lavender: #eeeaff;
            --lavender-dark: #dcd5ff;
            --cream: #fffcf8;
            --white: #ffffff;
            --text: #292943;
            --muted: #77758d;
            --gold: #d7ad55;
            --border: #e8e3f6;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: "Segoe UI", Arial, sans-serif;
            background: var(--cream);
            color: var(--text);
            min-height: 100vh;
        }

        .navbar {
            background: var(--white);
            border-bottom: 1px solid var(--border);
            padding: 18px 7%;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .logo {
            color: var(--indigo);
            font-size: 27px;
            font-weight: 800;
            letter-spacing: 2px;
        }

        .nav-link {
            color: var(--indigo);
            text-decoration: none;
            font-weight: 600;
            padding: 10px 17px;
            border-radius: 25px;
            transition: .2s;
        }

        .nav-link:hover {
            background: var(--lavender);
        }

        .container {
            max-width: 1180px;
            width: 90%;
            margin: 45px auto;
        }

        .hero {
            background: linear-gradient(120deg, #292866, #55509a);
            color: white;
            padding: 48px 45px;
            border-radius: 24px;
            margin-bottom: 35px;
            position: relative;
            overflow: hidden;
        }

        .hero::after {
            content: "✦";
            position: absolute;
            right: 65px;
            top: 5px;
            font-size: 130px;
            color: rgba(255,255,255,.12);
        }

        .hero h1 {
            font-family: Georgia, serif;
            font-size: clamp(30px, 4vw, 42px);
            margin-bottom: 13px;
            position: relative;
            z-index: 1;
        }

        .hero p {
            font-size: 16px;
            color: #e5e1ff;
            line-height: 1.7;
            max-width: 570px;
            position: relative;
            z-index: 1;
        }

        .search-card {
            background: white;
            border: 1px solid var(--border);
            border-radius: 20px;
            padding: 25px;
            margin-bottom: 35px;
            box-shadow: 0 8px 25px rgba(41,40,102,.04);
        }

        .search-card h2 {
            font-size: 19px;
            color: var(--indigo);
            margin-bottom: 18px;
        }

        .search-form {
            display: grid;
            grid-template-columns: 1.5fr 1fr auto auto;
            gap: 12px;
            align-items: end;
        }

        .field label {
            display: block;
            font-size: 13px;
            font-weight: 650;
            margin-bottom: 8px;
            color: var(--text);
        }

        .field input {
            width: 100%;
            padding: 13px 15px;
            border: 1px solid var(--border);
            border-radius: 12px;
            outline: none;
            font-size: 14px;
            color: var(--text);
            background: #fdfcff;
        }

        .field input:focus {
            border-color: var(--indigo-light);
            box-shadow: 0 0 0 3px rgba(85,80,154,.10);
        }

        .btn {
            display: inline-block;
            padding: 13px 22px;
            border: none;
            border-radius: 12px;
            background: var(--indigo);
            color: white;
            font-weight: 650;
            font-size: 14px;
            text-decoration: none;
            text-align: center;
            cursor: pointer;
            transition: .2s;
        }

        .btn:hover {
            background: var(--indigo-light);
            transform: translateY(-2px);
        }

        .btn-clear {
            background: var(--lavender);
            color: var(--indigo);
        }

        .btn-clear:hover {
            background: var(--lavender-dark);
            color: var(--indigo);
        }

        .section-title {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }

        .section-title h2 {
            font-family: Georgia, serif;
            font-size: 27px;
            color: var(--indigo);
        }

        .results {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
            gap: 23px;
        }

        .book-card {
            background: white;
            border: 1px solid var(--border);
            border-radius: 18px;
            overflow: hidden;
            transition: .25s;
            box-shadow: 0 6px 20px rgba(41,40,102,.04);
        }

        .book-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 14px 28px rgba(41,40,102,.10);
        }

        .book-cover {
            height: 155px;
            background: linear-gradient(135deg, #292866, #8c83c8);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 55px;
            overflow: hidden;
        }

        .book-cover img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: block;
        }

        .book-content {
            padding: 22px;
        }

        .book-content h3 {
            font-family: Georgia, serif;
            font-size: 21px;
            margin-bottom: 10px;
            line-height: 1.35;
        }

        .book-content h3 a {
            color: var(--indigo);
            text-decoration: none;
        }

        .book-content h3 a:hover {
            color: #7770ba;
        }

        .book-author {
            color: var(--muted);
            font-size: 13px;
            margin-bottom: 15px;
        }

        .tag {
            display: inline-block;
            background: var(--lavender);
            color: var(--indigo);
            border-radius: 20px;
            padding: 6px 11px;
            font-size: 11px;
            font-weight: 650;
            margin: 0 4px 8px 0;
        }

        .description {
            color: #66647b;
            font-size: 13px;
            line-height: 1.7;
            margin: 12px 0;
        }

        .book-stats {
            border-top: 1px solid var(--border);
            margin-top: 15px;
            padding-top: 14px;
            color: var(--muted);
            font-size: 12px;
            line-height: 1.8;
        }

        .empty-state {
            background: white;
            border: 1px dashed var(--lavender-dark);
            border-radius: 20px;
            text-align: center;
            padding: 55px 20px;
            grid-column: 1 / -1;
        }

        .empty-icon {
            font-size: 55px;
            margin-bottom: 15px;
        }

        .empty-state h3 {
            color: var(--indigo);
            font-family: Georgia, serif;
            font-size: 23px;
            margin-bottom: 10px;
        }

        .empty-state p {
            color: var(--muted);
            line-height: 1.7;
        }

        .library-link {
            display: inline-block;
            margin-top: 30px;
            padding: 14px 23px;
            border-radius: 13px;
            color: var(--indigo);
            background: var(--lavender);
            text-decoration: none;
            font-weight: 650;
            transition: .2s;
        }

        .library-link:hover {
            background: var(--lavender-dark);
        }

        footer {
            text-align: center;
            padding: 35px 15px;
            color: var(--muted);
            font-size: 13px;
            margin-top: 45px;
            border-top: 1px solid var(--border);
        }

        @media (max-width: 720px) {
            .navbar {
                padding: 16px 5%;
            }

            .container {
                width: 92%;
                margin-top: 25px;
            }

            .hero {
                padding: 35px 25px;
            }

            .search-form {
                grid-template-columns: 1fr;
            }

            .search-form .btn {
                width: 100%;
            }

            .section-title h2 {
                font-size: 23px;
            }
        }
    </style>
</head>

<body>

<header class="navbar">
    <div class="logo">SAFIR ✦</div>

    <a class="nav-link"
       href="${pageContext.request.contextPath}/biblioteca">
        Mi biblioteca
    </a>
</header>

<main class="container">

    <section class="hero">
        <h1>Descubre nuevas historias</h1>
        <p>
            Un universo de historias te espera.
            Encuentra tu próxima lectura favorita,
            explora nuevos géneros y disfruta cada capítulo.
        </p>
    </section>

    <section class="search-card">
        <h2>Encuentra tu próxima lectura</h2>

        <form class="search-form" method="get"
              action="${pageContext.request.contextPath}/catalogo">

            <div class="field">
                <label for="q">Buscar por título o autor</label>
                <input type="text" id="q" name="q"
                       placeholder="¿Qué historia buscas?"
                       value="<c:out value='${busqueda}'/>">
            </div>

            <div class="field">
                <label for="genero">Género literario</label>
                <input type="text" id="genero" name="genero"
                       placeholder="Ej. Romance, fantasía..."
                       value="<c:out value='${generoSeleccionado}'/>">
            </div>

            <button class="btn" type="submit">Buscar obras</button>

            <a class="btn btn-clear"
               href="${pageContext.request.contextPath}/catalogo">
                Limpiar
            </a>
        </form>
    </section>

    <section>
        <div class="section-title">
            <h2>Historias para descubrir</h2>
        </div>

        <div class="results">

            <c:choose>
                <c:when test="${empty obras}">
                    <div class="empty-state">
                        <div class="empty-icon">📚</div>
                        <h3>Aún no hay historias disponibles</h3>
                        <p>
                            Estamos preparando este espacio para ti.
                            Pronto encontrarás nuevas historias para leer
                            y disfrutar en SAFIR.
                        </p>
                    </div>
                </c:when>

                <c:otherwise>
                    <c:forEach var="obra" items="${obras}">
                        <article class="book-card">

                            <div class="book-cover">
                                <c:choose>
                                    <c:when test="${not empty obra.portadaRuta}">
                                        <img src="${pageContext.request.contextPath}/media/<c:out value='${obra.portadaRuta}'/>"
                                             alt="Portada de <c:out value='${obra.titulo}'/>" loading="lazy">
                                    </c:when>
                                    <c:otherwise>✦</c:otherwise>
                                </c:choose>
                            </div>

                            <div class="book-content">

                                <h3>
                                    <a href="${pageContext.request.contextPath}/obra?id=${obra.id}">
                                        <c:out value="${obra.titulo}"/>
                                    </a>
                                </h3>

                                <p class="book-author">
                                    Por <c:out value="${obra.autor}"/>
                                </p>

                                <span class="tag">
                                    <c:out value="${obra.genero}"/>
                                </span>

                                <span class="tag">
                                    <c:out value="${obra.clasificacion}"/>
                                </span>

                                <c:if test="${not empty obra.descripcion}">
                                    <p class="description">
                                        <c:out value="${obra.descripcion}"/>
                                    </p>
                                </c:if>

                                <div class="book-stats">
                                    <div>
                                        📖 Capítulos:
                                        <c:out value="${obra.capitulosPublicados}"/>
                                    </div>

                                    <div>
                                        ⭐ Valoración:
                                        <c:out value="${obra.promedio}"/>
                                        (<c:out value="${obra.totalValoraciones}"/>)
                                    </div>

                                    <div>
                                        Estado:
                                        <c:out value="${obra.avance}"/>
                                    </div>
                                </div>

                                <c:if test="${not empty obra.etiquetas}">
                                    <p class="description">
                                        <strong>Etiquetas:</strong>
                                        <c:out value="${obra.etiquetas}"/>
                                    </p>
                                </c:if>

                            </div>
                        </article>
                    </c:forEach>
                </c:otherwise>
            </c:choose>

        </div>
    </section>

    <div style="text-align:center;">
        <a class="library-link"
           href="${pageContext.request.contextPath}/biblioteca">
            ♡ Ir a mi biblioteca
        </a>
    </div>

</main>

<footer>
    SAFIR · Un lugar para descubrir y compartir historias ✦
</footer>

</body>
</html>
