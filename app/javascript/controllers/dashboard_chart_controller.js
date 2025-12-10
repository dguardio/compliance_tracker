import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  static targets = ["pieChart"]

  connect() {
    const data = JSON.parse(this.element.dataset.tasksByStatus)
    const labels = Object.keys(data)
    const values = Object.values(data)

    this.chart = new Chart(this.pieChartTarget, {
      type: 'pie',
      data: {
        labels: labels.map(l => l.charAt(0).toUpperCase() + l.slice(1).replace(/_/g, ' ')),
        datasets: [{
          label: 'Tasks by Status',
          data: values,
          backgroundColor: [
            'rgba(255, 99, 132, 0.7)',
            'rgba(54, 162, 235, 0.7)',
            'rgba(255, 206, 86, 0.7)',
            'rgba(75, 192, 192, 0.7)',
            'rgba(153, 102, 255, 0.7)',
            'rgba(255, 159, 64, 0.7)'
          ],
          borderColor: [
            'rgba(255, 99, 132, 1)',
            'rgba(54, 162, 235, 1)',
            'rgba(255, 206, 86, 1)',
            'rgba(75, 192, 192, 1)',
            'rgba(153, 102, 255, 1)',
            'rgba(255, 159, 64, 1)'
          ],
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    });
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }
}
