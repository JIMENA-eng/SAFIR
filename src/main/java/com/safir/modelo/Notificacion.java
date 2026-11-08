package com.safir.modelo;

import java.time.LocalDateTime;

public class Notificacion {

    private long id;
    private String tipo;
    private String mensaje;
    private Long actorId;
    private Long obraId;
    private Long capituloId;
    private Long comentarioId;
    private LocalDateTime creadoEn;
    private LocalDateTime leidaEn;

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public String getTipo() {
        return tipo;
    }

    public void setTipo(String tipo) {
        this.tipo = tipo;
    }

    public String getMensaje() {
        return mensaje;
    }

    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }

    public Long getActorId() {
        return actorId;
    }

    public void setActorId(Long actorId) {
        this.actorId = actorId;
    }

    public Long getObraId() {
        return obraId;
    }

    public void setObraId(Long obraId) {
        this.obraId = obraId;
    }

    public Long getCapituloId() {
        return capituloId;
    }

    public void setCapituloId(Long capituloId) {
        this.capituloId = capituloId;
    }

    public Long getComentarioId() {
        return comentarioId;
    }

    public void setComentarioId(Long comentarioId) {
        this.comentarioId = comentarioId;
    }

    public LocalDateTime getCreadoEn() {
        return creadoEn;
    }

    public void setCreadoEn(LocalDateTime creadoEn) {
        this.creadoEn = creadoEn;
    }

    public LocalDateTime getLeidaEn() {
        return leidaEn;
    }

    public void setLeidaEn(LocalDateTime leidaEn) {
        this.leidaEn = leidaEn;
    }

    public boolean isLeida() {
        return leidaEn != null;
    }

    // ---------- TAREA 5 ----------

    /** "mensajes" (sistema, moderación, respuestas) o "actividad" (obras, seguidores, otros). */
    public String getCategoria() {
        return com.safir.dao.NotificacionDAO.categoriaDe(tipo);
    }

    /** Nombre legible del tipo para mostrar al usuario. */
    public String getTipoTexto() {
        return com.safir.dao.NotificacionDAO.textoTipo(tipo);
    }
}