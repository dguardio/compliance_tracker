import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "modal", "iframe"]

  connect() {
    console.log("Document preview controller connected")
  }

  openPdfViewer(event) {
    event.preventDefault()
    const url = event.currentTarget.getAttribute('data-url')
    this.openModal(url, 'pdf')
  }

  embedViewer(event) {
    event.preventDefault()
    const url = event.currentTarget.getAttribute('data-url')
    this.openModal(url, 'office')
  }

  openModal(url, type) {
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50'
    modal.innerHTML = `
      <div class="relative top-20 mx-auto p-5 border w-11/12 h-5/6 shadow-lg rounded-md bg-white">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold">Document Preview</h3>
          <button class="text-gray-400 hover:text-gray-600" onclick="this.closest('.fixed').remove()">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
        <div class="h-full">
          ${type === 'pdf' ? this.createPdfViewer(url) : this.createOfficeViewer(url)}
        </div>
      </div>
    `
    
    document.body.appendChild(modal)
    
    // Close modal when clicking outside
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        modal.remove()
      }
    })
  }

  createPdfViewer(url) {
    return `
      <iframe 
        src="/pdfjs/web/viewer.html?file=${encodeURIComponent(url)}" 
        class="w-full h-full border-0"
        frameborder="0">
      </iframe>
    `
  }

  createOfficeViewer(url) {
    return `
      <iframe 
        src="${url}" 
        class="w-full h-full border-0"
        frameborder="0">
      </iframe>
    `
  }

  // Global functions for onclick handlers
  static openPdfViewer(url) {
    const controller = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="document-preview"]'),
      'document-preview'
    )
    if (controller) {
      controller.openPdfViewer({ preventDefault: () => {}, currentTarget: { getAttribute: () => url } })
    }
  }

  static embedViewer(url) {
    const controller = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="document-preview"]'),
      'document-preview'
    )
    if (controller) {
      controller.embedViewer({ preventDefault: () => {}, currentTarget: { getAttribute: () => url } })
    }
  }
}

// Make functions globally available
window.openPdfViewer = (url) => {
  const event = { preventDefault: () => {}, currentTarget: { getAttribute: () => url } }
  const controller = document.querySelector('[data-controller="document-preview"]')?.stimulus?.getControllerForElementAndIdentifier(
    document.querySelector('[data-controller="document-preview"]'),
    'document-preview'
  )
  if (controller) {
    controller.openPdfViewer(event)
  }
}

window.embedViewer = (url) => {
  const event = { preventDefault: () => {}, currentTarget: { getAttribute: () => url } }
  const controller = document.querySelector('[data-controller="document-preview"]')?.stimulus?.getControllerForElementAndIdentifier(
    document.querySelector('[data-controller="document-preview"]'),
    'document-preview'
  )
  if (controller) {
    controller.embedViewer(event)
  }
} 