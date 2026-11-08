package com.safir.util;

import com.safir.modelo.Capitulo;
import jakarta.servlet.http.Part;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamConstants;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.encryption.InvalidPasswordException;
import org.apache.pdfbox.text.PDFTextStripper;

/**
 * Lee un archivo (PDF, DOCX o TXT) y lo separa en capítulos.
 *
 * Un capítulo empieza en una línea como "Capítulo 1", "CAPÍTULO 2: Título",
 * "Capitulo III" o "Capítulo tres". Si después del número no hay título, se usa
 * la línea siguiente cuando parece un título corto. Lo que haya antes del
 * primer encabezado (portada, índice, prólogo) se descarta.
 *
 * Los errores de contenido se informan con IllegalArgumentException, cuyo
 * mensaje se puede mostrar tal cual al autor.
 */
public final class ImportadorCapitulos {

    public static final long MAX_ARCHIVO = 20L * 1024 * 1024;
    public static final int MAX_CAPITULOS = 500;

    private static final int MAX_TITULO = 150;
    private static final int MAX_LINEA_ENCABEZADO = 120;
    private static final int MAX_XML = 40 * 1024 * 1024;
    private static final int MAX_PAGINAS_PDF = 3000;
    private static final String NS_WORD =
            "http://schemas.openxmlformats.org/wordprocessingml/2006/main";

    private enum Tipo { PDF, DOCX, TXT }

    // ---- Reconocimiento de encabezados ------------------------------------

    private static final String UNIDADES =
            "uno|una|un|dos|tres|cuatro|cinco|seis|siete|ocho|nueve";
    private static final String DECENAS =
            "treinta|cuarenta|cincuenta|sesenta|setenta|ochenta|noventa";
    private static final String PALABRA =
            "veinti(?:uno|un|[uú]n|d[oó]s|tr[eé]s|cuatro|cinco|seis|siete|ocho|nueve)"
            + "|(?:" + DECENAS + ")(?:\\s+y\\s+(?:" + UNIDADES + "))?"
            + "|diez|once|doce|trece|catorce|quince|diecis[eé]is|diecisiete"
            + "|dieciocho|diecinueve|veinte|cien|ciento"
            + "|" + UNIDADES
            + "|primero|segundo|tercero|cuarto|quinto|sexto|s[eé]ptimo"
            + "|octavo|noveno|d[eé]cimo";
    private static final String NUMERO =
            "\\d{1,4}|(?-i:[IVXLCDM]{1,8})|" + PALABRA;

    private static final Pattern ENCABEZADO = Pattern.compile(
            "^(?:cap[ií]tulo\\s+|cap\\.\\s*|chapter\\s+)"
            + "(" + NUMERO + ")(?![\\p{L}\\d])\\s*[.:)\\-–—]*\\s*(.*)$",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);

    /** Línea de índice: "Capítulo 1 ........ 5" (puntos guía + página). */
    private static final Pattern INDICE =
            Pattern.compile("[.·…]{3,}\\s*\\d+\\s*$");

    private ImportadorCapitulos() {}

    // ---- API pública --------------------------------------------------------

    public static boolean hayArchivo(Part p) {
        return p != null && p.getSize() > 0;
    }

    /** Lee el archivo subido y devuelve los capítulos (titulo y contenido). */
    public static List<Capitulo> leer(Part p) {
        if (p.getSize() > MAX_ARCHIVO) {
            throw new IllegalArgumentException(
                "El archivo supera el máximo de "
                + (MAX_ARCHIVO / 1024 / 1024) + " MB.");
        }

        byte[] datos;
        try (InputStream in = p.getInputStream()) {
            datos = in.readNBytes((int) MAX_ARCHIVO + 1);
        } catch (IOException e) {
            throw new IllegalArgumentException(
                "No se pudo leer el archivo de capítulos.");
        }

        if (datos.length > MAX_ARCHIVO) {
            throw new IllegalArgumentException(
                "El archivo supera el máximo de "
                + (MAX_ARCHIVO / 1024 / 1024) + " MB.");
        }

        return leerBytes(datos);
    }

    public static List<Capitulo> leerBytes(byte[] datos) {
        Tipo tipo = detectar(datos);
        String texto;

        try {
            switch (tipo) {
                case PDF:
                    texto = textoPdf(datos);
                    break;
                case DOCX:
                    texto = textoDocx(datos);
                    break;
                default:
                    texto = textoPlano(datos);
                    break;
            }
        } catch (IOException | XMLStreamException e) {
            throw new IllegalArgumentException(
                "No se pudo leer el contenido del archivo. "
                + "Comprueba que no esté dañado.");
        }

        texto = normalizar(texto);

        if (texto.isBlank()) {
            throw new IllegalArgumentException(tipo == Tipo.PDF
                ? "El PDF no tiene texto seleccionable (¿es un escaneo?)."
                : "El archivo está vacío.");
        }

        List<Capitulo> capitulos = dividir(texto, tipo);

        if (capitulos.isEmpty()) {
            throw new IllegalArgumentException(
                "No se encontraron capítulos. Cada capítulo debe empezar "
                + "con una línea como «Capítulo 1» o «Capítulo 1: Título».");
        }

        return capitulos;
    }

