import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  show() {
    const loadingHtml = `
      <div class="flex flex-col items-center justify-center p-16 bg-white shadow sm:rounded-lg animate-pulse">
        <div class="animate-spin rounded-full h-16 w-16 border-b-4 border-indigo-600 mb-6"></div>
        <h3 class="text-xl font-medium text-gray-900">AI agents are scanning the web...</h3>
        <p class="text-sm text-gray-500 mt-2">Using Google Search and Natural Language Processing to identify regulatory sources.</p>
      </div>
    `;
    
    // If there is a target, replace it. Otherwise replace the whole innerHTML of the controller element.
    if (this.hasContentTarget) {
      this.contentTarget.innerHTML = loadingHtml;
    } else {
      document.getElementById('discovered_sources').innerHTML = loadingHtml;
    }
  }
}
