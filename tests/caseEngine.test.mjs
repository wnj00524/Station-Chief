import assert from 'node:assert/strict';
import caseData from '../src/data/cases/falconMeeting.js';
import { resolveDecision } from '../src/sim/caseEngine.js';

const success = resolveDecision({
  decisionId: 'verify_then_airport',
  caseData,
  minute: 5,
  analystCompleted: true,
  surveillanceCompleted: false
});
assert.equal(success.outcome, 'success');
assert.equal(success.politicalCapitalDelta, 10);

const downgraded = resolveDecision({
  decisionId: 'verify_then_airport',
  caseData,
  minute: 5,
  analystCompleted: false,
  surveillanceCompleted: false
});
assert.equal(downgraded.outcome, 'partial_success');
assert.equal(downgraded.politicalCapitalDelta, 0);

const lateFailure = resolveDecision({
  decisionId: 'surveil_airport_now',
  caseData,
  minute: 9,
  analystCompleted: false,
  surveillanceCompleted: false
});
assert.equal(lateFailure.outcome, 'failure');
assert.equal(lateFailure.politicalCapitalDelta, -6);

console.log('caseEngine decision branching tests passed');
