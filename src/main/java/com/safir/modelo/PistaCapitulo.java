package com.safir.modelo;

/**
 * Música que acompaña a un capítulo (tablas pista_musica + capitulo_pista).
 * Puede ser un video de YouTube o un archivo de audio subido por el autor.
 */
public class PistaCapitulo {

    public static final String YOUTUBE = "youtube";
    public static final String ARCHIVO = "archivo";

    private long pistaId;
    private String tipo;          // "youtube" o "archivo"
    private String titulo;
    private String url;           // enlace de YouTube o /media/audio/...
    private String archivoRuta;   // solo archivos: "audio/12-uuid.mp3"
    private String youtubeId;     // solo YouTube: id de 11 caracteres
    private boolean enBucle;
    private Integer tamanoBytes;  // solo al guardar un archivo nuevo

    public Integer getTamanoBytes() {
        return tamanoBytes;
    }

    public void setTamanoBytes(Integer tamanoBytes) {
        this.tamanoBytes = tamanoBytes;
    }

    public long getPistaId() {
        return pistaId;
    }

    public void setPistaId(long pistaId) {
        this.pistaId = pistaId;
    }

    public String getTipo() {
        return tipo;
    }

    public void setTipo(String tipo) {
        this.tipo = tipo;
    }

    public boolean isYoutube() {
        return YOUTUBE.equals(tipo);
    }

    public boolean isArchivo() {
        return ARCHIVO.equals(tipo);
    }

    public String getTitulo() {
        return titulo;
    }

    public void setTitulo(String titulo) {
        this.titulo = titulo;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getArchivoRuta() {
        return archivoRuta;
    }

    public void setArchivoRuta(String archivoRuta) {
        this.archivoRuta = archivoRuta;
    }

    public String getYoutubeId() {
        return youtubeId;
    }

    public void setYoutubeId(String youtubeId) {
        this.youtubeId = youtubeId;
    }

    public boolean isEnBucle() {
        return enBucle;
    }

    public void setEnBucle(boolean enBucle) {
        this.enBucle = enBucle;
    }
}