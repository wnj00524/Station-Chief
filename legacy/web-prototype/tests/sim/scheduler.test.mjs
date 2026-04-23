import test from 'node:test';
import assert from 'node:assert/strict';

import { Scheduler } from '../../src/sim/scheduler.js';

test('scheduler pops only due events and preserves time order', () => {
  const scheduler = new Scheduler();

  scheduler.scheduleMany([
    { atMinute: 3, type: 'intercept' },
    { atMinute: 1, type: 'intercept' },
    { atMinute: 5, type: 'deadline' }
  ]);

  const minuteOneDue = scheduler.popDue(1);
  assert.equal(minuteOneDue.length, 1);
  assert.equal(minuteOneDue[0].atMinute, 1);

  const minuteFourDue = scheduler.popDue(4);
  assert.equal(minuteFourDue.length, 1);
  assert.equal(minuteFourDue[0].atMinute, 3);

  const minuteFiveDue = scheduler.popDue(5);
  assert.equal(minuteFiveDue.length, 1);
  assert.equal(minuteFiveDue[0].type, 'deadline');
});
