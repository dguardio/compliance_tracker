import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "select"]
  static values = {
    sourceId: String,
    targetId: String,
    sourceAnchorType: String,
    targetAnchorType: String
  }

  connect() {
  }

  submit(event) {
    event.preventDefault()

    const condition = this.selectTarget.value || 'default'
    
    const detail = {
      sourceId: this.sourceIdValue,
      targetId: this.targetIdValue,
      condition: condition,
      sourceAnchorType: this.sourceAnchorTypeValue,
      targetAnchorType: this.targetAnchorTypeValue
    }

    // Dispatch a custom event that the workflow-editor controller can listen to
    this.dispatch("save-connection", { detail })

    // Modal will be closed by the workflow-editor controller after successful save
  }
}
