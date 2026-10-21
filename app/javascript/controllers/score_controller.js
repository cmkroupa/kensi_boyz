import { Controller } from "@hotwired/stimulus"

// Tap-to-enter score: opens a keypad dialog like the PIN pad. Closes itself
// as soon as the number can't get longer ("1" waits for a possible 10-19).
export default class extends Controller {
  static targets = ["input", "display", "dialog", "readout"]

  connect() {
    this.draft = ""
    this.render()
  }

  open() {
    this.draft = ""
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  press(event) {
    const digit = event.currentTarget.dataset.digit
    this.draft += digit
    this.inputTarget.value = this.draft
    this.render()
    if (this.draft.length === 2 || digit !== "1") this.close()
  }

  erase() {
    this.draft = this.draft.slice(0, -1)
    this.inputTarget.value = this.draft
    this.render()
  }

  render() {
    const value = this.inputTarget.value
    this.displayTarget.textContent = value === "" ? "0" : value
    this.displayTarget.classList.toggle("text-slate-300", value === "")
    this.displayTarget.classList.toggle("text-slate-900", value !== "")
    this.readoutTarget.textContent = value === "" ? "0" : value
    this.readoutTarget.classList.toggle("text-slate-300", value === "")
  }
}