    // ---- Tipo de archivo ----------------------------------------------------

    private static Tipo detectar(byte[] d) {
        if (d.length >= 5 && d[0] == '%' && d[1] == 'P'
                && d[2] == 'D' && d[3] == 'F') {
            return Tipo.PDF;
        }

        if (d.length >= 4 && d[0] == 'P' && d[1] == 'K'
                && d[2] == 3 && d[3] == 4) {
            return Tipo.DOCX;
        }

        if (d.length >= 4 && (d[0] & 0xFF) == 0xD0 && (d[1] & 0xFF) == 0xCF
                && (d[2] & 0xFF) == 0x11 && (d[3] & 0xFF) == 0xE0) {
            throw new IllegalArgumentException(
                "Los .doc antiguos no se pueden leer. "
                + "Guárdalo como .docx o como PDF.");
        }

        int limite = Math.min(d.length, 8192);
        for (int i = 0; i < limite; i++) {
            if (d[i] == 0) {
                throw new IllegalArgumentException(
                    "Formato no permitido. Sube un PDF, DOCX o TXT.");
            }
        }

        return Tipo.TXT;
    }

    // ---- Extracción de texto ------------------------------------------------

    private static String textoPlano(byte[] datos) {
        try {
            return StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(datos)).toString();
        } catch (CharacterCodingException e) {
            // Archivos guardados desde el Bloc de notas antiguo
            return new String(datos, Charset.forName("windows-1252"));
        }
    }

    private static String textoDocx(byte[] datos)
            throws IOException, XMLStreamException {

        try (ZipInputStream zip =
                     new ZipInputStream(new ByteArrayInputStream(datos))) {
            ZipEntry entrada;

            while ((entrada = zip.getNextEntry()) != null) {
                if ("word/document.xml".equals(entrada.getName())) {
                    byte[] xml = zip.readNBytes(MAX_XML + 1);

                    if (xml.length > MAX_XML) {
                        throw new IllegalArgumentException(
                            "El documento Word es demasiado grande.");
                    }

                    return textoXmlWord(xml);
                }
            }
        }

        throw new IllegalArgumentException(
            "El archivo no es un documento Word (.docx) válido.");
    }

    private static String textoXmlWord(byte[] xml)
            throws XMLStreamException {

        XMLInputFactory fabrica = XMLInputFactory.newFactory();
        fabrica.setProperty(XMLInputFactory.SUPPORT_DTD, false);
        fabrica.setProperty(
            XMLInputFactory.IS_SUPPORTING_EXTERNAL_ENTITIES, false);

        XMLStreamReader lector =
                fabrica.createXMLStreamReader(new ByteArrayInputStream(xml));
        StringBuilder sb = new StringBuilder();

        try {
            while (lector.hasNext()) {
                int evento = lector.next();

                if (evento != XMLStreamConstants.START_ELEMENT
                        && evento != XMLStreamConstants.END_ELEMENT) {
                    continue;
                }

                if (!NS_WORD.equals(lector.getNamespaceURI())) {
                    continue;
                }

                String nombre = lector.getLocalName();

                if (evento == XMLStreamConstants.START_ELEMENT) {
                    switch (nombre) {
                        case "t":
                            sb.append(lector.getElementText());
                            break;
                        case "tab":
                            sb.append('\t');
                            break;
                        case "br":
                        case "cr":
                            sb.append('\n');
                            break;
                        default:
                            break;
                    }
                } else if ("p".equals(nombre)) {
                    sb.append('\n');
                }
            }
        } finally {
            lector.close();
        }

        return sb.toString();
    }

    private static String textoPdf(byte[] datos) throws IOException {
        try (PDDocument doc = Loader.loadPDF(datos)) {
            int paginas = doc.getNumberOfPages();

            if (paginas > MAX_PAGINAS_PDF) {
                throw new IllegalArgumentException(
                    "El PDF tiene demasiadas páginas (máximo "
                    + MAX_PAGINAS_PDF + ").");
            }

            PDFTextStripper extractor = new PDFTextStripper();
            List<List<String>> lineasPorPagina = new ArrayList<>();

            for (int p = 1; p <= paginas; p++) {
                extractor.setStartPage(p);
                extractor.setEndPage(p);
                String texto = normalizar(extractor.getText(doc));
                lineasPorPagina.add(
                    new ArrayList<>(Arrays.asList(texto.split("\n", -1))));
            }

            quitarEncabezadosYPies(lineasPorPagina);

            StringBuilder sb = new StringBuilder();
            for (List<String> lineas : lineasPorPagina) {
                for (String linea : lineas) {
                    sb.append(linea).append('\n');
                }
            }
            return sb.toString();

        } catch (InvalidPasswordException e) {
            throw new IllegalArgumentException(
                "El PDF está protegido con contraseña.");
        }
    }

    /**
     * Quita la primera y la última línea de cada página cuando se repiten en
     * la mayoría (título del libro, número de página...). Los números se
     * ignoran al comparar, así "Página 3" y "Página 4" cuentan como iguales.
     */
    private static void quitarEncabezadosYPies(List<List<String>> paginas) {
        int total = paginas.size();
        if (total < 6) {
            return;
        }

        int umbral = Math.max(3, (int) Math.ceil(total * 0.5));
        Map<String, Integer> conteo = new HashMap<>();

        for (List<String> lineas : paginas) {
            String primera = clave(lineas, true);
            String ultima = clave(lineas, false);
            if (primera != null) {
                conteo.merge(primera, 1, Integer::sum);
            }
            if (ultima != null && !ultima.equals(primera)) {
                conteo.merge(ultima, 1, Integer::sum);
            }
        }

        for (List<String> lineas : paginas) {
            borrarSiRepetida(lineas, true, conteo, umbral);
            borrarSiRepetida(lineas, false, conteo, umbral);
        }
    }

    private static int indiceNoVacio(List<String> lineas, boolean desdeInicio) {
        if (desdeInicio) {
            for (int i = 0; i < lineas.size(); i++) {
                if (!lineas.get(i).isBlank()) return i;
            }
        } else {
            for (int i = lineas.size() - 1; i >= 0; i--) {
                if (!lineas.get(i).isBlank()) return i;
            }
        }
        return -1;
    }

    private static String clave(List<String> lineas, boolean desdeInicio) {
        int i = indiceNoVacio(lineas, desdeInicio);
        if (i < 0) return null;
        String linea = lineas.get(i).strip();
        if (linea.length() > 80) return null;
        return linea.replaceAll("\\d+", "#");
    }

    private static void borrarSiRepetida(List<String> lineas,
            boolean desdeInicio, Map<String, Integer> conteo, int umbral) {
        String k = clave(lineas, desdeInicio);
        if (k != null && conteo.getOrDefault(k, 0) >= umbral) {
            lineas.remove(indiceNoVacio(lineas, desdeInicio));
        }
    }

    /** Quita caracteres de control (PostgreSQL no admite NUL) y unifica saltos. */
    private static String normalizar(String texto) {
        String t = texto.replace("\r\n", "\n").replace('\r', '\n')
                .replace('\f', '\n').replace('\u00A0', ' ')
                .replace("\u00AD", "");

        if (!t.isEmpty() && t.charAt(0) == '\uFEFF') {
            t = t.substring(1);
        }

        StringBuilder sb = new StringBuilder(t.length());
        for (int i = 0; i < t.length(); i++) {
            char c = t.charAt(i);
            if (c == '\n' || c == '\t' || !Character.isISOControl(c)) {
                sb.append(c);
            }
        }
        return sb.toString();
    }

    // ---- División en capítulos ----------------------------------------------

    private static List<Capitulo> dividir(String texto, Tipo tipo) {
        String[] lineas = texto.split("\n", -1);
        List<Capitulo> capitulos = new ArrayList<>();

        String titulo = null;
        StringBuilder cuerpo = new StringBuilder();

        for (int i = 0; i < lineas.length; i++) {
            String linea = lineas[i].strip();
            Matcher m = linea.length() <= MAX_LINEA_ENCABEZADO
                    && !INDICE.matcher(linea).find()
                    ? ENCABEZADO.matcher(linea) : null;

            if (m == null || !m.matches()) {
                if (titulo != null) {
                    cuerpo.append(lineas[i]).append('\n');
                }
                continue;
            }

            agregar(capitulos, titulo, cuerpo.toString(), tipo);
            cuerpo.setLength(0);

            String etiqueta = "Capítulo " + mayusculaInicial(m.group(1).strip());
            String resto = limpiarTitulo(m.group(2));

            if (resto.isEmpty()) {
                int j = i + 1;
                while (j < lineas.length && lineas[j].isBlank()) {
                    j++;
                }
                if (j < lineas.length && pareceTitulo(lineas[j].strip())) {
                    resto = limpiarTitulo(lineas[j]);
                    i = j;
                }
            }

            titulo = recortar(resto.isEmpty() ? etiqueta
                    : etiqueta + ": " + resto);
        }

        agregar(capitulos, titulo, cuerpo.toString(), tipo);
        return capitulos;
    }

    private static void agregar(List<Capitulo> capitulos, String titulo,
            String cuerpo, Tipo tipo) {

        if (titulo == null) {
            return;
        }

        String contenido = formatear(cuerpo, tipo);

        // Un encabezado sin texto (p. ej. una línea del índice) se ignora
        if (contenido.isBlank()) {
            return;
        }

        if (capitulos.size() >= MAX_CAPITULOS) {
            throw new IllegalArgumentException(
                "El archivo tiene más de " + MAX_CAPITULOS + " capítulos.");
        }

        Capitulo c = new Capitulo();
        c.setTitulo(titulo);
        c.setContenido(contenido);
        capitulos.add(c);
    }

    private static boolean pareceTitulo(String linea) {
        if (linea.isEmpty() || linea.length() > 80) {
            return false;
        }
        if (ENCABEZADO.matcher(linea).matches()) {
            return false;
        }
        char primera = linea.charAt(0);
        if (primera == '—' || primera == '–' || primera == '―') {
            return false;
        }
        char ultima = linea.charAt(linea.length() - 1);
        if (ultima == '.' || ultima == ',' || ultima == ';') {
            return false;
        }
        return linea.split("\\s+").length <= 12;
    }

    /** Quita separadores iniciales y puntos guía + número de página del final. */
    private static String limpiarTitulo(String t) {
        String s = t == null ? "" : t.strip();
        s = s.replaceFirst("[\\s.·…]{3,}\\d*$", "");
        s = s.replaceFirst("^[.:)\\-–—\\s]+", "");
        return s.strip();
    }

    private static String mayusculaInicial(String s) {
        return s.isEmpty() ? s
                : s.substring(0, 1).toUpperCase() + s.substring(1);
    }

    private static String recortar(String titulo) {
        return titulo.length() <= MAX_TITULO
                ? titulo : titulo.substring(0, MAX_TITULO).strip();
    }

    // ---- Formato del contenido ----------------------------------------------

    private static String formatear(String cuerpo, Tipo tipo) {
        switch (tipo) {
            case DOCX:
                return unirParrafos(Arrays.asList(cuerpo.split("\n")));
            case PDF:
                return unirParrafos(reflujoPdf(cuerpo.split("\n")));
            default:
                // TXT: se respeta lo que escribió el autor
                return cuerpo.strip().replaceAll("\\n{3,}", "\n\n");
        }
    }

    private static String unirParrafos(List<String> parrafos) {
        StringBuilder sb = new StringBuilder();
        for (String p : parrafos) {
            String t = p.strip();
            if (t.isEmpty()) continue;
            if (sb.length() > 0) sb.append("\n\n");
            sb.append(t);
        }
        return sb.toString();
    }

    /**
     * Los PDF traen un salto de línea al final de cada renglón. Se vuelven a
     * unir los renglones en párrafos: un párrafo termina en un renglón corto
     * que acaba en punto, o cuando el siguiente empieza con raya de diálogo.
     */
    private static List<String> reflujoPdf(String[] lineas) {
        List<Integer> largos = new ArrayList<>();
        for (String l : lineas) {
            if (!l.isBlank()) largos.add(l.strip().length());
        }
        if (largos.isEmpty()) {
            return new ArrayList<>();
        }
        largos.sort(Integer::compare);
        int p90 = largos.get((int) (0.9 * (largos.size() - 1)));

        List<String> parrafos = new ArrayList<>();
        StringBuilder actual = new StringBuilder();
        int largoAnterior = 0;

        for (String l : lineas) {
            String t = l.strip();

            if (t.isEmpty()) {
                if (actual.length() > 0) {
                    parrafos.add(actual.toString());
                    actual.setLength(0);
                }
                continue;
            }

            if (actual.length() > 0) {
                char ultimo = actual.charAt(actual.length() - 1);
                boolean cierraOracion = ".!?…»”\"".indexOf(ultimo) >= 0;
                boolean renglonCorto = largoAnterior < 0.75 * p90;
                char c0 = t.charAt(0);
                boolean dialogo = c0 == '—' || c0 == '–' || c0 == '―';

                if (dialogo || (cierraOracion && renglonCorto)) {
                    parrafos.add(actual.toString());
                    actual.setLength(0);
                } else if (ultimo == '-' && actual.length() > 1
                        && Character.isLetter(actual.charAt(actual.length() - 2))
                        && Character.isLowerCase(c0)) {
                    // Palabra partida con guion al final del renglón
                    actual.setLength(actual.length() - 1);
                } else {
                    actual.append(' ');
                }
            }

            actual.append(t);
            largoAnterior = t.length();
        }

        if (actual.length() > 0) {
            parrafos.add(actual.toString());
        }

        return parrafos;
    }
}