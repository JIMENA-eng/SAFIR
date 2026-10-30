package com.safir.modelo;

import java.math.BigDecimal;

public class Obra {

    private long id;
    private String titulo;
    private String descripcion;
    private String portadaRuta;
    private String genero;
    private String autor;
    private String clasificacion;
    private String avance;
    private BigDecimal promedio;
    private long totalValoraciones;
    private long totalLecturas;
    private long totalSeguidores;
    private long capitulosPublicados;
    private String etiquetas;

    public Obra() {
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public String getTitulo() {
        return titulo;
    }

    public void setTitulo(String titulo) {
        this.titulo = titulo;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public String getPortadaRuta() {
        return portadaRuta;
    }

    public void setPortadaRuta(String portadaRuta) {
        this.portadaRuta = portadaRuta;
    }

    public String getGenero() {
        return genero;
    }

    public void setGenero(String genero) {
        this.genero = genero;
    }

    public String getAutor() {
        return autor;
    }

    public void setAutor(String autor) {
        this.autor = autor;
    }

    public String getClasificacion() {
        return clasificacion;
    }

    public void setClasificacion(String clasificacion) {
        this.clasificacion = clasificacion;
    }

    public String getAvance() {
        return avance;
    }

    public void setAvance(String avance) {
        this.avance = avance;
    }

    public BigDecimal getPromedio() {
        return promedio;
    }

    public void setPromedio(BigDecimal promedio) {
        this.promedio = promedio;
    }

    public long getTotalValoraciones() {
        return totalValoraciones;
    }

    public void setTotalValoraciones(long totalValoraciones) {
        this.totalValoraciones = totalValoraciones;
    }

    public long getTotalLecturas() {
        return totalLecturas;
    }

    public void setTotalLecturas(long totalLecturas) {
        this.totalLecturas = totalLecturas;
    }

    public long getTotalSeguidores() {
        return totalSeguidores;
    }

    public void setTotalSeguidores(long totalSeguidores) {
        this.totalSeguidores = totalSeguidores;
    }

    public long getCapitulosPublicados() {
        return capitulosPublicados;
    }

    public void setCapitulosPublicados(long capitulosPublicados) {
        this.capitulosPublicados = capitulosPublicados;
    }

    public String getEtiquetas() {
        return etiquetas;
    }

    public void setEtiquetas(String etiquetas) {
        this.etiquetas = etiquetas;
    }
    private String estadoBiblioteca;
private boolean favorita;

public String getEstadoBiblioteca() {
    return estadoBiblioteca;
}

public void setEstadoBiblioteca(String estadoBiblioteca) {
    this.estadoBiblioteca = estadoBiblioteca;
}

public boolean isFavorita() {
    return favorita;
}

public void setFavorita(boolean favorita) {
    this.favorita = favorita;
}
}
