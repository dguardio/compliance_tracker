import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "button", "panel" ]

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
      button.classList.toggle("bg-indigo-100", i === index)
      button.classList.toggle("text-indigo-700", i === index)
      button.classList.toggle("text-gray-500", i !== index)
      button.classList.toggle("hover:text-gray-700", i !== index)
      button.classList.toggle("hover:bg-gray-50", i !== index)
    })

    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })
  }
}
