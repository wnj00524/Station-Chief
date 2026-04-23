import { EventBus } from './eventBus.js';
import { SimClock } from './clock.js';

export class CaseEngine {
  constructor(caseData, options = {}) {
    this.caseData = caseData;
    this.bus = new EventBus();
    this.baseHour = Number(caseData.startTime.split(':')[0]);
    this.clock = new SimClock(this.baseHour * 60, options.tickMs || 1000);
    this.state = {
      minute: 0,
      politicalCapital: caseData.startingPoliticalCapital,
      inbox: structuredClone(caseData.inboxThreads),
      intercepts: [],
      completedTasks: [],
      pendingTasks: [],
      visitedApps: new Set(),
      chosenDecisionId: null,
      outcome: null,
      homeOfficeDebrief: null,
      mustUseAppsCount: 3
    };
    this.scheduledEvents = [];
    this._seedEvents();
  }

  _seedEvents() {
    this.caseData.intercepts.forEach((intercept) => {
      this.scheduledEvents.push({
        atMinute: intercept.availableAtMinute,
        type: 'intercept',
        payload: intercept
      });
    });

    this.scheduledEvents.push({
      atMinute: this.caseData.decisionDeadlineMinutes,
      type: 'deadline',
      payload: { reason: 'Decision window expired' }
    });
  }

  markAppVisited(appId) {
    this.state.visitedApps.add(appId);
  }

  start() {
    this.bus.emit('state', this.getPublicState());
    this.clock.start(() => {
      this.state.minute += 1;
      this._runScheduledEvents();
      this._runTaskCompletions();
      this.bus.emit('tick', this.getPublicState());
    });
  }

  stop() {
    this.clock.stop();
  }

  scheduleTask(taskId) {
    const template = this.caseData.staffTemplates.find((t) => t.id === taskId);
    if (!template || this.state.pendingTasks.some((t) => t.id === taskId) || this.state.completedTasks.some((t) => t.id === taskId)) {
      return false;
    }

    this.state.pendingTasks.push({
      id: template.id,
      completeAtMinute: this.state.minute + template.durationMinutes,
      template
    });
    this.bus.emit('staffTaskQueued', { label: template.label, etaMinute: this.state.minute + template.durationMinutes });
    return true;
  }

  canDecide() {
    return this.state.visitedApps.size >= this.state.mustUseAppsCount;
  }

  decide(decisionId) {
    if (this.state.chosenDecisionId) return;

    const decision = resolveDecision({
      decisionId,
      caseData: this.caseData,
      minute: this.state.minute,
      analystCompleted: this.state.completedTasks.some((t) => t.id === 'analyst_verify'),
      surveillanceCompleted: this.state.completedTasks.some((t) => t.id === 'surveil_airport')
    });

    this.state.chosenDecisionId = decision.id;
    this.state.outcome = decision.outcome;
    this.state.politicalCapital += decision.politicalCapitalDelta;
    this.state.homeOfficeDebrief = decision.debrief;

    this.bus.emit('decisionResolved', this.getPublicState());
    this.stop();
  }

  _runTaskCompletions() {
    const done = this.state.pendingTasks.filter((task) => task.completeAtMinute <= this.state.minute);
    if (!done.length) return;

    this.state.pendingTasks = this.state.pendingTasks.filter((task) => task.completeAtMinute > this.state.minute);
    done.forEach((task) => {
      this.state.completedTasks.push(task);
      const result = task.template.resultMessage;
      this.state.inbox.push({
        id: `staff_${task.id}_${this.state.minute}`,
        subject: result.subject,
        messages: [{ atMinute: this.state.minute, from: result.from, body: result.body, type: result.type }]
      });
      this.bus.emit('staffTaskCompleted', { taskId: task.id, message: result.subject });
    });
  }

  _runScheduledEvents() {
    const due = this.scheduledEvents.filter((evt) => evt.atMinute <= this.state.minute);
    this.scheduledEvents = this.scheduledEvents.filter((evt) => evt.atMinute > this.state.minute);
    due.forEach((evt) => {
      if (evt.type === 'intercept') {
        this.state.intercepts.push(evt.payload);
        this.bus.emit('interceptCaptured', evt.payload);
      }

      if (evt.type === 'deadline' && !this.state.chosenDecisionId) {
        this.bus.emit('deadline', evt.payload);
      }
    });
  }

  getPublicState() {
    return {
      ...this.state,
      appCountMet: this.canDecide(),
      displayTime: SimClock.format(this.baseHour * 60 + this.state.minute),
      timeRemaining: Math.max(0, this.caseData.decisionDeadlineMinutes - this.state.minute)
    };
  }
}

export function resolveDecision({ decisionId, caseData, minute, analystCompleted, surveillanceCompleted }) {
  const selected = caseData.decisions.find((d) => d.id === decisionId);
  if (!selected) throw new Error(`Unknown decision: ${decisionId}`);

  if (selected.id === 'verify_then_airport' && !analystCompleted) {
    return {
      ...selected,
      outcome: 'partial_success',
      politicalCapitalDelta: 0,
      debrief:
        'Home Office: Redirect was directionally correct but moved without full verification. Results were mixed and politically neutral.'
    };
  }

  if (selected.id === 'surveil_airport_now' && minute > caseData.decisionDeadlineMinutes - 2 && !surveillanceCompleted) {
    return {
      ...selected,
      outcome: 'failure',
      politicalCapitalDelta: -6,
      debrief: 'Home Office: Surveillance order came too late. Target exfiltrated before team was in place.'
    };
  }

  return selected;
}
