import 'package:flutter/material.dart';

/// Cantidad de elementos por página en los listados de administración.
const int kElementosPorPagina = 5;

/// Número total de páginas para [total] elementos (mínimo 1).
int totalPaginas(int total, {int porPagina = kElementosPorPagina}) {
  if (total <= 0) return 1;
  return (total + porPagina - 1) ~/ porPagina;
}

/// Ajusta [pagina] (base 0) al rango válido para [total] elementos.
int paginaValida(int pagina, int total, {int porPagina = kElementosPorPagina}) {
  final ultima = totalPaginas(total, porPagina: porPagina) - 1;
  return pagina.clamp(0, ultima);
}

/// Devuelve los elementos de [items] que corresponden a [pagina] (base 0).
List<T> paginar<T>(
  List<T> items,
  int pagina, {
  int porPagina = kElementosPorPagina,
}) {
  final p = paginaValida(pagina, items.length, porPagina: porPagina);
  final inicio = p * porPagina;
  final fin = (inicio + porPagina).clamp(0, items.length);
  return items.sublist(inicio, fin);
}

/// Barra de paginación: "Mostrando 1–5 de 12" + botones anterior/siguiente
/// y números de página.
class Paginador extends StatelessWidget {
  const Paginador({
    super.key,
    required this.pagina,
    required this.total,
    required this.onCambiar,
    this.porPagina = kElementosPorPagina,
    this.color = const Color(0xFF1B5A3F),
    this.compacto = false,
  });

  /// Página actual (base 0).
  final int pagina;

  /// Total de elementos (ya filtrados).
  final int total;

  final int porPagina;
  final ValueChanged<int> onCambiar;
  final Color color;

  /// En móvil oculta los números de página intermedios.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    if (total <= porPagina) return const SizedBox.shrink();

    final paginas = totalPaginas(total, porPagina: porPagina);
    final actual = paginaValida(pagina, total, porPagina: porPagina);
    final desde = actual * porPagina + 1;
    final hasta = ((actual + 1) * porPagina).clamp(0, total);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        spacing: 12,
        children: [
          Text(
            'Mostrando $desde–$hasta de $total',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _boton(
                icono: Icons.chevron_left,
                tooltip: 'Anterior',
                onTap: actual > 0 ? () => onCambiar(actual - 1) : null,
              ),
              if (compacto)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '${actual + 1} / $paginas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                )
              else
                for (final p in _paginasVisibles(actual, paginas))
                  p == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '…',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : _numero(p, p == actual),
              _boton(
                icono: Icons.chevron_right,
                tooltip: 'Siguiente',
                onTap: actual < paginas - 1
                    ? () => onCambiar(actual + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Números de página a mostrar; `null` representa un salto ("…").
  List<int?> _paginasVisibles(int actual, int paginas) {
    if (paginas <= 7) return List<int?>.generate(paginas, (i) => i);
    final resultado = <int?>[0];
    final inicio = (actual - 1).clamp(1, paginas - 2);
    final fin = (actual + 1).clamp(1, paginas - 2);
    if (inicio > 1) resultado.add(null);
    for (var i = inicio; i <= fin; i++) {
      resultado.add(i);
    }
    if (fin < paginas - 2) resultado.add(null);
    resultado.add(paginas - 1);
    return resultado;
  }

  Widget _boton({
    required IconData icono,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icono),
      color: color,
      disabledColor: Colors.grey.shade300,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _numero(int p, bool seleccionado) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: seleccionado ? null : () => onCambiar(p),
        child: Container(
          constraints: const BoxConstraints(minWidth: 34),
          height: 34,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: seleccionado ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: seleccionado ? color : Colors.grey.shade300,
            ),
          ),
          child: Text(
            '${p + 1}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: seleccionado ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
