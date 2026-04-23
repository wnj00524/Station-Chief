import test from 'node:test';
import assert from 'node:assert/strict';

import caseData from '../../src/data/cases/falconMeeting.js';
import { resolveDecision } from '../../src/sim/decisionResolver.js';

test('resolveDecision returns authored success when analyst verification completed', () => {
  const result = resolveDecision({
    decisionId: 'verify_then_airport',
    caseData,
    minute: 5,
    analystCompleted: true,
    surveillanceCompleted: false
  });

  assert.equal(result.outcome, 'success');
  assert.equal(result.politicalCapitalDelta, 10);
});

test('resolveDecision downgrades verification branch without analyst completion', () => {
  const result = resolveDecision({
    decisionId: 'verify_then_airport',
    caseData,
    minute: 5,
    analystCompleted: false,
    surveillanceCompleted: false
  });

  assert.equal(result.outcome, 'partial_success');
  assert.equal(result.politicalCapitalDelta, 0);
});

test('resolveDecision fails late airport surveillance decisions', () => {
  const result = resolveDecision({
    decisionId: 'surveil_airport_now',
    caseData,
    minute: 9,
    analystCompleted: false,
    surveillanceCompleted: false
  });

  assert.equal(result.outcome, 'failure');
  assert.equal(result.politicalCapitalDelta, -6);
});
