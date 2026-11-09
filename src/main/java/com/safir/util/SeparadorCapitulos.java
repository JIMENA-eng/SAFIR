package com.safir.util;

import com.safir.modelo.Capitulo;
import com.safir.util.ImportadorCapitulos.Tipo;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Corta el texto de un libro en capítulos. No depende de ninguna librería
 * externa, así que se puede probar sola.
 *
 * Regla de corte, en este orden (se usa la primera que encuentre algo):
 *   1. Líneas «Capítulo 1», «CAPÍTULO 2: Título», «Capitulo III», «Capítulo tres»,
 *      «Cap. 4», «Chapter 5».
 *   2. Líneas «Parte 1», «Parte II: Título», «Parte tres».
 *   3. Líneas que son solo un número romano («I», «II.», «IV)») y siguen la
 *      secuencia 1, 2, 3... (las sueltas que rompen la secuencia se ignoran;
 *      hacen falta al menos dos).
 *   4. Si no hay ninguna, todo el texto queda como un único capítulo.
 *
 * Lo que haya antes del primer encabezado (portada, índice, prólogo) se
 * descarta cuando se corta por encabezados; en el caso 4 no se descarta nada.
 */
final class SeparadorCapitulos {

    static final int MAX_CAPITULOS = 500;

    private static final int MAX_TITULO = 150;
    private static final int MAX_LINEA_ENCABEZADO = 120;
    private static final int MAX_RESTO_PARTE = 80;

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

    private static final String RESTO = "(?![\\p{L}\\d])\\s*[.:)\\-–—]*\\s*(.*)$";
    private static final int FLAGS =
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE;

    private static final Pattern CAPITULO = Pattern.compile(
            "^(?:cap[ií]tulo\\s+|cap\\.\\s*|chapter\\s+)(" + NUMERO + ")" + RESTO,
            FLAGS);

    private static final Pattern PARTE = Pattern.compile(
            "^parte\\s+(" + NUMERO + ")" + RESTO, FLAGS);

    /** Línea que es solo un número romano: "IV", "IV.", "IV)". */
    private static final Pattern ROMANO_SUELTO = Pattern.compile(
            "^((?-i:[IVXLCDM]{1,8}))\\s*[.)]?\\s*()$");

    /** Línea de índice: "Capítulo 1 ........ 5" (puntos guía + página). */
    private static final Pattern INDICE =
            Pattern.compile("[.·…]{3,}\\s*\\d+\\s*$");

    private SeparadorCapitulos() {}

    /** Resultado de dividir: los capítulos y datos para mostrar al autor. */
    static final class Division {
        final List<Capitulo> capitulos;
        final boolean capituloUnico;
        final int palabrasDescartadas;

        Division(List<Capitulo> capitulos, boolean capituloUnico,
                 int palabrasDescartadas) {
            this.capitulos = capitulos;
            this.capituloUnico = capituloUnico;
            this.palabrasDescartadas = palabrasDescartadas;
        }
    }

    // ---- API ------------------------------------------------------------------

    static Division dividir(String texto, Tipo tipo) {
        String[] lineas = texto.split("\n", -1);

        Division d = dividirPor(lineas, tipo, CAPITULO, "Capítulo", null, false);

        if (d == null) {
            d = dividirPor(lineas, tipo, PARTE, "Parte", null, true);
        }

        if (d == null) {
            Set<Integer> romanos = romanosEnSecuencia(lineas);
            if (romanos.size() >= 2) {
                d = dividirPor(lineas, tipo, ROMANO_SUELTO, "Capítulo",
                        romanos, false);
            }
        }

        if (d == null) {
            Capitulo c = new Capitulo();
            c.setTitulo("Capítulo 1");
            c.setContenido(formatear(texto, tipo));
            d = new Division(new ArrayList<>(List.of(c)), true, 0);
        }

        return d;
    }

