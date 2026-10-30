package com.safir.modelo;

import java.time.LocalDateTime;

public class Capitulo {

    private long id;
    private long obraId;
    private Integer numero;
    private String titulo;
    private String contenido;
    private Integer palabras;
    private String estado;
    private LocalDateTime publicadoEn;

    public Capitulo() {
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getObraId() {
        return obraId;
    }

    public void setObraId(long obraId) {
        this.obraId = obraId;
    }

    public Integer getNumero() {
        return numero;
    }

    public void setNumero(Integer numero) {
        this.numero = numero;
    }

    public String getTitulo() {
        return titulo;
    }

    public void setTitulo(String titulo) {
        this.titulo = titulo;
    }

    public String getContenido() {
        return contenido;
    }

    public void setContenido(String contenido) {
        this.contenido = contenido;
    }

    public Integer getPalabras() {
        return palabras;
    }

    public void setPalabras(Integer palabras) {
        this.palabras = palabras;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public LocalDateTime getPublicadoEn() {
        return publicadoEn;
    }

    public void setPublicadoEn(LocalDateTime publicadoEn) {
        this.publicadoEn = publicadoEn;
    }
}
