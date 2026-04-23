export class WindowManager {
  constructor(defaultApp = 'inbox') {
    this.currentApp = defaultApp;
  }

  open(appId) {
    this.currentApp = appId;
    return this.currentApp;
  }

  getCurrentApp() {
    return this.currentApp;
  }
}
