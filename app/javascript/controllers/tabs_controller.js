import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "panel"]
  static classes = ["active", "inactive"]

  connect() {
    this.showTab(0)
  }

  switch(event) {
    event.preventDefault()
    const index = this.buttonTargets.indexOf(event.currentTarget)
    this.showTab(index)
  }

  showTab(index) {
    this.buttonTargets.forEach((button, i) => {
      if (i === index) {
        button.classList.add(...this.activeClasses)
        button.classList.remove(...this.inactiveClasses)
      } else {
        button.classList.remove(...this.activeClasses)
        button.classList.add(...this.inactiveClasses)
      }
    })

    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })
  }
}
