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
3. **Configurar las variables de entorno** (ver la sección [Configuración](#️-configuración)). Como mínimo hay que definir `SAFIR_DB_CLAVE` con la contraseña de tu PostgreSQL. **No escribas contraseñas dentro del código.**
4. **Compilar:**
   ```bash
   mvn clean package
   ```
5. **Desplegar** el archivo `target/safir-1.0-SNAPSHOT.war` en Tomcat.
6. **Abrir** en el navegador: `http://localhost:8080/safir`

---

## ⚙️ Configuración

SAFIR lee sus datos secretos de **variables de entorno**, nunca del código. En el repositorio está la plantilla [`.env.example`](.env.example) con todas las variables y su explicación.

> Java no carga archivos `.env` automáticamente. La plantilla sirve de lista de referencia: cada variable se define en tu sistema o en tu servidor.

| Variable | ¿Obligatoria? | Para qué sirve |
|---|---|---|
| `SAFIR_DB_CLAVE` | **Sí** | Contraseña de PostgreSQL |
| `SAFIR_DB_URL` | No | Dirección de la base (por defecto `localhost:5432/safir`) |
| `SAFIR_DB_USUARIO` | No | Usuario de PostgreSQL (por defecto `postgres`) |
| `SAFIR_URL_BASE`, `SAFIR_BASE_URL` | No | Dirección pública de la app |
| `SAFIR_SMTP_HOST`, `_PORT`, `_USER`, `_PASS`, `_FROM` | No | Envío de correos (sin ellos, el código sale en consola) |
| `PAYPAL_CLIENT_ID`, `PAYPAL_SECRET`, `PAYPAL_BASE_URL` | No | Pagos con PayPal |
| `SAFIR_YAPE_NUMERO`, `SAFIR_YAPE_TITULAR` | No | Pagos con Yape |
| `SAFIR_GOOGLE_*`, `SAFIR_FACEBOOK_*`, `SAFIR_X_*` (`_ID` y `_SECRET`) | No | Login social |
| `SAFIR_UPLOADS`, `SAFIR_IMPORTACIONES` | No | Carpetas de archivos subidos |
| `SAFIR_PRIVACIDAD_CORREO` | No | Correo de contacto en la política de privacidad |

**Cómo definirlas:**

- **Windows (permanente):** `setx SAFIR_DB_CLAVE "tu-clave"` y luego cerrar y volver a abrir NetBeans o Tomcat.
- **Linux / Mac:** `export SAFIR_DB_CLAVE="tu-clave"` antes de iniciar Tomcat.
- **NetBeans:** Proyecto → Propiedades → Run → *VM Options* → `-DSAFIR_DB_CLAVE=tu-clave`.

Cada integrante usa **su propia** clave local. Nunca subas valores reales a Git.

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
