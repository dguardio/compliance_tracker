import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="source-type-toggle"
export default class extends Controller {
    static targets = ["selector", "apiSettings", "authSettings", "smartConfig"]

    connect() {
        this.toggle()
    }

    toggle() {
        if (this.selectorTarget.value === "api") {
            if (this.hasApiSettingsTarget) this.apiSettingsTarget.classList.remove("hidden")
            if (this.hasAuthSettingsTarget) this.authSettingsTarget.classList.remove("hidden")
            if (this.hasSmartConfigTarget) this.smartConfigTarget.classList.remove("hidden")
        } else {
            if (this.hasApiSettingsTarget) this.apiSettingsTarget.classList.add("hidden")
            if (this.hasAuthSettingsTarget) this.authSettingsTarget.classList.add("hidden")
            if (this.hasSmartConfigTarget) this.smartConfigTarget.classList.add("hidden")
        }
    }
}
