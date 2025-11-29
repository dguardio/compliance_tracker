import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["content", "form", "input", "start", "end", "selected", "list", "suggestionField", "suggestedText", "assigneeField", "assigneeSelect"]
    static values = {
        url: String,
        comments: Array,
        users: Array
    }

    connect() {
        console.log("Commentable controller connected")
        this.hideForm()
        this.loadComments()
    }

    loadComments() {
        if (this.hasCommentsValue) {
            this.commentsValue.forEach(comment => {
                this.appendComment(comment)
                this.highlightRange(comment.start_index, comment.end_index, comment.comment_type, comment.id)
            })
        }
    }

    highlightRange(start, end, type, id) {
        const root = this.contentTarget
        const treeWalker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null, false)

        let current = 0
        let node

        while ((node = treeWalker.nextNode())) {
            const length = node.textContent.length

            // Check if this node overlaps with the range
            if (current + length > start && current < end) {
                const range = document.createRange()

                const nodeStart = Math.max(0, start - current)
                const nodeEnd = Math.min(length, end - current)

                range.setStart(node, nodeStart)
                range.setEnd(node, nodeEnd)

                const wrapper = document.createElement(type === 'suggestion' || type === 'evidence_request' ? 'span' : 'mark')
                if (type === 'suggestion') {
                    wrapper.className = "bg-purple-100 text-purple-700 border-b-2 border-purple-400 cursor-pointer suggestion-highlight"
                } else if (type === 'evidence_request') {
                    wrapper.className = "bg-blue-100 text-blue-700 border-b-2 border-blue-400 cursor-pointer evidence-request-highlight"
                } else {
                    wrapper.className = "bg-yellow-200 cursor-pointer comment-highlight"
                }

                wrapper.dataset.commentId = id
                wrapper.addEventListener('click', (e) => {
                    e.stopPropagation()
                    this.scrollToComment(id)
                })

                range.surroundContents(wrapper)

                // Reset tree walker because DOM changed
                // This is a naive approach; for production, we'd need to handle split nodes better.
                // But for this demo, it should work if comments don't overlap heavily.
                return // Stop after first match for simplicity in this iteration, or adjust logic to continue
            }

            current += length
        }
    }

    scrollToComment(id) {
        // Implementation to scroll sidebar to comment
        const commentEl = this.listTarget.querySelector(`[data-comment-id="${id}"]`)
        if (commentEl) {
            commentEl.scrollIntoView({ behavior: 'smooth', block: 'center' })
            commentEl.classList.add('ring-2', 'ring-indigo-500')
            setTimeout(() => commentEl.classList.remove('ring-2', 'ring-indigo-500'), 2000)
        }
    }

    handleSelection(event) {
        const selection = window.getSelection()
        if (selection.rangeCount === 0 || selection.isCollapsed) {
            return
        }

        const range = selection.getRangeAt(0)
        const selectedText = selection.toString()

        // Simple offset calculation (can be improved for nested elements)
        // We assume the content target is the root container
        const preSelectionRange = range.cloneRange()
        preSelectionRange.selectNodeContents(this.contentTarget)
        preSelectionRange.setEnd(range.startContainer, range.startOffset)
        const start = preSelectionRange.toString().length
        const end = start + selectedText.length

        console.log(`Selection: "${selectedText}" (${start}-${end})`)

        this.showForm(selectedText, start, end, range)
    }

    showForm(text, start, end, range) {
        this.selectedTarget.value = text
        this.startTarget.value = start
        this.endTarget.value = end

        // Position the form near the selection
        const rect = range.getBoundingClientRect()
        const form = this.formTarget
        form.style.display = "block"
        form.style.top = `${window.scrollY + rect.bottom + 10}px`
        form.style.left = `${window.scrollX + rect.left}px`
    }

    hideForm() {
        this.formTarget.style.display = "none"
    }

    toggleType(event) {
        const type = event.target.value
        if (type === 'suggestion') {
            this.suggestionFieldTarget.classList.remove('hidden')
            this.assigneeFieldTarget.classList.add('hidden')
            this.inputTarget.placeholder = "Reason for suggestion..."
        } else if (type === 'evidence_request') {
            this.suggestionFieldTarget.classList.add('hidden')
            this.assigneeFieldTarget.classList.remove('hidden')
            this.inputTarget.placeholder = "Describe evidence needed..."
        } else {
            this.suggestionFieldTarget.classList.add('hidden')
            this.assigneeFieldTarget.classList.add('hidden')
            this.inputTarget.placeholder = "Type your comment..."
        }
    }

    submit(event) {
        event.preventDefault()

        const content = this.inputTarget.value
        const selectedText = this.selectedTarget.value
        const startIndex = this.startTarget.value
        const endIndex = this.endTarget.value

        // Get selected type
        const typeRadio = this.formTarget.querySelector('input[name="comment_type"]:checked')
        const commentType = typeRadio ? typeRadio.value : 'comment'
        const assigneeId = this.assigneeSelectTarget.value

        if (!content && commentType === 'comment') return
        if (commentType === 'suggestion' && !suggestedText) {
            alert("Please provide suggested text")
            return
        }
        if (commentType === 'evidence_request' && !assigneeId) {
            alert("Please select an assignee")
            return
        }

        fetch(this.urlValue, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({
                comment: {
                    content: content,
                    selected_text: selectedText,
                    start_index: startIndex,
                    end_index: endIndex,
                    comment_type: commentType,
                    suggested_text: suggestedText,
                    assignee_id: assigneeId
                }
            })
        })
            .then(async response => {
                if (response.ok) {
                    return response.json()
                } else {
                    const contentType = response.headers.get("content-type");
                    if (contentType && contentType.indexOf("application/json") !== -1) {
                        const errorData = await response.json();
                        throw new Error(errorData.errors ? errorData.errors.join(", ") : "Server error");
                    } else {
                        const text = await response.text();
                        console.error("Non-JSON response:", text);
                        throw new Error("Network response was not ok: " + response.statusText);
                    }
                }
            })
            .then(data => {
                this.appendComment(data)
                this.highlightRange(parseInt(startIndex), parseInt(endIndex), commentType, data.id)
                this.hideForm()
                this.inputTarget.value = ""
                this.suggestedTextTarget.value = ""
                // Reset to comment type
                const commentRadio = this.formTarget.querySelector('input[value="comment"]')
                if (commentRadio) {
                    commentRadio.checked = true
                    this.toggleType({ target: commentRadio })
                }
                window.getSelection().removeAllRanges()
            })
            .catch(error => {
                console.error("Error:", error)
                alert(`Failed to save comment: ${error.message}`)
            })
    }

    appendComment(data) {
        const isSuggestion = data.comment_type === 'suggestion'
        const isEvidenceRequest = data.comment_type === 'evidence_request'

        let typeLabel = ''
        let borderClass = 'border-yellow-200 bg-yellow-50'

        if (isSuggestion) {
            typeLabel = `<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800 ml-2">Suggestion</span>`
            borderClass = 'border-purple-200 bg-purple-50'
        } else if (isEvidenceRequest) {
            typeLabel = `<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800 ml-2">Evidence Request</span>`
            borderClass = 'border-blue-200 bg-blue-50'
            if (data.assignee) {
                typeLabel += `<span class="text-xs text-gray-500 ml-2">assigned to ${data.assignee}</span>`
            }
        }

        let suggestionHtml = ''
        if (isSuggestion && data.suggested_text) {
            suggestionHtml = `
                <div class="mt-2 text-xs border-t border-purple-200 pt-2">
                    <div class="flex items-center gap-2 mb-1">
                        <span class="text-red-600 line-through bg-red-50 px-1 rounded">${data.selected_text}</span>
                        <span class="text-gray-400">→</span>
                        <span class="text-green-600 font-medium bg-green-50 px-1 rounded">${data.suggested_text}</span>
                    </div>
                </div>
             `
        }

        const commentHtml = `
      <div class="${borderClass} p-3 rounded mb-2 border text-sm" data-comment-id="${data.id}">
        <div class="flex justify-between items-start">
            <p class="font-semibold text-gray-900">${data.user} ${typeLabel}</p>
            <span class="text-gray-500 font-normal text-xs">${data.created_at}</span>
        </div>
        <p class="mt-1 text-gray-800">${data.content}</p>
        ${!isSuggestion ? `<p class="mt-1 text-xs text-gray-500 italic border-l-2 border-gray-300 pl-2">"${data.selected_text || '...'}"</p>` : ''}
        ${suggestionHtml}
      </div>
    `
        this.listTarget.insertAdjacentHTML("afterbegin", commentHtml)
    }
}
