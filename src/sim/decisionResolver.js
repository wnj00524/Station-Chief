export function resolveDecision({ decisionId, caseData, minute, analystCompleted, surveillanceCompleted }) {
  const selected = caseData.decisions.find((decision) => decision.id === decisionId);
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
