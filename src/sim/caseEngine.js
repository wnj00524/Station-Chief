import { EventBus } from './eventBus.js';
import { SimClock } from './clock.js';
import { Scheduler } from './scheduler.js';
import { resolveDecision } from './decisionResolver.js';
import { projectCaseState } from './stateProjection.js';

export class CaseEngine {
  constructor(caseData, options = {}) {
    this.caseData = caseData;
    this.bus = new EventBus();
    this.baseHour = Number(caseData.startTime.split(':')[0]);
    this.clock = new SimClock(this.baseHour * 60, options.tickMs || 1000);
    this.scheduler = new Scheduler();
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
    this._seedEvents();
  }

  _seedEvents() {
    this.scheduler.scheduleMany(
      this.caseData.intercepts.map((intercept) => ({
        atMinute: intercept.availableAtMinute,
        type: 'intercept',
        payload: intercept
      }))
    );

    this.scheduler.schedule({
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
    const template = this.caseData.staffTemplates.find((task) => task.id === taskId);
    if (!template || this.state.pendingTasks.some((task) => task.id === taskId) || this.state.completedTasks.some((task) => task.id === taskId)) {
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
      analystCompleted: this.state.completedTasks.some((task) => task.id === 'analyst_verify'),
      surveillanceCompleted: this.state.completedTasks.some((task) => task.id === 'surveil_airport')
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
    const due = this.scheduler.popDue(this.state.minute);
    due.forEach((event) => {
      if (event.type === 'intercept') {
        this.state.intercepts.push(event.payload);
        this.bus.emit('interceptCaptured', event.payload);
      }

      if (event.type === 'deadline' && !this.state.chosenDecisionId) {
        this.bus.emit('deadline', event.payload);
      }
    });
  }

  getPublicState() {
    return projectCaseState(this.state, this.caseData, this.baseHour);
  }
}
