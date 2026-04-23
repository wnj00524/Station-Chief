export class SimClock {
  constructor(startMinutes = 8 * 60, tickMs = 1000) {
    this.currentMinutes = startMinutes;
    this.tickMs = tickMs;
    this.timer = null;
  }

  start(onTick) {
    if (this.timer) return;
    this.timer = setInterval(() => {
      this.currentMinutes += 1;
      onTick(this.currentMinutes);
    }, this.tickMs);
  }

  stop() {
    clearInterval(this.timer);
    this.timer = null;
  }

  static format(totalMinutes) {
    const hrs = Math.floor(totalMinutes / 60)
      .toString()
      .padStart(2, '0');
    const mins = (totalMinutes % 60).toString().padStart(2, '0');
    return `${hrs}:${mins}`;
  }
}
