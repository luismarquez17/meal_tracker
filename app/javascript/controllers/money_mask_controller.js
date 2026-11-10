import { Controller } from "@hotwired/stimulus"

// MoneyMaskController: ATM / Banking style currency input mask
// Example: typing 5 -> "0,05", then 0 -> "0,50", then 0 -> "5,00", then 0 -> "50,00"
// Backspace pops digits from right to left without ever having to delete "0.00" manually.
export default class extends Controller {
  static targets = ["display", "hidden"]
  static values = {
    initial: { type: Number, default: 0 }
  }

  connect() {
    this.rawDigits = ""

    // Read initial value if provided
    let initVal = null
    if (this.hasHiddenTarget && this.hiddenTarget.value) {
      const parsed = parseFloat(this.hiddenTarget.value)
      if (!isNaN(parsed) && parsed > 0) initVal = parsed
    } else if (this.initialValue && this.initialValue > 0) {
      initVal = this.initialValue
    }

    if (initVal !== null) {
      this.rawDigits = Math.round(initVal * 100).toString()
    }

    this.render()

    // Bind event listeners
    this.boundOnInput = this.onInput.bind(this)
    this.boundOnKeyDown = this.onKeyDown.bind(this)
    this.boundOnFocus = this.onFocus.bind(this)
    this.boundOnClick = this.onClick.bind(this)
    this.boundOnPaste = this.onPaste.bind(this)

    this.displayTarget.addEventListener("input", this.boundOnInput)
    this.displayTarget.addEventListener("keydown", this.boundOnKeyDown)
    this.displayTarget.addEventListener("focus", this.boundOnFocus)
    this.displayTarget.addEventListener("click", this.boundOnClick)
    this.displayTarget.addEventListener("paste", this.boundOnPaste)

    const form = this.element.closest("form")
    if (form) {
      this.boundOnReset = this.onReset.bind(this)
      form.addEventListener("reset", this.boundOnReset)
    }
  }

  disconnect() {
    if (this.hasDisplayTarget) {
      this.displayTarget.removeEventListener("input", this.boundOnInput)
      this.displayTarget.removeEventListener("keydown", this.boundOnKeyDown)
      this.displayTarget.removeEventListener("focus", this.boundOnFocus)
      this.displayTarget.removeEventListener("click", this.boundOnClick)
      this.displayTarget.removeEventListener("paste", this.boundOnPaste)
    }
  }

  onKeyDown(event) {
    if (event.key === "Backspace" || event.key === "Delete") {
      event.preventDefault()
      this.rawDigits = this.rawDigits.slice(0, -1)
      this.render()
      return
    }

    // Ignore non-digits except navigation/form keys
    if (event.key.length === 1 && !/[0-9]/.test(event.key)) {
      event.preventDefault()
      return
    }

    // If single digit key
    if (/[0-9]/.test(event.key) && !event.ctrlKey && !event.metaKey && !event.altKey) {
      event.preventDefault()
      if (this.rawDigits.length >= 11) return // Cap at 999,999,999.99
      this.rawDigits += event.key
      this.render()
    }
  }

  onInput(event) {
    // Fallback for mobile virtual keyboards where keydown doesn't pass key
    const val = event.target.value || ""
    const digitsOnly = val.replace(/\D/g, "").replace(/^0+/, "")
    this.rawDigits = digitsOnly.slice(0, 11)
    this.render()
  }

  onPaste(event) {
    event.preventDefault()
    const pasted = (event.clipboardData || window.clipboardData).getData("text") || ""
    // Handle pasted numbers (e.g. 15.50, 15,50, or 15)
    const normalized = pasted.trim().replace(/\./g, "").replace(",", ".")
    const parsed = parseFloat(normalized)
    if (!isNaN(parsed) && parsed > 0) {
      this.rawDigits = Math.round(parsed * 100).toString().slice(0, 11)
      this.render()
    }
  }

  onFocus() {
    requestAnimationFrame(() => this.setCursorToEnd())
  }

  onClick() {
    this.setCursorToEnd()
  }

  onReset() {
    this.rawDigits = ""
    setTimeout(() => this.render(), 10)
  }

  clear() {
    this.rawDigits = ""
    this.render()
    this.setCursorToEnd()
  }

  setCursorToEnd() {
    if (!this.hasDisplayTarget) return
    const len = this.displayTarget.value.length
    try {
      this.displayTarget.setSelectionRange(len, len)
    } catch (e) {
      // Ignored for non-text inputs
    }
  }

  render() {
    const clean = this.rawDigits.replace(/^0+/, "")
    this.rawDigits = clean

    let formatted = "0,00"
    let numeric = "0.00"

    if (clean.length === 0) {
      formatted = "0,00"
      numeric = "0.00"
    } else if (clean.length === 1) {
      formatted = `0,0${clean}`
      numeric = `0.0${clean}`
    } else if (clean.length === 2) {
      formatted = `0,${clean}`
      numeric = `0.${clean}`
    } else {
      const integerPart = clean.slice(0, -2)
      const decimalPart = clean.slice(-2)
      const formattedInteger = integerPart.replace(/\B(?=(\d{3})+(?!\d))/g, ".")
      formatted = `${formattedInteger},${decimalPart}`
      numeric = `${integerPart}.${decimalPart}`
    }

    if (this.hasDisplayTarget) {
      this.displayTarget.value = formatted
    }

    if (this.hasHiddenTarget) {
      const prev = this.hiddenTarget.value
      this.hiddenTarget.value = numeric
      if (prev !== numeric) {
        this.hiddenTarget.dispatchEvent(new Event("input", { bubbles: true }))
        this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }))
      }
    }
  }
}
