/* SAFIR · Mi cuenta (enlazado desde WEB-INF/vistas/cuenta.jsp) */
(function () {
  // Enlaces de módulos que aún no existen (mensajes, listas): no navegan.
  Array.prototype.forEach.call(document.querySelectorAll('.cuenta-acceso[data-pendiente]'), function (a) {
    a.addEventListener('click', function (e) { e.preventDefault(); });
  });
})();
