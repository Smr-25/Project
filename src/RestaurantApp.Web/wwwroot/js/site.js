document.addEventListener("submit", (event) => {
    const form = event.target;
    if (!(form instanceof HTMLFormElement)) return;
    const message = form.dataset.confirm;
    if (message && !window.confirm(message)) event.preventDefault();
});

document.querySelectorAll("[data-order-builder]").forEach((builder) => {
    const quantityInputs = [...builder.querySelectorAll(".order-quantity")];
    const countOutput = builder.querySelector("[data-order-count]");
    const totalOutput = builder.querySelector("[data-order-total]");

    const updateSummary = () => {
        let count = 0;
        let total = 0;
        quantityInputs.forEach((input) => {
            const quantity = Math.max(0, Number.parseInt(input.value || "0", 10) || 0);
            const price = Number.parseFloat(input.dataset.price || "0") || 0;
            count += quantity;
            total += quantity * price;
            input.closest("[data-order-row]")?.classList.toggle("is-selected", quantity > 0);
        });
        if (countOutput) countOutput.textContent = count.toString();
        if (totalOutput) totalOutput.textContent = total.toFixed(2);
    };

    quantityInputs.forEach((input) => input.addEventListener("input", updateSummary));
    updateSummary();
});
