export function renderNominalsView(caseData) {
  const cards = caseData.npcs
    .map(
      (nominal) => `<div class="record"><b>${nominal.name}</b> — ${nominal.role}<br/><span class="small">Last known: ${caseData.locations.find((location) => location.id === nominal.knownLocation)?.name || 'HQ'}</span></div>`
    )
    .join('');
  return `<h2>Nominals / Database</h2><div class="panel">${cards}</div>`;
}
