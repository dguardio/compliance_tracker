import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "results", "container", "tokenContainer"]

    connect() {
        this.boundHandleKeydown = this.handleKeydown.bind(this)
        document.addEventListener("keydown", this.boundHandleKeydown)
    }

    disconnect() {
        document.removeEventListener("keydown", this.boundHandleKeydown)
    }

    handleKeydown(event) {
        if ((event.metaKey || event.ctrlKey) && event.key === "k") {
            event.preventDefault()
            this.inputTarget.focus()
        }

        if (event.key === "Escape") {
            this.inputTarget.blur()
            this.hideResults()
        }
    }

    onFocus() {
        this.containerTarget.classList.add("ring-2", "ring-primary-100", "shadow-primary-glow")
        this.showResults()
    }

    onBlur(event) {
        // Check if the related target is within the controller
        if (this.element.contains(event.relatedTarget)) {
            return
        }
        this.containerTarget.classList.remove("ring-2", "ring-primary-100", "shadow-primary-glow")
        setTimeout(() => {
            this.hideResults()
        }, 200)
    }

    input() {
        const value = this.inputTarget.value

        // Magic Tokenization Logic (Simulation)
        // Check for "Mike" or "Sarah"
        if (value.toLowerCase().includes("mike ")) {
            this.addToken("Mike Ross", "https://i.pravatar.cc/150?u=mike")
            this.inputTarget.value = value.replace(/mike /i, "")
        } else if (value.toLowerCase().includes("sarah ")) {
            this.addToken("Sarah Lee", "https://i.pravatar.cc/150?u=sarah")
            this.inputTarget.value = value.replace(/sarah /i, "")
        }

        this.showResults()
    }

    addToken(name, avatarUrl) {
        const tokenHtml = `
      <div class="inline-flex items-center bg-primary-50 text-primary-700 px-2 py-1 rounded-full text-xs font-medium mr-1 mb-1">
        <img src="${avatarUrl}" class="w-4 h-4 rounded-full mr-1">
        ${name}
        <button type="button" class="ml-1 text-primary-400 hover:text-primary-600 focus:outline-none" onclick="this.parentElement.remove()">
          &times;
        </button>
      </div>
    `
        this.tokenContainerTarget.insertAdjacentHTML("beforeend", tokenHtml)
    }

    showResults() {
        this.resultsTarget.classList.remove("hidden")
    }

    hideResults() {
        this.resultsTarget.classList.add("hidden")
    }
}
