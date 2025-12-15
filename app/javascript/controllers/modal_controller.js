import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["newColumnModal", "saveTemplateModal", "templateModal"]

  connect() {
    this.boundCloseWithKeyboard = this.closeWithKeyboard.bind(this)
    document.addEventListener("keydown", this.boundCloseWithKeyboard)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundCloseWithKeyboard)
  }

  open(event) {
    // Check if a specific modal target is specified via param
    const modalName = event.params.target || "newColumnModal"
    // Use dynamic property access to get the target element
    // Stimulus creates properties like `this.newColumnModalTarget` for single targets
    // or `this.targets.find(name)` with the TargetSet API
    const modal = this.targets.find(modalName)

    if (modal) {
      modal.classList.remove("hidden")
      // Prevent body scrolling
      document.body.classList.add("overflow-hidden")
    }
  }

  close(event) {
    // Close all modals managed by this controller
    this.newColumnModalTargets.forEach(modal => modal.classList.add("hidden"))
    this.saveTemplateModalTargets.forEach(modal => modal.classList.add("hidden"))
    this.templateModalTargets.forEach(modal => modal.classList.add("hidden"))

    // Re-enable body scrolling
    document.body.classList.remove("overflow-hidden")
  }

  closeWithKeyboard(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
