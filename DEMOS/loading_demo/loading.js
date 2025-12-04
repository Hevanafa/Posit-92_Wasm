class LoadingMixin extends Posit92 {
  setLoadingText(text) {
    const div = document.querySelector("#loading-overlay > div");
    div.innerHTML = text;
  }

  hideLoadingOverlay() {
    const div = document.getElementById("loading-overlay");
    // div.style.display = "none";
    div.classList.add("hidden");
    this.setLoadingText("");
  }

  async sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }
}