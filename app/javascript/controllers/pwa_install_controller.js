import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner", "modal", "iosGuide", "androidGuide", "installBtn"]

  connect() {
    this.deferredPrompt = null

    // Verificar si ya está corriendo como PWA independiente (standalone)
    const isStandalone = window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
    if (isStandalone) {
      this.hideBanner()
      return
    }

    // Detectar si es iOS (iPhone / iPad)
    this.isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream

    // Escuchar el evento oficial de instalación de Android/Chrome
    window.addEventListener("beforeinstallprompt", (e) => {
      e.preventDefault()
      this.deferredPrompt = e
      this.showBanner()
    })

    // Si es iOS y no está instalada, mostrar banner si no se ha descartado
    if (this.isIOS) {
      const dismissed = localStorage.getItem("pwa_install_dismissed")
      if (!dismissed) {
        this.showBanner()
      }
    }
  }

  showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove("hidden")
      this.bannerTarget.style.display = "flex"
    }
  }

  hideBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.add("hidden")
      this.bannerTarget.style.display = "none"
    }
  }

  install() {
    if (this.deferredPrompt) {
      // Flujo nativo de Android / Chrome
      this.deferredPrompt.prompt()
      this.deferredPrompt.userChoice.then((choiceResult) => {
        if (choiceResult.outcome === "accepted") {
          this.hideBanner()
        }
        this.deferredPrompt = null
      })
    } else {
      // Flujo para iOS o navegadores que requieren instrucciones
      this.openModal()
    }
  }

  openModal() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
      this.modalTarget.style.display = "flex"
      if (this.isIOS) {
        if (this.hasIosGuideTarget) {
          this.iosGuideTarget.classList.remove("hidden")
          this.iosGuideTarget.style.display = "block"
        }
        if (this.hasAndroidGuideTarget) {
          this.androidGuideTarget.classList.add("hidden")
          this.androidGuideTarget.style.display = "none"
        }
      } else {
        if (this.hasAndroidGuideTarget) {
          this.androidGuideTarget.classList.remove("hidden")
          this.androidGuideTarget.style.display = "block"
        }
        if (this.hasIosGuideTarget) {
          this.iosGuideTarget.classList.add("hidden")
          this.iosGuideTarget.style.display = "none"
        }
      }
    }
  }

  closeModal() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
      this.modalTarget.style.display = "none"
    }
  }

  dismissBanner() {
    this.hideBanner()
    localStorage.setItem("pwa_install_dismissed", "true")
  }
}
