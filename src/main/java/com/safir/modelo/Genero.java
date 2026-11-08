package com.safir.modelo;

/**
 * Categoría (género literario) de una obra.
 * totalObras = cuántas obras PUBLICADAS tiene la categoría.
 */
public class Genero {

    private int id;
    private String nombre;
    private long totalObras;

    public Genero() {
    }

    public Genero(int id, String nombre, long totalObras) {
        this.id = id;
        this.nombre = nombre;
        this.totalObras = totalObras;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public long getTotalObras() { return totalObras; }
    public void setTotalObras(long totalObras) { this.totalObras = totalObras; }

    /** Ícono decorativo para las tarjetas del catálogo. */
    public String getIcono() {
        if (nombre == null) return "✦";
        switch (nombre.trim().toLowerCase()) {
            case "fantasía":        return "🐉";
            case "romance":         return "💞";
            case "ciencia ficción": return "🚀";
            case "misterio":        return "🔍";
            case "terror":          return "👻";
            case "aventura":        return "🧭";
            case "drama":           return "🎭";
            default:                return "✦";
        }
    }
}