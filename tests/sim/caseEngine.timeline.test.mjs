import test from 'node:test';
import assert from 'node:assert/strict';

import caseData from '../../src/data/cases/falconMeeting.js';
import { CaseEngine } from '../../src/sim/caseEngine.js';

test('case engine emits scheduled intercepts by timeline minute', () => {
  const engine = new CaseEngine(caseData);

  engine.state.minute = 1;
  engine._runScheduledEvents();

  assert.equal(engine.state.intercepts.length, 1);
  assert.equal(engine.state.intercepts[0].id, 'int_001');

  engine.state.minute = 3;
  engine._runScheduledEvents();

  assert.equal(engine.state.intercepts.length, 2);
  assert.equal(engine.state.intercepts[1].id, 'int_002');
});

test('case engine moves completed tasks to inbox report threads', () => {
  const engine = new CaseEngine(caseData);

  assert.equal(engine.scheduleTask('analyst_verify'), true);
  engine.state.minute = 2;
  engine._runTaskCompletions();

  assert.equal(engine.state.completedTasks.length, 1);
  const generatedThread = engine.state.inbox.find((thread) => thread.id.startsWith('staff_analyst_verify_'));
  assert.ok(generatedThread);
  assert.equal(generatedThread.subject, 'Verification Report: Falcon');
});
