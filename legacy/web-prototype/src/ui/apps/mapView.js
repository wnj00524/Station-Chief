export function renderMapView(caseData, state) {
  const locations = caseData.locations
    .map((location) => {
      const flagged = state.intercepts.some((intercept) => intercept.locationId === location.id);
      return `<div class="record"><b>${location.name}</b> (${location.coords.join(', ')}) ${flagged ? '• <span class="warn">SIGINT activity</span>' : ''}</div>`;
    })
    .join('');
  return `<h2>Map</h2><div class="panel">${locations}</div>`;
}
