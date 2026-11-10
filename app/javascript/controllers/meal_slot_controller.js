import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "formContainer",
    "locationInput",
    "amountInput",
    "placeInput",
    "homeNotice",
    "streetNotice",
    "homeBtn",
    "streetBtn",
    "amountWrapper",
    "placeWrapper",
    "amountLabel"
  ]

  select(event) {
    const loc = event.currentTarget.dataset.location
    this.locationInputTarget.value = loc

    // Desplegar contenedor con animación suave
    this.formContainerTarget.classList.remove("hidden", "max-h-0", "opacity-0", "-translate-y-2")
    this.formContainerTarget.classList.add("max-h-[500px]", "opacity-100", "translate-y-0")

    if (loc === "street") {
      // Estilo activo para botón Calle
      this.streetBtnTarget.classList.add("ring-2", "ring-amber-500", "bg-amber-100", "text-amber-900")
      this.homeBtnTarget.classList.remove("ring-2", "ring-emerald-500", "bg-emerald-100", "text-emerald-900")

      // Mostrar avisos e inputs de Calle
      if (this.hasStreetNoticeTarget) this.streetNoticeTarget.classList.remove("hidden")
      if (this.hasHomeNoticeTarget) this.homeNoticeTarget.classList.add("hidden")
      if (this.hasAmountWrapperTarget) this.amountWrapperTarget.classList.remove("hidden")
      if (this.hasPlaceWrapperTarget) this.placeWrapperTarget.classList.remove("hidden")

      // Enfoque automático para ingresar el monto al instante
      setTimeout(() => {
        this.amountInputTarget.focus()
      }, 150)
    } else {
      // Estilo activo para botón Casa
      this.homeBtnTarget.classList.add("ring-2", "ring-emerald-500", "bg-emerald-100", "text-emerald-900")
      this.streetBtnTarget.classList.remove("ring-2", "ring-amber-500", "bg-amber-100", "text-amber-900")

      // Mostrar aviso de Casa y ocultar campos de gasto/lugar
      if (this.hasHomeNoticeTarget) this.homeNoticeTarget.classList.remove("hidden")
      if (this.hasStreetNoticeTarget) this.streetNoticeTarget.classList.add("hidden")
      if (this.hasAmountWrapperTarget) this.amountWrapperTarget.classList.add("hidden")
      if (this.hasPlaceWrapperTarget) this.placeWrapperTarget.classList.add("hidden")

      this.amountInputTarget.value = "0.00"
    }
  }

  cancel() {
    // Colapsar suavemente el formulario
    this.formContainerTarget.classList.remove("max-h-[500px]", "opacity-100", "translate-y-0")
    this.formContainerTarget.classList.add("max-h-0", "opacity-0", "-translate-y-2")

    // Quitar estados activos
    this.streetBtnTarget.classList.remove("ring-2", "ring-amber-500", "bg-amber-100", "text-amber-900")
    this.homeBtnTarget.classList.remove("ring-2", "ring-emerald-500", "bg-emerald-100", "text-emerald-900")

    setTimeout(() => {
      this.formContainerTarget.classList.add("hidden")
    }, 250)
  }
}
