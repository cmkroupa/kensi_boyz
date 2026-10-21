import { Controller } from "@hotwired/stimulus"

// Keeps the game form consistent (right number of players per side, nobody on
// both sides) and previews each team's win chance before saving. On the
// predict page (autoSubmit) it submits the form itself once both teams are full.
export default class extends Controller {
  static targets = ["chip", "mode", "preview", "result"]
  static values = { autoSubmit: Boolean }

  connect() {
    this.refresh(false)
  }

  changeMode() {
    this.trim("a")
    this.trim("b")
    this.refresh()
  }

  pick(event) {
    const chip = event.target
    if (chip.checked) {
      this.chipsFor(chip.dataset.side === "a" ? "b" : "a")
        .filter((other) => other.dataset.name === chip.dataset.name)
        .forEach((other) => (other.checked = false))
      this.trim(chip.dataset.side, chip)
    }
    this.refresh()
  }

  get mode() {
    return this.modeTargets.find((radio) => radio.checked)?.value || "singles"
  }

  get limit() {
    return this.mode === "doubles" ? 2 : 1
  }

  chipsFor(side) {
    return this.chipTargets.filter((chip) => chip.dataset.side === side)
  }

  // Drops the oldest picks on a side until it fits, keeping the newest one.
  trim(side, keep = null) {
    const picked = this.chipsFor(side).filter((chip) => chip.checked && chip !== keep)
    const room = this.limit - (keep ? 1 : 0)
    picked.slice(0, Math.max(picked.length - room, 0)).forEach((chip) => (chip.checked = false))
  }

  average(side) {
    const picked = this.chipsFor(side).filter((chip) => chip.checked)
    if (picked.length !== this.limit) return null
    return picked.reduce((sum, chip) => sum + Number(chip.dataset[this.mode]), 0) / picked.length
  }

  refresh(submit = true) {
    const a = this.average("a")
    const b = this.average("b")
    const ready = a !== null && b !== null

    if (this.hasPreviewTarget) {
      const chanceA = ready ? 1 / (1 + 10 ** ((b - a) / 400)) : null
      this.previewTarget.textContent = ready ? `Team 1 has a ${Math.round(chanceA * 100)}% chance to win.` : ""
    }

    if (!this.autoSubmitValue || !submit) return
    if (ready) this.element.requestSubmit()
    else if (this.hasResultTarget) this.resultTarget.innerHTML = ""
  }
}
