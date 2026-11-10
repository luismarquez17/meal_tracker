import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    type: { type: String, default: "bar" },
    data: Object,
    options: { type: Object, default: {} }
  }

  connect() {
    this.renderChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  renderChart() {
    const ChartClass = window.Chart || (typeof Chart !== "undefined" ? Chart : null)
    if (!ChartClass) {
      setTimeout(() => this.renderChart(), 100)
      return
    }

    if (this.chart) {
      this.chart.destroy()
    }

    const ctx = this.element.getContext("2d")
    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: "bottom",
          labels: {
            boxWidth: 12,
            font: { size: 12 }
          }
        }
      }
    }

    this.chart = new ChartClass(ctx, {
      type: this.typeValue,
      data: this.dataValue,
      options: Object.assign({}, defaultOptions, this.optionsValue)
    })
  }

  downloadImage(event) {
    if (event) event.preventDefault()
    if (!this.chart || !this.element) return

    const title = this.element.getAttribute("data-chart-title") || "grafica_gastos"
    const dateStr = new Date().toISOString().slice(0, 10)

    // Crear canvas temporal con fondo blanco sólido para exportación nítida
    const canvas = this.element
    const tempCanvas = document.createElement("canvas")
    tempCanvas.width = canvas.width
    tempCanvas.height = canvas.height
    const tempCtx = tempCanvas.getContext("2d")

    // Fondo blanco nítido
    tempCtx.fillStyle = "#ffffff"
    tempCtx.fillRect(0, 0, tempCanvas.width, tempCanvas.height)

    // Dibujar la gráfica encima
    tempCtx.drawImage(canvas, 0, 0)

    // Firma visual en la esquina inferior
    tempCtx.fillStyle = "#94a3b8"
    tempCtx.font = "bold 13px 'Plus Jakarta Sans', system-ui, sans-serif"
    tempCtx.textAlign = "right"
    tempCtx.fillText("🍲 MealTracker App", tempCanvas.width - 16, tempCanvas.height - 12)

    const dataUrl = tempCanvas.toDataURL("image/png", 1.0)
    const link = document.createElement("a")
    link.download = `${title}_${dateStr}.png`
    link.href = dataUrl
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }
}
