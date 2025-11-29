import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["sidebar", "messages", "input"]

    toggleSidebar() {
        this.sidebarTarget.classList.toggle("hidden")
    }

    async sendMessage(event) {
        event.preventDefault()

        const question = this.inputTarget.value.trim()
        if (!question) return

        // Add user message to chat
        this.addMessage(question, "user")
        this.inputTarget.value = ""

        // Get regulation IDs from current view
        const regulationIds = this.getRegulationIds()

        // Show loading indicator
        const loadingId = this.addMessage("Thinking...", "assistant", true)

        try {
            const response = await fetch("/admin/compliance_assistant/chat", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
                },
                body: JSON.stringify({
                    question: question,
                    regulation_ids: regulationIds
                })
            })

            const data = await response.json()

            // Remove loading indicator
            document.getElementById(loadingId)?.remove()

            if (response.ok) {
                this.addMessage(data.response, "assistant")
            } else {
                this.addMessage(data.error || "Sorry, something went wrong.", "assistant")
            }
        } catch (error) {
            // Remove loading indicator
            document.getElementById(loadingId)?.remove()
            this.addMessage("Sorry, I couldn't connect to the server.", "assistant")
        }
    }

    addMessage(text, sender, isLoading = false) {
        const messageId = `msg-${Date.now()}`
        const messageDiv = document.createElement("div")
        messageDiv.id = messageId
        messageDiv.className = sender === "user"
            ? "flex justify-end"
            : "flex justify-start"

        const bubble = document.createElement("div")
        bubble.className = sender === "user"
            ? "bg-indigo-600 text-white rounded-lg px-4 py-2 max-w-xs"
            : "bg-gray-200 text-gray-900 rounded-lg px-4 py-2 max-w-xs"

        if (isLoading) {
            bubble.innerHTML = '<span class="animate-pulse">●●●</span>'
        } else {
            bubble.textContent = text
        }

        messageDiv.appendChild(bubble)
        this.messagesTarget.appendChild(messageDiv)

        // Scroll to bottom
        this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight

        return messageId
    }

    getRegulationIds() {
        // Extract regulation IDs from the table rows
        const rows = document.querySelectorAll("tbody tr")
        const ids = []

        rows.forEach(row => {
            const link = row.querySelector("a[href*='/admin/regulations/']")
            if (link) {
                const match = link.href.match(/\/admin\/regulations\/(\d+)/)
                if (match) ids.push(match[1])
            }
        })

        return ids
    }
}
