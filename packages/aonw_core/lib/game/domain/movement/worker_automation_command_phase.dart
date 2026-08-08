enum WorkerAutomationCommandPhase {
  direct,
  continuation;

  bool get isContinuation => this == WorkerAutomationCommandPhase.continuation;
}
