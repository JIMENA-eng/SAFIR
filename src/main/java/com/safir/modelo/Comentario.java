package com.safir.modelo;

import java.time.LocalDateTime;

public class Comentario {

    private long id;
    private long capituloId;
    private long usuarioId;
    private Long padreId;
    private String autor;
    private String texto;
    private String estado;
    private LocalDateTime creadoEn;
    private long meGusta;
    private long noMeGusta;

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getCapituloId() {
        return capituloId;
    }

    public void setCapituloId(long capituloId) {
        this.capituloId = capituloId;
    }

    public long getUsuarioId() {
        return usuarioId;
    }

    public void setUsuarioId(long usuarioId) {
        this.usuarioId = usuarioId;
    }

    public Long getPadreId() {
        return padreId;
    }

    public void setPadreId(Long padreId) {
        this.padreId = padreId;
    }

    public String getAutor() {
        return autor;
    }

    public void setAutor(String autor) {
        this.autor = autor;
    }

    public String getTexto() {
        return texto;
    }

    public void setTexto(String texto) {
        this.texto = texto;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public LocalDateTime getCreadoEn() {
        return creadoEn;
    }

    public void setCreadoEn(LocalDateTime creadoEn) {
        this.creadoEn = creadoEn;
    }

    public long getMeGusta() {
        return meGusta;
    }

    public void setMeGusta(long meGusta) {
        this.meGusta = meGusta;
    }

    public long getNoMeGusta() {
        return noMeGusta;
    }

    public void setNoMeGusta(long noMeGusta) {
        this.noMeGusta = noMeGusta;
    }
}