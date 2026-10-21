import { Controller } from "@hotwired/stimulus"

// Keeps the game form consistent (right number of players per side, nobody on
// both sides) and previews each team's win chance before saving. On the
// predict page (autoSubmit) it submits the form itself once both teams are full.
export default class extends Controller {
  static targets = ["chip", "mode", "preview", "result", "bet", "terms"]
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

  betChanged() {
    this.refresh(false)
  }

  // Mirrors Moneyline: the underdog puts up the bet, the favourite risks enough to make it fair.
  terms(chanceA, underdogCents) {
    const favorite = chanceA >= 0.5 ? "a" : "b"
    const chance = Math.min(Math.max(chanceA, 1 - chanceA), 0.9)
    const favoriteCents = Math.round((underdogCents * chance) / (1 - chance) / 25) * 25
    const line = (side) => {
      const risks = side === favorite ? favoriteCents : underdogCents
      const wins = side === favorite ? underdogCents : favoriteCents
      return `${this.teamName(side)} risks ${this.money(risks)} to win ${this.money(wins)}`
    }
    return `${line("a")}\n${line("b")}`
  }

  teamName(side) {
    return this.chipsFor(side).filter((chip) => chip.checked).map((chip) => chip.dataset.name).join(" & ")
  }

  money(cents) {
    return cents % 100 === 0 ? `$${cents / 100}` : `$${(cents / 100).toFixed(2)}`
  }

  refresh(submit = true) {
    const a = this.average("a")
    const b = this.average("b")
    const ready = a !== null && b !== null
    const chanceA = ready ? 1 / (1 + 10 ** ((b - a) / 400)) : null

    if (this.hasPreviewTarget) {
      this.previewTarget.textContent = ready ? `Team 1 has a ${Math.round(chanceA * 100)}% chance to win.` : ""
    }

    if (this.hasTermsTarget) {
      const cents = this.hasBetTarget ? Number(this.betTarget.value) * 100 : 0
      this.termsTarget.textContent = ready && cents > 0 ? this.terms(chanceA, cents) : ""
    }

    if (!this.autoSubmitValue || !submit) return
    if (ready) this.element.requestSubmit()
    else if (this.hasResultTarget) this.resultTarget.innerHTML = ""
  }
}
