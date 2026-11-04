<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recuperar contraseña | SAFIR</title>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">

    <style>
        :root {
            --indigo: #252866;
            --lavanda: #7775D6;
            --lavanda-claro: #E9E7FF;
            --blanco-calido: #FFFCF7;
            --texto: #292936;
        }

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 24px;
            background: var(--blanco-calido);
            color: var(--texto);
            font-family: "DM Sans", sans-serif;
        }

        .tarjeta {
            width: 100%;
            max-width: 440px;
            padding: 36px;
            background: white;
            border: 1px solid var(--lavanda-claro);
            border-radius: 18px;
            box-shadow: 0 12px 32px rgba(37, 40, 102, 0.08);
        }

        h1 {
            margin: 0 0 12px;
            color: var(--indigo);
            font-size: 28px;
        }

        p {
            line-height: 1.6;
        }

        label {
            display: block;
            margin: 22px 0 8px;
            font-weight: 600;
        }

        input {
            width: 100%;
            padding: 13px 14px;
            border: 1px solid #c9c8dc;
            border-radius: 9px;
            font: inherit;
        }

        input:focus {
            outline: 3px solid var(--lavanda-claro);
            border-color: var(--lavanda);
        }

        button {
            width: 100%;
            margin-top: 20px;
            padding: 13px;
            border: 0;
            border-radius: 9px;
            background: var(--indigo);
            color: white;
            font: inherit;
            font-weight: 700;
            cursor: pointer;
        }

        button:hover {
            background: var(--lavanda);
        }

        .volver {
            display: inline-block;
            margin-top: 20px;
            color: var(--indigo);
            text-decoration: none;
        }

        .volver:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <main class="tarjeta">
        <h1>¿Olvidaste tu contraseña?</h1>
        <p>Ingresa el correo asociado a tu cuenta SAFIR. Te indicaremos cómo continuar con la recuperación.</p>

        <form action="#" method="post">
            <label for="correo">Correo electrónico</label>
            <input
                type="email"
                id="correo"
                name="correo"
                placeholder="tu@correo.com"
                autocomplete="email"
                required
            >

            <button type="submit">Continuar</button>
        </form>

        <a class="volver" href="${pageContext.request.contextPath}/login">
            Volver al inicio de sesión
        </a>
    </main>
</body>
</html>