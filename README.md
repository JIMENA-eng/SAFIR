# ✈️ SAFIR

**Tus historias, en un solo lugar.**

SAFIR es una plataforma web donde las personas pueden **leer, publicar y comentar historias** por capítulos. Combina una biblioteca digital con una comunidad literaria: los autores publican sus obras y los lectores las descubren, las guardan, las valoran y conversan sobre ellas.

> Proyecto del curso **EST323 · Ingeniería de Software II** — Facultad de Ingeniería Estadística e Informática, Universidad Nacional del Altiplano (UNA-Puno).

---

## 🎯 ¿Qué se puede hacer en SAFIR?

### 👤 Como lector
- Crear una cuenta, iniciar sesión y recuperar la contraseña.
- Explorar el **catálogo de obras** por género y etiquetas.
- Leer capítulos y **continuar leyendo desde donde se quedó** (el sistema guarda el progreso).
- **Valorar** obras de 1 a 5 estrellas y escribir comentarios.
- Guardar obras en su **biblioteca** y seguir a sus autores favoritos.
- Recibir **notificaciones** cuando un autor publica un capítulo nuevo.
- Usar **monedas** (billetera) para desbloquear capítulos de pago.

### ✍️ Como autor
- Crear obras con título, portada, descripción y género.
- Publicar y administrar capítulos desde su **panel de autor**.
- Ver estadísticas de su obra: lecturas, valoraciones y seguidores.
- Cualquier lector puede **convertirse en autor** desde su cuenta.

### 🛡️ Como moderador / administrador
- Atender reportes de contenido inapropiado y retirar comentarios.

---

## 🧱 Tecnologías

| Parte | Tecnología |
|---|---|
| Lenguaje | Java 21 |
| Plataforma web | Jakarta EE 10 (Servlets y JSP) |
| Base de datos | PostgreSQL |
| Acceso a datos | JDBC con patrón DAO |
| Seguridad | Contraseñas cifradas con BCrypt, sesiones, filtros de autenticación y de roles |
| Construcción | Maven (empaquetado `.war`) |
| Servidor | Apache Tomcat 10+ |

**Organización del código (MVC):**

```
src/main/java/com/safir/
├── modelo/        → objetos del negocio (Obra, Capítulo, Usuario…)
├── dao/           → consultas a la base de datos
├── controlador/   → servlets que atienden cada petición
├── seguridad/     → filtros de acceso y cifrado de contraseñas
└── config/        → conexión a la base de datos
src/main/webapp/
├── WEB-INF/vistas/ → páginas JSP (lo que ve el usuario)
└── assets/css/     → estilos
```

---

## 🗄️ Base de datos

El modelo está en PostgreSQL e incluye usuarios y roles, obras, capítulos (con historial de versiones), lecturas y progreso, valoraciones, comentarios, reportes de moderación, biblioteca, seguimientos, notificaciones, feed de novedades y auditoría. Las estadísticas de cada obra se actualizan solas mediante *triggers*.

El script SQL y el diagrama entidad-relación están en la rama `base-de-datos`.

---

## 🚀 Cómo ejecutarlo

1. **Requisitos:** JDK 21, Maven, PostgreSQL y Apache Tomcat 10 o superior.
2. **Crear la base de datos:** ejecutar el script SQL del modelo de datos en PostgreSQL (crea la base `safir`, las tablas y los datos iniciales).
3. **Configurar la conexión** en `src/main/java/com/safir/config/ConexionBD.java` con el usuario y la contraseña de tu PostgreSQL.
4. **Compilar:**
   ```bash
   mvn clean package
   ```
5. **Desplegar** el archivo `target/safir-1.0-SNAPSHOT.war` en Tomcat.
6. **Abrir** en el navegador: `http://localhost:8080/safir`

---

## 🗺️ Estado del proyecto

El desarrollo avanza por «vueltas» de tres semanas.

- ✅ Registro, inicio de sesión y roles
- ✅ Catálogo, ficha de obra y lector de capítulos con progreso
- ✅ Panel del autor y gestión de capítulos
- ✅ Comentarios, valoraciones, biblioteca y seguimiento
- ✅ Perfiles con imagen, billetera y monedas
- 🔄 Importación de novelas desde PDF con vista previa
- 🔄 Moderación y bloqueo de cuenta tras intentos fallidos
- 📋 Música ambiental para la lectura

---

## 👥 Equipo

- Paricela Yana Jimena Yessica
- Peralta Lopez Etzel Yuliza
- Umiña Machaca Beatriz

**Docente:** Milton Vladimir Mamani Calisaya

---

## 🎨 Identidad visual

Paleta: índigo `#252866`, lavanda `#7775D6`, blanco cálido `#FFFCF7` y dorado `#F2B84B` (solo para las monedas). Tipografías: **DM Sans** para la interfaz y **Literata** para leer las historias.
