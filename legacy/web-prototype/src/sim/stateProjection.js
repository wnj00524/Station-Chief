import { SimClock } from './clock.js';

export function projectCaseState(state, caseData, baseHour) {
  return {
    ...state,
    appCountMet: state.visitedApps.size >= state.mustUseAppsCount,
    displayTime: SimClock.format(baseHour * 60 + state.minute),
    timeRemaining: Math.max(0, caseData.decisionDeadlineMinutes - state.minute)
  };
}
