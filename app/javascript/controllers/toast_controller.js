import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this.enter()

        // Auto-dismiss after 5 seconds if not error
        if (!this.element.querySelector(".bg-danger-100")) {
            setTimeout(() => {
                this.close()
            }, 5000)
        }
    }

    enter() {
        const transition = this.element.dataset.transitionEnter || ""
        const start = this.element.dataset.transitionEnterStart || ""
        const end = this.element.dataset.transitionEnterEnd || ""

        const getClasses = (str) => str.split(" ").filter(Boolean)

        // Apply base transition classes
        if (transition) this.element.classList.add(...getClasses(transition))

        // Apply start state
        if (start) this.element.classList.add(...getClasses(start))

        // Next frame: remove start, apply end
        requestAnimationFrame(() => {
            if (start) this.element.classList.remove(...getClasses(start))
            if (end) this.element.classList.add(...getClasses(end))
        })
    }

    close(event) {
        if (event) event.preventDefault()

        const transition = this.element.dataset.transitionLeave || ""
        const start = this.element.dataset.transitionLeaveStart || ""
        const end = this.element.dataset.transitionLeaveEnd || ""

        const getClasses = (str) => str.split(" ").filter(Boolean)

        // Apply base transition classes
        if (transition && getClasses(transition).length > 0) this.element.classList.add(...getClasses(transition))

        // Apply start state
        if (start && getClasses(start).length > 0) this.element.classList.add(...getClasses(start))

        // Next frame: remove start, apply end
        requestAnimationFrame(() => {
            if (start && getClasses(start).length > 0) this.element.classList.remove(...getClasses(start))
            if (end && getClasses(end).length > 0) this.element.classList.add(...getClasses(end))
        })

        // Remove element after transition completes (approx 300ms)
        setTimeout(() => {
            this.element.remove()
        }, 300)
    }
}
