package com.safir.config;

import java.sql.Connection;

public class PruebaConexion {

    public static void main(String[] args) {

        try (Connection conexion = ConexionBD.conectar()) {

            if (conexion != null && !conexion.isClosed()) {
                System.out.println("¡CONEXIÓN EXITOSA A POSTGRESQL!");
                System.out.println("Base de datos: "
                        + conexion.getCatalog());
            }

        } catch (Exception e) {
            System.out.println("ERROR DE CONEXIÓN:");
            e.printStackTrace();
        }
    }
}