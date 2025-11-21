import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "overlay" ]

  connect() {
    document.addEventListener("keydown", this.closeWithKeyboard.bind(this))
    this.element.addEventListener("modal:close", this.close.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.closeWithKeyboard.bind(this))
    this.element.removeEventListener("modal:close", this.close.bind(this))
  }

  close() {
    this.element.parentElement.removeAttribute("src") // Remove the src attribute from the turbo-frame
    this.element.remove()
  }

  closeWithKeyboard(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
