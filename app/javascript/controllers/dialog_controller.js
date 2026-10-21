import { Controller } from "@hotwired/stimulus"

// Opens and closes a <dialog> from a button; clicking the backdrop closes it.
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
    this.dialogTarget.scrollTop = 0
  }

  close() {
    this.dialogTarget.close()
  }

  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
