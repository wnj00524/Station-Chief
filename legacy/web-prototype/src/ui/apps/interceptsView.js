export function renderInterceptsView(state) {
  const rows = state.intercepts.length
    ? state.intercepts
        .map((intercept) => `<div class="record"><b>${intercept.title}</b><div>${intercept.summary}</div></div>`)
        .join('')
    : '<div class="record">No intercepts captured yet.</div>';
  return `<h2>Intercepts</h2><div class="panel">${rows}</div>`;
}
