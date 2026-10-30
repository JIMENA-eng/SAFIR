package com.safir.modelo;

public class ObraAutor {

    private long obraId;
    private String titulo;
    private String estado;
    private String avance;
    private long capitulosPublicados;
    private long capitulosBorrador;
    private long totalLecturas;
    private double promedio;
    private long totalSeguidores;

    public long getObraId() {
        return obraId;
    }

    public void setObraId(long obraId) {
        this.obraId = obraId;
    }

    public String getTitulo() {
        return titulo;
    }

    public void setTitulo(String titulo) {
        this.titulo = titulo;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public String getAvance() {
        return avance;
    }

    public void setAvance(String avance) {
        this.avance = avance;
    }

    public long getCapitulosPublicados() {
        return capitulosPublicados;
    }

    public void setCapitulosPublicados(long capitulosPublicados) {
        this.capitulosPublicados = capitulosPublicados;
    }

    public long getCapitulosBorrador() {
        return capitulosBorrador;
    }

    public void setCapitulosBorrador(long capitulosBorrador) {
        this.capitulosBorrador = capitulosBorrador;
    }

    public long getTotalLecturas() {
        return totalLecturas;
    }

    public void setTotalLecturas(long totalLecturas) {
        this.totalLecturas = totalLecturas;
    }

    public double getPromedio() {
        return promedio;
    }

    public void setPromedio(double promedio) {
        this.promedio = promedio;
    }

    public long getTotalSeguidores() {
        return totalSeguidores;
    }

    public void setTotalSeguidores(long totalSeguidores) {
        this.totalSeguidores = totalSeguidores;
    }
}