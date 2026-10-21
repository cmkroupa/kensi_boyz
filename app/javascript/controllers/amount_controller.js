import { Controller } from "@hotwired/stimulus"

// Dollar amount entry on the same keypad as the scores. Stays open until Done
// since a bet can be one to three digits, and tells the form when it changes.
export default class extends Controller {
  static targets = ["input", "display", "dialog"]

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
    if (this.draft.length >= 3) return
    this.draft = (this.draft + event.currentTarget.dataset.digit).replace(/^0+/, "")
    this.commit()
  }

  erase() {
    this.draft = this.draft.slice(0, -1)
    this.commit()
  }

  commit() {
    this.inputTarget.value = this.draft || "0"
    this.render()
    this.dispatch("change")
  }

  render() {
    const dollars = Number(this.inputTarget.value)
    this.displayTarget.textContent = `$${dollars}`
    this.displayTarget.classList.toggle("text-slate-300", dollars === 0)
    this.displayTarget.classList.toggle("text-slate-900", dollars !== 0)
  }
}
