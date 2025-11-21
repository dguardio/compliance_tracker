import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import { patch } from '@rails/request.js'

export default class extends Controller {
  static targets = ["column"]

  connect() {
    this.columnTargets.forEach((column) => {
      new Sortable(column, {
        group: 'kanban', // set both lists to same group
        animation: 150,
        onEnd: this.onEnd.bind(this)
      });
    });
  }

  onEnd(event) {
    const id = event.item.dataset.id
    const newStatus = event.to.dataset.status
    const url = `/tasks/${id}/update_status`

    patch(url, { body: JSON.stringify({ status: newStatus }) })
  }
}
