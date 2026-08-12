/// Convertit un score de congestion (0-100) en label affiché, cohérent avec
/// les seuils utilisés côté backend (mobility/aggregation.py, conseil/views.py).
String trafficLabelFromScore(num score) {
  if (score >= 70) return 'Dense';
  if (score >= 45) return 'Modéré';
  return 'Fluide';
}
