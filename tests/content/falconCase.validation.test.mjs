import test from 'node:test';
import assert from 'node:assert/strict';

import caseData from '../../src/data/cases/falconMeeting.js';
import { validateCaseDefinition } from '../../src/data/schemas/caseSchema.js';

test('falcon case satisfies scaffold schema requirements', () => {
  const errors = validateCaseDefinition(caseData);
  assert.deepEqual(errors, []);
});