    /** Quita caracteres de control (PostgreSQL no admite NUL) y unifica saltos. */
    static String normalizar(String texto) {
        String t = texto.replace("\r\n", "\n").replace('\r', '\n')
                .replace('\f', '\n').replace('\u000B', '\n')   // salto de línea manual de Word
                .replace('\u0007', '\t')                       // fin de celda en .doc
                .replace(' ', ' ')
                .replace("­", "");

        if (!t.isEmpty() && t.charAt(0) == '﻿') {
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

    // ---- División por encabezados ---------------------------------------------

    /**
     * Corta por las líneas que cumplen el patrón. Devuelve null si no sale
     * ningún capítulo con texto (para pasar a la regla siguiente).
     *
     * @param permitidas  si no es null, solo cuentan las líneas con esos índices
     * @param validarResto  exige que lo que sigue al número parezca un título
     *                      (para "Parte", que también es una palabra corriente)
     */
    private static Division dividirPor(String[] lineas, Tipo tipo,
            Pattern patron, String prefijo, Set<Integer> permitidas,
            boolean validarResto) {

        List<Capitulo> capitulos = new ArrayList<>();
        String titulo = null;
        StringBuilder cuerpo = new StringBuilder();
        StringBuilder previo = new StringBuilder();

        for (int i = 0; i < lineas.length; i++) {
            String linea = lineas[i].strip();
            Matcher m = null;

            if ((permitidas == null || permitidas.contains(i))
                    && linea.length() <= MAX_LINEA_ENCABEZADO
                    && !INDICE.matcher(linea).find()) {
                m = patron.matcher(linea);
                if (!m.matches()
                        || (validarResto && !restoValido(m.group(2)))) {
                    m = null;
                }
            }

            if (m == null) {
                if (titulo != null) {
                    cuerpo.append(lineas[i]).append('\n');
                } else {
                    previo.append(lineas[i]).append('\n');
                }
                continue;
            }

            agregar(capitulos, titulo, cuerpo.toString(), tipo);
            cuerpo.setLength(0);

            String etiqueta = prefijo + " " + mayusculaInicial(m.group(1).strip());
            String resto = limpiarTitulo(m.group(2));

            if (resto.isEmpty()) {
                int j = i + 1;
                while (j < lineas.length && lineas[j].isBlank()) {
                    j++;
                }
                if (j < lineas.length && pareceTitulo(lineas[j].strip())
                        && (permitidas == null || !permitidas.contains(j))) {
                    resto = limpiarTitulo(lineas[j]);
                    i = j;
                }
            }

            titulo = recortar(resto.isEmpty() ? etiqueta
                    : etiqueta + ": " + resto);
        }

        agregar(capitulos, titulo, cuerpo.toString(), tipo);

        if (capitulos.isEmpty()) {
            return null;
        }

        return new Division(capitulos, false, contarPalabras(previo.toString()));
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

    /** "Parte 2 de la cena fue larga." no es un encabezado; "Parte 2: El viaje" sí. */
    private static boolean restoValido(String resto) {
        String r = limpiarTitulo(resto);
        if (r.isEmpty()) {
            return true;
        }
        char ultima = r.charAt(r.length() - 1);
        return r.length() <= MAX_RESTO_PARTE
                && ultima != '.' && ultima != ',' && ultima != ';';
    }

    // ---- Números romanos sueltos ----------------------------------------------

    /**
     * Índices de las líneas "I", "II", "III"... que siguen la secuencia desde 1.
     * Una "I" o una "C" perdida en el texto no cuenta porque no continúa la
     * secuencia; así un párrafo de lista "I." no corta el libro.
     */
    private static Set<Integer> romanosEnSecuencia(String[] lineas) {
        Set<Integer> indices = new HashSet<>();
        int esperado = 1;

        for (int i = 0; i < lineas.length; i++) {
            String linea = lineas[i].strip();
            if (linea.length() > 12) {
                continue;
            }
            Matcher m = ROMANO_SUELTO.matcher(linea);
            if (m.matches() && valorRomano(m.group(1)) == esperado) {
                indices.add(i);
                esperado++;
            }
        }
        return indices;
    }

    /** Valor del número romano, o -1 si no está bien formado ("IIII", "VX"...). */
    static int valorRomano(String s) {
        if (!s.matches("M{0,3}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})")) {
            return -1;
        }
        int total = 0;
        for (int i = 0; i < s.length(); i++) {
            int v = valorLetra(s.charAt(i));
            int sig = i + 1 < s.length() ? valorLetra(s.charAt(i + 1)) : 0;
            total += v < sig ? -v : v;
        }
        return total;
    }

    private static int valorLetra(char c) {
        switch (c) {
            case 'I': return 1;
            case 'V': return 5;
            case 'X': return 10;
            case 'L': return 50;
            case 'C': return 100;
            case 'D': return 500;
            case 'M': return 1000;
            default:  return 0;
        }
    }

    // ---- Títulos --------------------------------------------------------------

    private static boolean pareceTitulo(String linea) {
        if (linea.isEmpty() || linea.length() > 80) {
            return false;
        }
        if (CAPITULO.matcher(linea).matches()
                || PARTE.matcher(linea).matches()) {
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

    private static int contarPalabras(String t) {
        return t.isBlank() ? 0 : t.trim().split("\\s+").length;
    }

    // ---- Formato del contenido ----------------------------------------------

    private static String formatear(String cuerpo, Tipo tipo) {
        switch (tipo) {
            case DOCX:
            case DOC:
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