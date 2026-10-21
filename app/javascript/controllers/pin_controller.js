import { Controller } from "@hotwired/stimulus"

// On-screen PIN pad: fills four dots and submits the form on the last digit.
// Physical keyboard digits and backspace work too.
export default class extends Controller {
  static targets = ["form", "input", "dot"]
  static LENGTH = 4

  connect() {
    this.onKey = (event) => {
      if (/^\d$/.test(event.key)) this.add(event.key)
      else if (event.key === "Backspace") this.erase()
    }
    window.addEventListener("keydown", this.onKey)
  }

  disconnect() {
    window.removeEventListener("keydown", this.onKey)
  }

  press(event) {
    this.add(event.currentTarget.dataset.digit)
  }

  erase() {
    this.inputTarget.value = this.inputTarget.value.slice(0, -1)
    this.render()
  }

  add(digit) {
    if (this.inputTarget.value.length >= this.constructor.LENGTH) return
    this.inputTarget.value += digit
    this.render()
    if (this.inputTarget.value.length === this.constructor.LENGTH) this.formTarget.requestSubmit()
  }

  render() {
    const filled = this.inputTarget.value.length
    this.dotTargets.forEach((dot, index) => {
      dot.classList.toggle("bg-blue-600", index < filled)
      dot.classList.toggle("border-blue-600", index < filled)
    })
  }
}
