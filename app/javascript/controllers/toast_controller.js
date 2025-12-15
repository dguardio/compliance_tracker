import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this.enter()

        // Auto-dismiss after 5 seconds if not error
        if (!this.element.classList.contains("bg-danger-100")) {
            setTimeout(() => {
                this.close()
            }, 5000)
        }
    }

    enter() {
        const transition = this.element.dataset.transitionEnter || ""
        const start = this.element.dataset.transitionEnterStart || ""
        const end = this.element.dataset.transitionEnterEnd || ""

        // Apply base transition classes
        if (transition) this.element.classList.add(...transition.split(" "))

        // Apply start state
        if (start) this.element.classList.add(...start.split(" "))

        // Next frame: remove start, apply end
        requestAnimationFrame(() => {
            if (start) this.element.classList.remove(...start.split(" "))
            if (end) this.element.classList.add(...end.split(" "))
        })
    }

    close(event) {
        if (event) event.preventDefault()

        const transition = this.element.dataset.transitionLeave || ""
        const start = this.element.dataset.transitionLeaveStart || ""
        const end = this.element.dataset.transitionLeaveEnd || ""

        // Apply base transition classes
        if (transition) this.element.classList.add(...transition.split(" "))

        // Apply start state
        if (start) this.element.classList.add(...start.split(" "))

        // Next frame: remove start, apply end
        requestAnimationFrame(() => {
            if (start) this.element.classList.remove(...start.split(" "))
            if (end) this.element.classList.add(...end.split(" "))
        })

        // Remove element after transition completes (approx 300ms)
        setTimeout(() => {
            this.element.remove()
        }, 300)
    }
}
