import caseData from '../data/cases/falconMeeting.js';
import { validateCaseDefinition } from '../data/schemas/caseSchema.js';
import { CaseEngine } from '../sim/caseEngine.js';
import { wireDock } from './desktop/dock.js';
import { renderTopBar } from './desktop/topBar.js';
import { WindowManager } from './desktop/windowManager.js';
import { renderInboxView } from './apps/inboxView.js';
import { renderNominalsView } from './apps/nominalsView.js';
import { renderInterceptsView } from './apps/interceptsView.js';
import { renderMapView } from './apps/mapView.js';
import { renderStaffPanelView } from './apps/staffPanelView.js';

const workspace = document.getElementById('workspace');
const clockEl = document.getElementById('clock');
const pcEl = document.getElementById('pc');
const toasts = document.getElementById('toasts');

const schemaErrors = validateCaseDefinition(caseData);
if (schemaErrors.length) {
  throw new Error(`Case schema invalid:\n${schemaErrors.join('\n')}`);
}

const engine = new CaseEngine(caseData, { tickMs: 1300 });
const windows = new WindowManager('inbox');
let lastState = engine.getPublicState();

function toast(text) {
  const node = document.createElement('div');
  node.className = 'toast';
  node.textContent = text;
  toasts.appendChild(node);
  setTimeout(() => node.remove(), 4500);
}

function render(state = lastState) {
  lastState = state;
  renderTopBar({ clockEl, pcEl, state });

  const views = {
    inbox: renderInboxView(state),
    nominals: renderNominalsView(caseData),
    intercepts: renderInterceptsView(state),
    map: renderMapView(caseData, state),
    staff: renderStaffPanelView(caseData, state)
  };

  const currentApp = windows.getCurrentApp();
  workspace.innerHTML = views[currentApp] || views.inbox;
}

function openApp(appId) {
  windows.open(appId);
  engine.markAppVisited(appId);
  render(engine.getPublicState());
}

wireDock(document, openApp);

workspace.addEventListener('click', (event) => {
  const taskId = event.target.getAttribute('data-task');
  const decisionId = event.target.getAttribute('data-decision');

  if (taskId) {
    if (engine.scheduleTask(taskId)) toast(`Task queued: ${taskId}`);
    render(engine.getPublicState());
  }

  if (decisionId) {
    engine.decide(decisionId);
  }
});

engine.bus.on('interceptCaptured', (intercept) => {
  toast(`Intercept captured: ${intercept.title}`);
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

openApp('inbox');
engine.start();
