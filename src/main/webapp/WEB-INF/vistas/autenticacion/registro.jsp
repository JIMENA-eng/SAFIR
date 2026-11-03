<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Crear cuenta | SAFIR</title>
</head>
<body>
    <h1>SAFIR</h1>
    <h2>Crear cuenta</h2>

    <% if (request.getAttribute("error") != null) { %>
        <p style="color:red">${error}</p>
    <% } %>

    <form action="${pageContext.request.contextPath}/auth/registro"
      method="post" enctype="multipart/form-data">
        <label>Nombre público</label><br>
        <input type="text" name="nombre" maxlength="60" required><br><br>

        <label>Correo electrónico</label><br>
        <input type="email" name="correo" maxlength="254" required><br><br>

        <label>Contraseña (mínimo 8 caracteres)</label><br>
        <input type="password" name="clave" minlength="8" required><br><br>

        <label>Repetir contraseña</label><br>
        <input type="password" name="repetir" minlength="8" required><br><br>

        <label>Foto de perfil (opcional)</label><br>
        <input type="file" name="avatar" accept="image/png,image/jpeg,image/webp"><br><br>

        <label>Foto de portada (opcional)</label><br>
        <input type="file" name="portada" accept="image/png,image/jpeg,image/webp"><br>
        <small>Puedes omitirlas y agregarlas luego desde tu perfil.</small><br><br>

        <button type="submit">Registrarme</button>
    </form>

    <p>¿Ya tienes cuenta?
        <a href="${pageContext.request.contextPath}/auth/login">
            Inicia sesión
        </a>
    </p>
</body>
</html>