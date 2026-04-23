import caseData from '../data/cases/falconMeeting.js';
import { CaseEngine } from '../sim/caseEngine.js';

const workspace = document.getElementById('workspace');
const clockEl = document.getElementById('clock');
const pcEl = document.getElementById('pc');
const toasts = document.getElementById('toasts');

const engine = new CaseEngine(caseData, { tickMs: 1300 });
let currentApp = 'inbox';
let lastState = engine.getPublicState();

function toast(text) {
  const node = document.createElement('div');
  node.className = 'toast';
  node.textContent = text;
  toasts.appendChild(node);
  setTimeout(() => node.remove(), 4500);
}

function renderInbox(state) {
  const threads = state.inbox
    .map(
      (thread) => `
      <div class="panel">
        <strong>${thread.subject}</strong>
        ${thread.messages
          .map(
            (m) => `<div class="thread-msg"><div><b>${m.from}</b> @ ${String(m.atMinute).padStart(2, '0')}m</div><div>${m.body}</div></div>`
          )
          .join('')}
      </div>`
    )
    .join('');

  return `
    <h2>Inbox</h2>
    <p class="small">Read incoming HUMINT/SIGINT/staff reports. No hints are auto-generated.</p>
    ${threads}
  `;
}

function renderNominals() {
  const cards = caseData.npcs
    .map(
      (n) => `<div class="record"><b>${n.name}</b> — ${n.role}<br/><span class="small">Last known: ${caseData.locations.find((l) => l.id === n.knownLocation)?.name || 'HQ'}</span></div>`
    )
    .join('');
  return `<h2>Nominals / Database</h2><div class="panel">${cards}</div>`;
}

function renderIntercepts(state) {
  const rows = state.intercepts.length
    ? state.intercepts
        .map((i) => `<div class="record"><b>${i.title}</b><div>${i.summary}</div></div>`)
        .join('')
    : '<div class="record">No intercepts captured yet.</div>';
  return `<h2>Intercepts</h2><div class="panel">${rows}</div>`;
}

function renderMap(state) {
  const locations = caseData.locations
    .map((loc) => {
      const flagged = state.intercepts.some((i) => i.locationId === loc.id);
      return `<div class="record"><b>${loc.name}</b> (${loc.coords.join(', ')}) ${flagged ? '• <span class="warn">SIGINT activity</span>' : ''}</div>`;
    })
    .join('');
  return `<h2>Map</h2><div class="panel">${locations}</div>`;
}

function renderStaff(state) {
  const templates = caseData.staffTemplates
    .map((tpl) => {
      const busy = state.pendingTasks.some((t) => t.id === tpl.id);
      const done = state.completedTasks.some((t) => t.id === tpl.id);
      return `<div class="record"><button data-task="${tpl.id}" ${busy || done ? 'disabled' : ''}>${tpl.label}</button> <span class="small">ETA ${tpl.durationMinutes}m</span></div>`;
    })
    .join('');

  const decisions = caseData.decisions
    .map(
      (d) => `<button data-decision="${d.id}" ${state.chosenDecisionId || !state.appCountMet ? 'disabled' : ''}>${d.label}</button>`
    )
    .join('');

  const outcome = state.outcome
    ? `<div class="panel"><h3>Home Office Debrief</h3><div class="${state.outcome === 'success' ? 'good' : state.outcome === 'failure' ? 'bad' : 'warn'}">${state.outcome.toUpperCase()}</div><p>${state.homeOfficeDebrief}</p></div>`
    : '';

  return `
    <h2>Staff Tasking Panel</h2>
    <div class="panel">${templates}</div>
    <div class="panel actions">
      <h3>Judgment Call (time remaining: ${state.timeRemaining}m)</h3>
      <p class="small">Decision unlock requires meaningful use of at least 3 apps. (${state.visitedApps.size}/3)</p>
      ${decisions}
    </div>
    ${outcome}
  `;
}

function render(state = lastState) {
  lastState = state;
  clockEl.textContent = state.displayTime;
  pcEl.textContent = `Political Capital: ${state.politicalCapital}`;

  const views = {
    inbox: renderInbox(state),
    nominals: renderNominals(state),
    intercepts: renderIntercepts(state),
    map: renderMap(state),
    staff: renderStaff(state)
  };
  workspace.innerHTML = views[currentApp] || views.inbox;
}

function setApp(app) {
  currentApp = app;
  engine.markAppVisited(app);
  render(engine.getPublicState());
}

document.querySelectorAll('.dock button').forEach((btn) => {
  btn.addEventListener('click', () => setApp(btn.dataset.app));
});

workspace.addEventListener('click', (evt) => {
  const taskId = evt.target.getAttribute('data-task');
  const decisionId = evt.target.getAttribute('data-decision');
  if (taskId) {
    if (engine.scheduleTask(taskId)) toast(`Task queued: ${taskId}`);
    render(engine.getPublicState());
  }
  if (decisionId) {
    engine.decide(decisionId);
  }
});

engine.bus.on('interceptCaptured', (it) => {
  toast(`Intercept captured: ${it.title}`);
  render(engine.getPublicState());
});
engine.bus.on('staffTaskCompleted', ({ message }) => {
  toast(`Staff complete: ${message}`);
  render(engine.getPublicState());
});
engine.bus.on('deadline', () => {
  toast('Decision window closing.');
  render(engine.getPublicState());
});
engine.bus.on('tick', render);
engine.bus.on('decisionResolved', (state) => {
  toast(`Decision resolved: ${state.outcome}`);
  render(state);
});

setApp('inbox');
engine.start();
