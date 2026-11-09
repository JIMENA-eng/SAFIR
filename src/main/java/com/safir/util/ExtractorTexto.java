package com.safir.util;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.encryption.InvalidPasswordException;
import org.apache.pdfbox.text.PDFTextStripper;

import org.apache.poi.EncryptedDocumentException;
import org.apache.poi.hwpf.HWPFDocument;
import org.apache.poi.hwpf.extractor.WordExtractor;
import org.apache.poi.xwpf.usermodel.IBodyElement;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.apache.poi.xwpf.usermodel.XWPFTable;
import org.apache.poi.xwpf.usermodel.XWPFTableCell;
import org.apache.poi.xwpf.usermodel.XWPFTableRow;

/**
 * Saca el texto plano de un PDF (PDFBox), un DOCX (Apache POI, XWPF) o un DOC
 * antiguo (Apache POI, HWPF). Cada método devuelve líneas separadas por '\n';
 * la limpieza y el corte en capítulos se hacen después.
 *
 * Dependencias Maven: org.apache.pdfbox:pdfbox (3.x),
 * org.apache.poi:poi-ooxml y org.apache.poi:poi-scratchpad (misma versión;
 * poi-scratchpad es el que trae HWPF).
 */
final class ExtractorTexto {

    private static final int MAX_PAGINAS_PDF = 3000;

    private ExtractorTexto() {}

    // ---- PDF ----------------------------------------------------------------

    static String pdf(byte[] datos) {
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
                String texto = SeparadorCapitulos.normalizar(extractor.getText(doc));
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
        } catch (IOException e) {
            throw new IllegalArgumentException(
                "No se pudo leer el PDF. Comprueba que no esté dañado.");
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

    // ---- DOCX (POI XWPF) ----------------------------------------------------

    static String docx(byte[] datos) {
        try (XWPFDocument doc = new XWPFDocument(new ByteArrayInputStream(datos))) {
            StringBuilder sb = new StringBuilder();

            // Se recorre el cuerpo en orden: párrafos y tablas tal como aparecen.
            for (IBodyElement e : doc.getBodyElements()) {
                if (e instanceof XWPFParagraph) {
                    sb.append(((XWPFParagraph) e).getText()).append('\n');
                } else if (e instanceof XWPFTable) {
                    agregarTabla(sb, (XWPFTable) e);
                }
            }
            return sb.toString();

        } catch (EncryptedDocumentException e) {
            throw new IllegalArgumentException(
                "El documento Word está protegido con contraseña.");
        } catch (IOException | RuntimeException e) {
            // POI lanza distintas RuntimeException (POIXMLException,
            // NotOfficeXmlFileException, zip dañado...) si no es un .docx real.
            throw new IllegalArgumentException(
                "El archivo no es un documento Word (.docx) válido.");
        }
    }

    private static void agregarTabla(StringBuilder sb, XWPFTable tabla) {
        for (XWPFTableRow fila : tabla.getRows()) {
            for (XWPFTableCell celda : fila.getTableCells()) {
                String t = celda.getText();
                if (t != null && !t.isBlank()) {
                    sb.append(t).append('\n');
                }
            }
        }
    }

    // ---- DOC antiguo (POI HWPF) ---------------------------------------------

    static String doc(byte[] datos) {
        try (HWPFDocument doc = new HWPFDocument(new ByteArrayInputStream(datos));
             WordExtractor extractor = new WordExtractor(doc)) {

            StringBuilder sb = new StringBuilder();
            for (String parrafo : extractor.getParagraphText()) {
                sb.append(parrafo).append('\n');
            }
            return sb.toString();

        } catch (EncryptedDocumentException e) {
            throw new IllegalArgumentException(
                "El documento Word está protegido con contraseña.");
        } catch (IOException | RuntimeException e) {
            // El contenedor OLE2 también lo usan .xls, .ppt y los .docx cifrados:
            // HWPF los rechaza.
            throw new IllegalArgumentException(
                "El archivo no es un documento Word (.doc) válido "
                + "(o está protegido con contraseña).");
        }
    }
}