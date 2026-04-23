export function renderStaffPanelView(caseData, state) {
  const taskRows = caseData.staffTemplates
    .map((template) => {
      const busy = state.pendingTasks.some((task) => task.id === template.id);
      const done = state.completedTasks.some((task) => task.id === template.id);
      return `<div class="record"><button data-task="${template.id}" ${busy || done ? 'disabled' : ''}>${template.label}</button> <span class="small">ETA ${template.durationMinutes}m</span></div>`;
    })
    .join('');

  const decisions = caseData.decisions
    .map(
      (decision) => `<button data-decision="${decision.id}" ${state.chosenDecisionId || !state.appCountMet ? 'disabled' : ''}>${decision.label}</button>`
    )
    .join('');

  const outcome = state.outcome
    ? `<div class="panel"><h3>Home Office Debrief</h3><div class="${state.outcome === 'success' ? 'good' : state.outcome === 'failure' ? 'bad' : 'warn'}">${state.outcome.toUpperCase()}</div><p>${state.homeOfficeDebrief}</p></div>`
    : '';

  return `
    <h2>Staff Tasking Panel</h2>
    <div class="panel">${taskRows}</div>
    <div class="panel actions">
      <h3>Judgment Call (time remaining: ${state.timeRemaining}m)</h3>
      <p class="small">Decision unlock requires meaningful use of at least 3 apps. (${state.visitedApps.size}/3)</p>
      ${decisions}
    </div>
    ${outcome}
  `;
}
